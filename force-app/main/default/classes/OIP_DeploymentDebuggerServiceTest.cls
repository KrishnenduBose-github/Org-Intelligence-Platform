@IsTest
private class OIP_DeploymentDebuggerServiceTest {
    @TestSetup
    static void makeData() {
        OIP_MetadataIndex__c idx = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'ApexClass',
            OIP_FullName__c = 'DeployTestClass',
            OIP_CompoundKey__c = 'ApexClass||DeployTestClass',
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idx;

        OIP_DependencyNode__c nodeA = new OIP_DependencyNode__c(
            OIP_ComponentType__c = 'ApexClass',
            OIP_FullName__c = 'DeployTestClass',
            OIP_MetadataIndexId__c = idx.Id,
            OIP_DependentCount__c = 5
        );
        insert nodeA;
    }

    @IsTest
    static void testDetectMissingDependencies() {
        List<String> components = new List<String>{'DeployTestClass'};
        Test.startTest();
        OIP_DeploymentDebuggerService.DeploymentDiff diff =
            OIP_DeploymentDebuggerService.detectMissingDependencies(components, 'target-org-1');
        Test.stopTest();
        System.assertNotEquals(null, diff, 'Should return deployment diff');
    }

    @IsTest
    static void testGenerateFixActions() {
        Test.startTest();
        List<String> actions = OIP_DeploymentDebuggerService.generateFixActions(null);
        Test.stopTest();
        System.assert(actions.size() > 0, 'Should generate fix actions');
    }
}
