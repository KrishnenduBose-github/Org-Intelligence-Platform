@IsTest
private class OIP_ExportServiceTest {
    @TestSetup
    static void makeData() {
        OIP_DebugSession__c session = new OIP_DebugSession__c(
            OIP_QueryText__c = 'Export Test',
            OIP_SessionType__c = 'Search',
            OIP_Status__c = 'InProgress',
            OIP_StartTime__c = Datetime.now()
        );
        insert session;

        OIP_DiagnosticsLog__c log = new OIP_DiagnosticsLog__c(
            OIP_ServiceName__c = 'ExportTestSvc',
            OIP_LogLevel__c = 'INFO',
            OIP_Message__c = 'Export test message',
            OIP_Category__c = 'Security',
            OIP_Timestamp__c = Datetime.now(),
            OIP_DebugSessionId__c = session.Id
        );
        insert log;

        OIP_MetadataIndex__c idx = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'ApexClass',
            OIP_FullName__c = 'ExportTestClass',
            OIP_CompoundKey__c = 'ApexClass||ExportTestClass',
            OIP_Status__c = 'Active',
            OIP_IsActive__c = true,
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idx;
    }

    @IsTest
    static void testExportSessionCSV() {
        OIP_ExportService.skipPermissionCheck = true;
        List<OIP_DebugSession__c> sessions = [SELECT Id FROM OIP_DebugSession__c LIMIT 1];
        Test.startTest();
        String csv = OIP_ExportService.exportSessionCSV(sessions[0].Id);
        Test.stopTest();
        System.assert(String.isNotBlank(csv), 'Should return CSV data');
        System.assert(csv.contains('Service'), 'CSV should contain header');
    }

    @IsTest
    static void testExportFindingsCSV() {
        OIP_ExportService.skipPermissionCheck = true;
        Test.startTest();
        String csv = OIP_ExportService.exportFindingsCSV('ExportTestClass');
        Test.stopTest();
        System.assert(String.isNotBlank(csv), 'Should return CSV data for findings');
    }

    @IsTest
    static void testExportFindingsCSVNonExistent() {
        OIP_ExportService.skipPermissionCheck = true;
        Test.startTest();
        String csv = OIP_ExportService.exportFindingsCSV('NonExistent');
        Test.stopTest();
        System.assertEquals('', csv, 'Should return empty string for non-existent component');
    }

    @IsTest
    static void testExportSessionCSVWithoutPermission() {
        OIP_ExportService.skipPermissionCheck = false;
        List<OIP_DebugSession__c> sessions = [SELECT Id FROM OIP_DebugSession__c LIMIT 1];
        Test.startTest();
        String csv = OIP_ExportService.exportSessionCSV(sessions[0].Id);
        Test.stopTest();
        System.assertEquals('', csv, 'Should return empty string without permission');
    }
}