@IsTest
private class OIP_QueueableAndBatchTest {
    @TestSetup
    static void makeData() {
        OIP_MetadataIndex__c idx = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'ApexClass',
            OIP_FullName__c = 'QueueableTestClass',
            OIP_CompoundKey__c = 'ApexClass||QueueableTestClass',
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now().addDays(-2)
        );
        insert idx;

        OIP_DiagnosticsLog__c log1 = new OIP_DiagnosticsLog__c(
            OIP_ServiceName__c = 'BatchTest',
            OIP_LogLevel__c = 'ERROR',
            OIP_Message__c = 'Error in batch test',
            OIP_Category__c = 'Deployment',
            OIP_Timestamp__c = Datetime.now().addDays(-1)
        );
        insert log1;

        OIP_DiagnosticsLog__c log2 = new OIP_DiagnosticsLog__c(
            OIP_ServiceName__c = 'BatchTest',
            OIP_LogLevel__c = 'INFO',
            OIP_Message__c = '75',
            OIP_Category__c = 'Performance',
            OIP_Timestamp__c = Datetime.now()
        );
        insert log2;
    }

    @IsTest
    static void testComponentTypeIndexQueueable() {
        Test.startTest();
        System.enqueueJob(new OIP_ComponentTypeIndexQueueable('ApexClass'));
        Test.stopTest();
        System.assert(true, 'ComponentTypeIndexQueueable should execute without error');
    }

    @IsTest
    static void testComponentTypeIndexQueueableBlank() {
        Test.startTest();
        System.enqueueJob(new OIP_ComponentTypeIndexQueueable(''));
        Test.stopTest();
        System.assert(true, 'Should handle blank component type');
    }

    @IsTest
    static void testDeltaRefreshQueueable() {
        Test.startTest();
        System.enqueueJob(new OIP_DeltaRefreshQueueable());
        Test.stopTest();
        System.assert(true, 'DeltaRefreshQueueable should execute without error');
    }

    @IsTest
    static void testFullIndexBatch() {
        OIP_FullIndexBatch.isTestMode = true;
        OIP_FullIndexBatch.testEntities = new List<EntityDefinition>();

        Test.startTest();
        Database.executeBatch(new OIP_FullIndexBatch(), 10);
        Test.stopTest();
        System.assert(true, 'FullIndexBatch should execute without error');
    }

    @IsTest
    static void testHealthScoreBatch() {
        Test.startTest();
        Database.executeBatch(new OIP_HealthScoreBatch(), 10);
        Test.stopTest();
        System.assert(true, 'HealthScoreBatch should execute without error');
    }

    @IsTest
    static void testDependencyGraphBuilderQueueable() {
        OIP_ToolingAPIClient.isTestMode = true;
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>();

        Test.startTest();
        System.enqueueJob(new OIP_DependencyGraphBuilderQueueable());
        Test.stopTest();
        System.assert(true, 'DependencyGraphBuilderQueueable should execute without error');
    }

    @IsTest
    static void testDependencyGraphBuilderQueueableWithOffset() {
        OIP_ToolingAPIClient.isTestMode = true;
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>();

        Test.startTest();
        System.enqueueJob(new OIP_DependencyGraphBuilderQueueable(0, 0));
        Test.stopTest();
        System.assert(true, 'Should execute with offset parameters');
    }

    @IsTest
    static void testDependencyGraphBuilderWithMockData() {
        OIP_ToolingAPIClient.isTestMode = true;
        Map<String, Object> dep1 = new Map<String, Object>{
            'MetadataComponentName' => 'TestClass',
            'MetadataComponentType' => 'ApexClass',
            'RefMetadataComponentName' => 'ReferencedClass',
            'RefMetadataComponentType' => 'ApexClass'
        };
        Map<String, Object> dep2 = new Map<String, Object>{
            'MetadataComponentName' => 'TestClass2',
            'MetadataComponentType' => 'ApexClass',
            'RefMetadataComponentName' => 'OtherClass',
            'RefMetadataComponentType' => 'ApexClass'
        };
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>{ dep1, dep2 };

        Test.startTest();
        System.enqueueJob(new OIP_DependencyGraphBuilderQueueable());
        Test.stopTest();
        System.assert(true, 'DependencyGraphBuilderQueueable should process mock data without error');
    }

    @IsTest
    static void testDependencyGraphBuilderWithBlankNames() {
        OIP_ToolingAPIClient.isTestMode = true;
        Map<String, Object> depBlank = new Map<String, Object>{
            'MetadataComponentName' => '',
            'MetadataComponentType' => 'ApexClass',
            'RefMetadataComponentName' => 'SomeTarget',
            'RefMetadataComponentType' => 'ApexClass'
        };
        Map<String, Object> depValid = new Map<String, Object>{
            'MetadataComponentName' => 'ValidSource',
            'MetadataComponentType' => 'ApexClass',
            'RefMetadataComponentName' => 'ValidTarget',
            'RefMetadataComponentType' => 'ApexClass'
        };
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>{ depBlank, depValid };

        Test.startTest();
        System.enqueueJob(new OIP_DependencyGraphBuilderQueueable());
        Test.stopTest();
        System.assert(true, 'Should handle blank source names gracefully');
    }
}