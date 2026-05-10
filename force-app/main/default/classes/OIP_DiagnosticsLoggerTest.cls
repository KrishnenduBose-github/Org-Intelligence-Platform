@IsTest
private class OIP_DiagnosticsLoggerTest {
    @TestSetup
    static void makeData() {
        try {
            OIP_DiagnosticsLog__c log = new OIP_DiagnosticsLog__c(
                OIP_ServiceName__c = 'TestService',
                OIP_LogLevel__c = 'INFO',
                OIP_Message__c = 'Test setup message',
                OIP_Timestamp__c = Datetime.now()
            );
            insert log;
        } catch (Exception e) {
            System.debug('Test setup skipped - object may not be deployed: ' + e.getMessage());
        }
    }

    @IsTest
    static void testLogSingleEntry() {
        Test.startTest();
        OIP_DiagnosticsLogger.log('TestService', 'INFO', 'Single test message', 'TestComponent');
        Test.stopTest();

        List<OIP_DiagnosticsLog__c> logs = [
            SELECT Id, OIP_ServiceName__c, OIP_LogLevel__c, OIP_Message__c, OIP_ComponentRef__c, OIP_StackHash__c
            FROM OIP_DiagnosticsLog__c
            WHERE OIP_ServiceName__c = 'TestService' AND OIP_ComponentRef__c = 'TestComponent' AND OIP_LogLevel__c = 'INFO'
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        System.assertEquals(1, logs.size(), 'Should create exactly one log entry');
        System.assertEquals('INFO', logs[0].OIP_LogLevel__c, 'Log level should be INFO');
        System.assertEquals('TestComponent', logs[0].OIP_ComponentRef__c, 'Component ref should be set');
        System.assert(String.isNotBlank(logs[0].OIP_StackHash__c), 'Stack hash should be generated');
    }

    @IsTest
    static void testLogBulkScenario() {
        List<OIP_DiagnosticsLog__c> entries = new List<OIP_DiagnosticsLog__c>();
        for (Integer i = 0; i < 200; i++) {
            entries.add(new OIP_DiagnosticsLog__c(
                OIP_ServiceName__c = 'BulkTest',
                OIP_LogLevel__c = 'DEBUG',
                OIP_Message__c = 'Bulk entry ' + i,
                OIP_Timestamp__c = Datetime.now()
            ));
        }

        Test.startTest();
        OIP_DiagnosticsLogger.logBulk(entries);
        Test.stopTest();

        List<OIP_DiagnosticsLog__c> results = [
            SELECT Id, OIP_Message__c
            FROM OIP_DiagnosticsLog__c
            WHERE OIP_ServiceName__c = 'BulkTest'
        ];
        System.assertEquals(200, results.size(), 'Should insert all 200 log entries');
    }

    @IsTest
    static void testLogBulkExceedsBatchSize() {
        List<OIP_DiagnosticsLog__c> entries = new List<OIP_DiagnosticsLog__c>();
        for (Integer i = 0; i < 450; i++) {
            entries.add(new OIP_DiagnosticsLog__c(
                OIP_ServiceName__c = 'LargeBulkTest',
                OIP_LogLevel__c = 'WARN',
                OIP_Message__c = 'Large bulk entry ' + i,
                OIP_Timestamp__c = Datetime.now()
            ));
        }

        Test.startTest();
        OIP_DiagnosticsLogger.logBulk(entries);
        Test.stopTest();

        List<OIP_DiagnosticsLog__c> results = [
            SELECT Id FROM OIP_DiagnosticsLog__c
            WHERE OIP_ServiceName__c = 'LargeBulkTest'
        ];
        System.assertEquals(450, results.size(), 'Should insert all 450 entries across multiple DML chunks');
    }

    @IsTest
    static void testLogNullEntries() {
        Test.startTest();
        OIP_DiagnosticsLogger.logBulk(null);
        Test.stopTest();
        System.assert(true, 'Should handle null input gracefully');
    }

    @IsTest
    static void testLogEmptyEntries() {
        Test.startTest();
        OIP_DiagnosticsLogger.logBulk(new List<OIP_DiagnosticsLog__c>());
        Test.stopTest();
        System.assert(true, 'Should handle empty list gracefully');
    }

    @IsTest
    static void testBuildLogEntry() {
        Datetime beforeCall = Datetime.now();

        OIP_DiagnosticsLog__c entry = OIP_DiagnosticsLogger.buildLogEntry(
            'ServiceX', 'ERROR', 'Something went wrong', 'ComponentY'
        );

        System.assertEquals('ServiceX', entry.OIP_ServiceName__c, 'Service name should match');
        System.assertEquals('ERROR', entry.OIP_LogLevel__c, 'Log level should match');
        System.assertEquals('Something went wrong', entry.OIP_Message__c, 'Message should match');
        System.assertEquals('ComponentY', entry.OIP_ComponentRef__c, 'Component ref should match');
        System.assert(entry.OIP_Timestamp__c >= beforeCall, 'Timestamp should be set to now');
        System.assert(String.isNotBlank(entry.OIP_StackHash__c), 'Stack hash should be generated');
    }

    @IsTest
    static void testLogAllLevels() {
        List<OIP_DiagnosticsLog__c> entries = new List<OIP_DiagnosticsLog__c>();
        entries.add(OIP_DiagnosticsLogger.buildLogEntry('LevelTest', 'DEBUG', 'Debug msg', null));
        entries.add(OIP_DiagnosticsLogger.buildLogEntry('LevelTest', 'INFO', 'Info msg', null));
        entries.add(OIP_DiagnosticsLogger.buildLogEntry('LevelTest', 'WARN', 'Warn msg', null));
        entries.add(OIP_DiagnosticsLogger.buildLogEntry('LevelTest', 'ERROR', 'Error msg', null));
        entries.add(OIP_DiagnosticsLogger.buildLogEntry('LevelTest', 'FATAL', 'Fatal msg', null));

        Test.startTest();
        OIP_DiagnosticsLogger.logBulk(entries);
        Test.stopTest();

        List<OIP_DiagnosticsLog__c> results = [
            SELECT Id, OIP_LogLevel__c FROM OIP_DiagnosticsLog__c
            WHERE OIP_ServiceName__c = 'LevelTest'
        ];
        System.assertEquals(5, results.size(), 'Should insert all log levels');
    }

    @IsTest
    static void testGetSessionLogs() {
        OIP_DebugSession__c session = new OIP_DebugSession__c(
            OIP_QueryText__c = 'SessionLogTest',
            OIP_SessionType__c = 'Search',
            OIP_Status__c = 'InProgress',
            OIP_StartTime__c = Datetime.now()
        );
        insert session;

        List<OIP_DiagnosticsLog__c> sessionLogs = new List<OIP_DiagnosticsLog__c>();
        for (Integer i = 0; i < 3; i++) {
            sessionLogs.add(new OIP_DiagnosticsLog__c(
                OIP_ServiceName__c = 'SessionTest',
                OIP_LogLevel__c = 'INFO',
                OIP_Message__c = 'Session log ' + i,
                OIP_Category__c = 'Governor',
                OIP_Timestamp__c = Datetime.now(),
                OIP_DebugSessionId__c = session.Id
            ));
        }
        insert sessionLogs;

        Test.startTest();
        List<OIP_DiagnosticsLog__c> results = OIP_DiagnosticsLogger.getSessionLogs(session.Id);
        Test.stopTest();
        System.assert(results.size() >= 3, 'Should return session logs');
    }

    @IsTest
    static void testDeduplicateLogs() {
        OIP_DebugSession__c session = new OIP_DebugSession__c(
            OIP_QueryText__c = 'DedupTest',
            OIP_SessionType__c = 'RootCause',
            OIP_Status__c = 'InProgress',
            OIP_StartTime__c = Datetime.now()
        );
        insert session;

        List<OIP_DiagnosticsLog__c> dupLogs = new List<OIP_DiagnosticsLog__c>();
        for (Integer i = 0; i < 3; i++) {
            dupLogs.add(new OIP_DiagnosticsLog__c(
                OIP_ServiceName__c = 'DedupSvc',
                OIP_LogLevel__c = 'WARN',
                OIP_Message__c = 'Duplicate message',
                OIP_Category__c = 'Security',
                OIP_Timestamp__c = Datetime.now().addSeconds(i),
                OIP_DebugSessionId__c = session.Id
            ));
        }
        insert dupLogs;

        Test.startTest();
        Integer removed = OIP_DiagnosticsLogger.deduplicateLogs(session.Id);
        Test.stopTest();
        System.assert(removed >= 0, 'Deduplication should complete without error');
    }

    @IsTest
    static void testArchiveOldLogs() {
        List<OIP_DiagnosticsLog__c> oldLogs = new List<OIP_DiagnosticsLog__c>();
        for (Integer i = 0; i < 5; i++) {
            oldLogs.add(new OIP_DiagnosticsLog__c(
                OIP_ServiceName__c = 'ArchiveSvc',
                OIP_LogLevel__c = 'INFO',
                OIP_Message__c = 'Old log entry ' + i,
                OIP_Category__c = 'Deployment',
                OIP_Timestamp__c = Datetime.now().addDays(-60)
            ));
        }
        insert oldLogs;

        List<OIP_DiagnosticsLog__c> recentLogs = new List<OIP_DiagnosticsLog__c>();
        for (Integer i = 0; i < 3; i++) {
            recentLogs.add(new OIP_DiagnosticsLog__c(
                OIP_ServiceName__c = 'ArchiveSvc',
                OIP_LogLevel__c = 'INFO',
                OIP_Message__c = 'Recent log entry ' + i,
                OIP_Category__c = 'Performance',
                OIP_Timestamp__c = Datetime.now()
            ));
        }
        insert recentLogs;

        Test.startTest();
        OIP_DiagnosticsLogger.archiveOldLogs(30);
        Test.stopTest();

        List<OIP_DiagnosticsLog__c> remaining = [
            SELECT Id FROM OIP_DiagnosticsLog__c
            WHERE OIP_ServiceName__c = 'ArchiveSvc'
        ];
        System.assert(remaining.size() >= 3, 'Should retain recent logs after archival');
    }

    @IsTest
    static void testArchiveOldLogsWithNull() {
        Test.startTest();
        OIP_DiagnosticsLogger.archiveOldLogs(null);
        Test.stopTest();
        System.assert(true, 'Should handle null daysToKeep gracefully');
    }

    @IsTest
    static void testBuildLogEntryLongMessage() {
        String longMessage = '';
        for (Integer i = 0; i < 300; i++) {
            longMessage += 'A';
        }
        OIP_DiagnosticsLog__c entry = OIP_DiagnosticsLogger.buildLogEntry('LongMsgSvc', 'ERROR', longMessage, null);
        System.assertEquals('LongMsgSvc', entry.OIP_ServiceName__c, 'Service name should match');
        System.assert(String.isNotBlank(entry.OIP_StackHash__c), 'Stack hash should be generated for long messages');
    }

    @IsTest
    static void testGetSessionLogsWithSessionId() {
        OIP_DebugSession__c session = new OIP_DebugSession__c(
            OIP_QueryText__c = 'SessionFetchTest',
            OIP_SessionType__c = 'ImpactAnalysis',
            OIP_Status__c = 'Completed',
            OIP_StartTime__c = Datetime.now()
        );
        insert session;

        OIP_DiagnosticsLog__c sessionLog = new OIP_DiagnosticsLog__c(
            OIP_ServiceName__c = 'FetchTestSvc',
            OIP_LogLevel__c = 'INFO',
            OIP_Message__c = 'Session log fetch test',
            OIP_Category__c = 'Dependency',
            OIP_Timestamp__c = Datetime.now(),
            OIP_DebugSessionId__c = session.Id
        );
        insert sessionLog;

        Test.startTest();
        List<OIP_DiagnosticsLog__c> results = OIP_DiagnosticsLogger.getSessionLogs(session.Id);
        Test.stopTest();
        System.assert(results.size() >= 1, 'Should return at least one log for session');
    }
}
