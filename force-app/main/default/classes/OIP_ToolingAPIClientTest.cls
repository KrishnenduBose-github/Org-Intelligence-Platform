@IsTest
private class OIP_ToolingAPIClientTest {
    @IsTest
    static void testQueryInTestModeReturnsEmpty() {
        OIP_ToolingAPIClient.isTestMode = true;
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>();

        Test.startTest();
        List<Map<String, Object>> results = OIP_ToolingAPIClient.query('SELECT Id FROM ApexClass');
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Should return empty results in test mode');
    }

    @IsTest
    static void testQueryInTestModeWithMockData() {
        OIP_ToolingAPIClient.isTestMode = true;
        Map<String, Object> mockRecord = new Map<String, Object>{
            'Id' => '01p000000000000',
            'Name' => 'TestClass'
        };
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>{mockRecord};

        Test.startTest();
        List<Map<String, Object>> results = OIP_ToolingAPIClient.query('SELECT Id, Name FROM ApexClass');
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return mock results');
        System.assertEquals('TestClass', results[0].get('Name'), 'Should contain mock data');
    }

    @IsTest
    static void testQueryMetadataComponentDependencies() {
        OIP_ToolingAPIClient.isTestMode = true;
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>();

        Test.startTest();
        List<Map<String, Object>> results = OIP_ToolingAPIClient.queryMetadataComponentDependencies(new List<String>{'ApexClass'});
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Should return empty in test mode');
    }

    @IsTest
    static void testQueryApexClasses() {
        OIP_ToolingAPIClient.isTestMode = true;
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>();

        Test.startTest();
        List<Map<String, Object>> results = OIP_ToolingAPIClient.queryApexClasses(100);
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Should return empty in test mode');
    }

    @IsTest
    static void testQueryFlows() {
        OIP_ToolingAPIClient.isTestMode = true;
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>();

        Test.startTest();
        List<Map<String, Object>> results = OIP_ToolingAPIClient.queryFlows(100);
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Should return empty in test mode');
    }

    @IsTest
    static void testQueryApexClassesNull() {
        OIP_ToolingAPIClient.isTestMode = true;
        OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>();

        Test.startTest();
        List<Map<String, Object>> results = OIP_ToolingAPIClient.queryApexClasses(null);
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Should handle null limit');
    }
}