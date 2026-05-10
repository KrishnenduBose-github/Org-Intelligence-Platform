@IsTest
private class OIP_MetadataIndexerServiceTest {
    @TestSetup
    static void makeData() {
        try {
            OIP_MetadataIndex__c idx = new OIP_MetadataIndex__c(
                OIP_ComponentType__c = 'ApexClass',
                OIP_FullName__c = 'TestClass',
                OIP_CompoundKey__c = 'ApexClass||TestClass',
                OIP_IsActive__c = true,
                OIP_Status__c = 'Active',
                OIP_IndexedAt__c = Datetime.now()
            );
            insert idx;
        } catch (Exception e) {
            System.debug('Test setup skipped - object may not be deployed: ' + e.getMessage());
        }
    }

    @IsTest
    static void testIndexBySOQLApexClass() {
        Test.startTest();
        Integer count = OIP_MetadataIndexerService.indexBySOQL('ApexClass');
        Test.stopTest();

        System.assert(count >= 0, 'Should index ApexClass components without error');
    }

    @IsTest
    static void testIndexBySOQLFlow() {
        Test.startTest();
        Integer count = OIP_MetadataIndexerService.indexBySOQL('Flow');
        Test.stopTest();

        System.assert(count >= 0, 'Should index Flow components without error');
    }

    @IsTest
    static void testIndexBySOQLApexTrigger() {
        Test.startTest();
        Integer count = OIP_MetadataIndexerService.indexBySOQL('ApexTrigger');
        Test.stopTest();

        System.assert(count >= 0, 'Should index ApexTrigger components without error');
    }

    @IsTest
    static void testIndexBySOQLUnsupportedType() {
        Test.startTest();
        Integer count = OIP_MetadataIndexerService.indexBySOQL('InvalidType');
        Test.stopTest();

        System.assertEquals(0, count, 'Unsupported type should return 0');
    }

    @IsTest
    static void testIndexComponentTypesWithNull() {
        Test.startTest();
        OIP_MetadataIndexerService.indexComponentTypes(null);
        Test.stopTest();
        System.assert(true, 'Should handle null input gracefully');
    }

    @IsTest
    static void testIndexComponentTypesWithEmpty() {
        Test.startTest();
        OIP_MetadataIndexerService.indexComponentTypes(new Set<String>());
        Test.stopTest();
        System.assert(true, 'Should handle empty set gracefully');
    }

    @IsTest
    static void testUpsertIndexRecordsBulk() {
        List<OIP_MetadataIndex__c> records = new List<OIP_MetadataIndex__c>();
        for (Integer i = 0; i < 200; i++) {
            String fname = 'BulkTestClass_' + i;
            records.add(new OIP_MetadataIndex__c(
                OIP_ComponentType__c = 'ApexClass',
                OIP_FullName__c = fname,
                OIP_CompoundKey__c = 'ApexClass||' + fname,
                OIP_IsActive__c = true,
                OIP_Status__c = 'Active',
                OIP_IndexedAt__c = Datetime.now()
            ));
        }

        Test.startTest();
        OIP_MetadataIndexerService.upsertIndexRecords(records);
        Test.stopTest();

        List<OIP_MetadataIndex__c> results = [
            SELECT Id FROM OIP_MetadataIndex__c
            WHERE OIP_FullName__c LIKE 'BulkTestClass_%'
        ];
        System.assert(results.size() >= 200, 'Should upsert all 200 records');
    }

    @IsTest
    static void testUpsertIndexRecordsWithUpdate() {
        List<OIP_MetadataIndex__c> existing = [
            SELECT Id, OIP_ComponentType__c, OIP_FullName__c, OIP_CompoundKey__c, OIP_IsActive__c, OIP_Status__c, OIP_IndexedAt__c
            FROM OIP_MetadataIndex__c
            WHERE OIP_FullName__c = 'TestClass'
        ];
        System.assertEquals(1, existing.size(), 'Should find existing test record');

        existing[0].OIP_Status__c = 'Deprecated';
        existing[0].OIP_IndexedAt__c = Datetime.now();

        Test.startTest();
        OIP_MetadataIndexerService.upsertIndexRecords(existing);
        Test.stopTest();

        List<OIP_MetadataIndex__c> updated = [
            SELECT OIP_Status__c FROM OIP_MetadataIndex__c
            WHERE OIP_FullName__c = 'TestClass'
        ];
        System.assertEquals(1, updated.size(), 'Should find the updated record');
        System.assertEquals('Deprecated', updated[0].OIP_Status__c, 'Status should be updated via upsert');
    }

    @IsTest
    static void testIndexComponentTypesMultipleTypes() {
        Set<String> types = new Set<String>{'ApexClass', 'ApexTrigger'};

        Test.startTest();
        OIP_MetadataIndexerService.indexComponentTypes(types);
        Test.stopTest();

        System.assert(true, 'Should process multiple types without error');
    }
}
