/**
 * @description Centralized diagnostics logging service for OIP platform.
 *              Provides bulkified log creation, deduplication, session retrieval,
 *              and archival of diagnostic entries across all workspaces.
 * @see OIP_DiagnosticsLog__c
 */
public with sharing class OIP_DiagnosticsLogger {

    public enum LogLevel { DEBUG, INFO, WARN, ERROR, FATAL }

    // Maximum number of records per DML operation to stay within governor limits
    private static final Integer MAX_BULK_SIZE = 200;

    // Number of days to retain logs before archival
    private static final Integer MAX_LOG_RETENTION_DAYS = 30;

    /**
     * @description Creates and persists a single log entry by delegating to logBulk.
     * @param serviceName   The originating service or workspace name
     * @param level         The log severity level (DEBUG, INFO, WARN, ERROR, FATAL)
     * @param message       The descriptive log message
     * @param componentRef  Optional reference to a metadata component (e.g. Flow API name)
     */
    public static void log(String serviceName, String level, String message, String componentRef) {
        OIP_DiagnosticsLog__c entry = buildLogEntry(serviceName, level, message, componentRef);
        logBulk(new List<OIP_DiagnosticsLog__c>{ entry });
    }

    /**
     * @description Bulk-inserts a list of log entries, chunked to respect
     *              the MAX_BULK_SIZE limit. Uses allOrNone=false to allow
     *              partial success and avoid rollbacks on individual failures.
     * @param entries  List of OIP_DiagnosticsLog__c records to insert
     */
    public static void logBulk(List<OIP_DiagnosticsLog__c> entries) {
        if (entries == null || entries.isEmpty()) {
            return;
        }

        // Check FLS on OIP_DiagnosticsLog__c before inserting
        if (!Schema.sObjectType.OIP_DiagnosticsLog__c.isCreateable()) {
            return;
        }

        // Chunk into groups of MAX_BULK_SIZE for safe DML
        for (Integer i = 0; i < entries.size(); i += MAX_BULK_SIZE) {
            Integer endIdx = Math.min(i + MAX_BULK_SIZE, entries.size());
            List<OIP_DiagnosticsLog__c> chunk = new List<OIP_DiagnosticsLog__c>();
            for (Integer j = i; j < endIdx; j++) {
                chunk.add(entries[j]);
            }
            Database.insert(chunk, false);
        }
    }

    /**
     * @description Constructs an OIP_DiagnosticsLog__c record with a generated
     *              stack hash for deduplication and the current timestamp.
     * @param serviceName   The originating service or workspace name
     * @param level         The log severity level
     * @param message       The descriptive log message
     * @param componentRef  Optional reference to a metadata component
     * @return              A populated OIP_DiagnosticsLog__c record (not yet inserted)
     */
    public static OIP_DiagnosticsLog__c buildLogEntry(String serviceName, String level, String message, String componentRef) {
        OIP_DiagnosticsLog__c entry = new OIP_DiagnosticsLog__c();
        entry.OIP_ServiceName__c = serviceName;
        entry.OIP_LogLevel__c = level;
        entry.OIP_Message__c = message;
        entry.OIP_ComponentRef__c = componentRef;
        entry.OIP_Timestamp__c = Datetime.now();
        entry.OIP_StackHash__c = generateStackHash(serviceName, level, message);
        return entry;
    }

    /**
     * @description Retrieves all log entries for a given session, ordered
     *              by most recent first. Capped at 500 to avoid heap limits.
     * @param sessionId  The OIP_DebugSessionId__c value to filter on
     * @return           List of matching OIP_DiagnosticsLog__c records
     */
    public static List<OIP_DiagnosticsLog__c> getSessionLogs(Id sessionId) {
        if (!Schema.sObjectType.OIP_DiagnosticsLog__c.isQueryable()) {
            return new List<OIP_DiagnosticsLog__c>();
        }

        return [
            SELECT Id, OIP_ServiceName__c, OIP_LogLevel__c, OIP_Message__c,
                   OIP_ComponentRef__c, OIP_Timestamp__c, OIP_StackHash__c,
                   OIP_DebugSessionId__c
            FROM OIP_DiagnosticsLog__c
            WHERE OIP_DebugSessionId__c = :sessionId
            ORDER BY OIP_Timestamp__c DESC
            LIMIT 500
        ];
    }

    /**
     * @description Groups logs by StackHash for a given session, keeps only
     *              the most recent entry per hash, and deletes all duplicates.
     * @param sessionId  The session to deduplicate logs within
     * @return           The number of duplicate records removed
     */
    public static Integer deduplicateLogs(Id sessionId) {
        if (!Schema.sObjectType.OIP_DiagnosticsLog__c.isQueryable()
            || !Schema.sObjectType.OIP_DiagnosticsLog__c.isDeletable()) {
            return 0;
        }

        // Aggregate duplicates by StackHash, keeping the most recent Id per group
        List<AggregateResult> duplicates = [
            SELECT OIP_StackHash__c, COUNT(Id) cnt
            FROM OIP_DiagnosticsLog__c
            WHERE OIP_DebugSessionId__c = :sessionId
              AND OIP_StackHash__c != null
            GROUP BY OIP_StackHash__c
            HAVING COUNT(Id) > 1
        ];

        if (duplicates.isEmpty()) {
            return 0;
        }

        Set<String> hashSet = new Set<String>();
        for (AggregateResult ar : duplicates) {
            hashSet.add((String) ar.get('OIP_StackHash__c'));
        }

        // Fetch all logs matching duplicated hashes for this session
        List<OIP_DiagnosticsLog__c> allLogs = [
            SELECT Id, OIP_StackHash__c, OIP_Timestamp__c
            FROM OIP_DiagnosticsLog__c
            WHERE OIP_DebugSessionId__c = :sessionId
              AND OIP_StackHash__c IN :hashSet
            ORDER BY OIP_Timestamp__c DESC
        ];

        // Keep the first (most recent) per hash, delete the rest
        Map<String, Id> keepIds = new Map<String, Id>();
        List<OIP_DiagnosticsLog__c> toDelete = new List<OIP_DiagnosticsLog__c>();

        for (OIP_DiagnosticsLog__c logEntry : allLogs) {
            if (!keepIds.containsKey(logEntry.OIP_StackHash__c)) {
                keepIds.put(logEntry.OIP_StackHash__c, logEntry.Id);
            } else {
                toDelete.add(logEntry);
            }
        }

        // Batch delete in chunks of MAX_BULK_SIZE
        for (Integer i = 0; i < toDelete.size(); i += MAX_BULK_SIZE) {
            Integer endIdx = Math.min(i + MAX_BULK_SIZE, toDelete.size());
            List<OIP_DiagnosticsLog__c> chunk = new List<OIP_DiagnosticsLog__c>();
            for (Integer j = i; j < endIdx; j++) {
                chunk.add(toDelete[j]);
            }
            Database.delete(chunk, false);
        }

        return toDelete.size();
    }

    /**
     * @description Archives (deletes) logs older than the specified number of days.
     *              Processes deletions in batches of MAX_BULK_SIZE to respect limits.
     * @param daysToKeep  Number of days of logs to retain
     */
    public static void archiveOldLogs(Integer daysToKeep) {
        if (!Schema.sObjectType.OIP_DiagnosticsLog__c.isQueryable()
            || !Schema.sObjectType.OIP_DiagnosticsLog__c.isDeletable()) {
            return;
        }

        if (daysToKeep == null || daysToKeep < 1) {
            daysToKeep = MAX_LOG_RETENTION_DAYS;
        }

        Datetime threshold = Datetime.now().addDays(-daysToKeep);

        // Query and delete in batches to handle large volumes
        Boolean hasMore = true;
        while (hasMore) {
            List<OIP_DiagnosticsLog__c> oldLogs = [
                SELECT Id
                FROM OIP_DiagnosticsLog__c
                WHERE OIP_Timestamp__c < :threshold
                LIMIT :MAX_BULK_SIZE
            ];

            if (oldLogs.isEmpty()) {
                hasMore = false;
            } else {
                Database.delete(oldLogs, false);
                hasMore = oldLogs.size() == MAX_BULK_SIZE;
            }
        }
    }

    /**
     * @description Generates an MD5 hash from the concatenation of serviceName,
     *              level, and a truncated message. Used for deduplication grouping.
     * @param serviceName  The service name component
     * @param level        The log level component
     * @param message      The message component (truncated to 2000 chars)
     * @return             Hex string of the MD5 digest
     */
    private static String generateStackHash(String serviceName, String level, String message) {
        String rawInput = serviceName + '|' + level + '|';
        if (message != null && message.length() > 2000) {
            rawInput += message.substring(0, 2000);
        } else {
            rawInput += message;
        }

        Blob hashBlob = Crypto.generateDigest('MD5', Blob.valueOf(rawInput));
        return EncodingUtil.convertToHex(hashBlob);
    }
}
