/**
 * @description Service layer responsible for indexing Salesforce metadata components
 *              into OIP_MetadataIndex__c records. Supports ApexClass, Flow, and
 *              ApexTrigger types with SOQL-based retrieval and bulkified upserts.
 * @see OIP_MetadataIndex__c
 */
public with sharing class OIP_MetadataIndexerService {

    // Batch size for DML operations to respect governor limits
    public static final Integer BATCH_SIZE = 200;

    // Maximum callouts allowed per transaction
    private static final Integer MAX_CALLOUTS = 100;

    /**
     * @description Iterates over a set of component types and indexes each one
     *              individually via indexBySOQL.
     * @param types  Set of component type strings (e.g. 'ApexClass', 'Flow', 'ApexTrigger')
     */
    public static void indexComponentTypes(Set<String> types) {
        if (types == null || types.isEmpty()) {
            return;
        }

        for (String compType : types) {
            try {
                indexBySOQL(compType);
            } catch (Exception e) {
                OIP_DiagnosticsLogger.log(
                    'OIP_MetadataIndexerService',
                    'ERROR',
                    'Failed to index component type: ' + compType + ' - ' + e.getMessage(),
                    compType
                );
            }
        }
    }

    /**
     * @description Queries metadata tooling API tables for the given component type,
     *              builds OIP_MetadataIndex__c records, and upserts them using
     *              the OIP_CompoundKey__c external ID.
     * @param componentType  The metadata type to index (ApexClass, Flow, ApexTrigger)
     * @return               The number of records indexed
     */
    public static Integer indexBySOQL(String componentType) {
        if (String.isBlank(componentType)) {
            return 0;
        }

        if (!Schema.sObjectType.OIP_MetadataIndex__c.isCreateable()
            || !Schema.sObjectType.OIP_MetadataIndex__c.isUpdateable()) {
            return 0;
        }

        List<OIP_MetadataIndex__c> indexRecords = new List<OIP_MetadataIndex__c>();

        switch on componentType {
            when 'ApexClass' {
                for (ApexClass cls : [
                    SELECT Id, Name, NamespacePrefix, Status, ApiVersion, LengthWithoutComments
                    FROM ApexClass
                    WHERE NamespacePrefix = null
                ]) {
                    indexRecords.add(buildIndexRecord(
                        'ApexClass',
                        cls.Name,
                        cls.NamespacePrefix,
                        cls.Status
                    ));
                }
            }
            when 'Flow' {
                // Flow requires offset-based pagination due to potential volume
                Integer offset = 0;
                Boolean hasMore = true;

                while (hasMore) {
                    List<Flow> flows = [
                        SELECT Id, FullName, NamespacePrefix, Status, VersionNumber, Description
                        FROM Flow
                        WHERE NamespacePrefix = null
                        ORDER BY FullName
                        LIMIT :BATCH_SIZE
                        OFFSET :offset
                    ];

                    if (flows.isEmpty()) {
                        hasMore = false;
                    } else {
                        for (Flow f : flows) {
                            indexRecords.add(buildIndexRecord(
                                'Flow',
                                f.FullName,
                                f.NamespacePrefix,
                                String.valueOf(f.Status)
                            ));
                        }
                        offset += BATCH_SIZE;
                        // Guard against OFFSET limit of 2000
                        if (offset >= 2000 || flows.size() < BATCH_SIZE) {
                            hasMore = false;
                        }
                    }
                }
            }
            when 'ApexTrigger' {
                for (ApexTrigger trig : [
                    SELECT Id, Name, NamespacePrefix, Status, ApiVersion, EntityDefinition.Name
                    FROM ApexTrigger
                    WHERE NamespacePrefix = null
                ]) {
                    indexRecords.add(buildIndexRecord(
                        'ApexTrigger',
                        trig.Name,
                        trig.NamespacePrefix,
                        trig.Status
                    ));
                }
            }
            when else {
                OIP_DiagnosticsLogger.log(
                    'OIP_MetadataIndexerService',
                    'WARN',
                    'Unsupported component type: ' + componentType,
                    componentType
                );
                return 0;
            }
        }

        if (!indexRecords.isEmpty()) {
            upsertIndexRecords(indexRecords);
        }

        return indexRecords.size();
    }

    /**
     * @description Performs a bulkified upsert of OIP_MetadataIndex__c records,
     *              chunked to BATCH_SIZE and using OIP_CompoundKey__c as the
     *              external ID for conflict resolution.
     * @param records  List of OIP_MetadataIndex__c records to upsert
     */
    public static void upsertIndexRecords(List<OIP_MetadataIndex__c> records) {
        if (records == null || records.isEmpty()) {
            return;
        }

        Schema.SObjectField compoundKeyField = OIP_MetadataIndex__c.OIP_CompoundKey__c;

        for (Integer i = 0; i < records.size(); i += BATCH_SIZE) {
            Integer endIdx = Math.min(i + BATCH_SIZE, records.size());
            List<OIP_MetadataIndex__c> chunk = records.subList(i, endIdx);
            try {
                Database.upsert(chunk, compoundKeyField, false);
            } catch (DmlException e) {
                OIP_DiagnosticsLogger.log(
                    'OIP_MetadataIndexerService',
                    'ERROR',
                    'Upsert failed for batch starting at index ' + i + ': ' + e.getMessage(),
                    'OIP_MetadataIndex__c'
                );
            }
        }
    }

    /**
     * @description Builds a single OIP_MetadataIndex__c record from component metadata.
     *              Generates a compound key in the format TYPE__NAME__NS for upsert matching.
     * @param type       The component type (e.g. ApexClass, Flow)
     * @param fullName   The full API name of the component
     * @param namespace  The namespace prefix (null for unmanaged)
     * @param status     The current status of the component
     * @return           A populated OIP_MetadataIndex__c record
     */
    private static OIP_MetadataIndex__c buildIndexRecord(String type, String fullName, String namespace, String status) {
        OIP_MetadataIndex__c record = new OIP_MetadataIndex__c();
        record.OIP_ComponentType__c = type;
        record.OIP_FullName__c = fullName;
        record.OIP_Namespace__c = namespace;
        record.OIP_Status__c = status;

        // Build compound key: TYPE__NAME__NS for unique identification
        String ns = String.isNotBlank(namespace) ? namespace : 'unmanaged';
        record.OIP_CompoundKey__c = type + '__' + fullName + '__' + ns;

        return record;
    }
}
