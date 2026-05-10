@IsTest
private class OIP_DashboardControllerTest {
    @TestSetup
    static void makeData() {
        OIP_DebugSession__c session = new OIP_DebugSession__c(
            OIP_QueryText__c = 'Test Query',
            OIP_SessionType__c = 'Search',
            OIP_Status__c = 'InProgress',
            OIP_StartTime__c = Datetime.now()
        );
        insert session;

        try {
            OIP_DiagnosticsLog__c log = new OIP_DiagnosticsLog__c(
                OIP_ServiceName__c = 'TestService',
                OIP_LogLevel__c = 'INFO',
                OIP_Message__c = 'Test setup message',
                OIP_Category__c = 'Governor',
                OIP_Timestamp__c = Datetime.now()
            );
            insert log;
        } catch (Exception e) {
            System.debug('Test setup skipped - object may not be deployed: ' + e.getMessage());
        }
    }

    @IsTest
    static void testGetHealthScore() {
        OIP_DashboardController.skipPermissionCheck = true;
        Test.startTest();
        OIP_DashboardController.HealthScoreResult result = OIP_DashboardController.getHealthScore();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Should return health score result');
        System.assert(result.score >= 0 && result.score <= 100, 'Score should be between 0 and 100');
    }

    @IsTest
    static void testGetRecentSessions() {
        OIP_DashboardController.skipPermissionCheck = true;
        Test.startTest();
        List<OIP_DebugSession__c> sessions = OIP_DashboardController.getRecentSessions();
        Test.stopTest();
        System.assertNotEquals(null, sessions, 'Should return sessions list');
    }

    @IsTest
    static void testCheckOIPUserPermission() {
        Test.startTest();
        Boolean hasPermission = OIP_DashboardController.checkOIPUserPermission();
        Test.stopTest();
        System.assertNotEquals(null, hasPermission, 'Should return a boolean');
    }

    @IsTest
    static void testGetHealthScoreWithoutPermission() {
        OIP_DashboardController.skipPermissionCheck = false;
        Test.startTest();
        try {
            OIP_DashboardController.getHealthScore();
            System.assert(false, 'Should have thrown OIP_AccessException');
        } catch (OIP_AccessException e) {
            System.assert(true, 'Correctly threw OIP_AccessException');
        }
        Test.stopTest();
    }
}