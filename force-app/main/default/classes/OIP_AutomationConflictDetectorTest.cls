@IsTest
private class OIP_AutomationConflictDetectorTest {
    @TestSetup
    static void makeData() {
        OIP_MetadataIndex__c idx = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'Flow',
            OIP_FullName__c = 'TestFlow_Account_Update',
            OIP_CompoundKey__c = 'Flow||TestFlow_Account_Update',
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idx;
    }

    @IsTest
    static void testDetectConflictsForObject() {
        Test.startTest();
        OIP_AutomationConflictDetector.ConflictReport report =
            OIP_AutomationConflictDetector.detectAllConflictsForObject('Account');
        Test.stopTest();
        System.assertNotEquals(null, report, 'Should return a conflict report');
        System.assertEquals('Account', report.objectName);
    }

    @IsTest
    static void testDetectConflictsNoAutomation() {
        Test.startTest();
        OIP_AutomationConflictDetector.ConflictReport report =
            OIP_AutomationConflictDetector.detectAllConflictsForObject('NonExistentObject__c');
        Test.stopTest();
        System.assertEquals(0, report.totalConflicts, 'No automation = no conflicts');
    }
}
