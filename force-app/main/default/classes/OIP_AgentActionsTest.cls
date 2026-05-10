@IsTest
private class OIP_AgentActionsTest {
    @TestSetup
    static void makeData() {
        OIP_MetadataIndex__c idx = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'ApexClass',
            OIP_FullName__c = 'ActionTestClass',
            OIP_CompoundKey__c = 'ApexClass||ActionTestClass',
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idx;

        OIP_DependencyNode__c node = new OIP_DependencyNode__c(
            OIP_ComponentType__c = 'ApexClass',
            OIP_FullName__c = 'ActionTestClass',
            OIP_MetadataIndexId__c = idx.Id,
            OIP_DependentCount__c = 3
        );
        insert node;

        OIP_DiagnosticsLog__c log1 = new OIP_DiagnosticsLog__c(
            OIP_ServiceName__c = 'ActionTest',
            OIP_LogLevel__c = 'ERROR',
            OIP_Message__c = 'Null pointer error',
            OIP_Category__c = 'Dependency',
            OIP_ComponentRef__c = 'ActionTestClass',
            OIP_Timestamp__c = Datetime.now()
        );
        insert log1;
    }

    @IsTest
    static void testSymptomInterpreterAction() {
        Test.startTest();
        List<String> results = OIP_SymptomInterpreterAction.interpretSymptoms(new List<String>{'ActionTestClass'});
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].contains('ActionTestClass'), 'Result should contain component name');
    }

    @IsTest
    static void testCauseRankerAction() {
        Test.startTest();
        List<List<String>> results = OIP_CauseRankerAction.rankCauses(new List<String>{'ActionTestClass'});
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return one list of ranked causes');
    }

    @IsTest
    static void testDependencySummarizerAction() {
        Test.startTest();
        List<String> results = OIP_DependencySummarizerAction.summarizeDependencies(new List<String>{'ActionTestClass'});
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return one summary');
        System.assert(results[0].contains('ActionTestClass'), 'Summary should contain component name');
    }

    @IsTest
    static void testDependencySummarizerActionNonExistent() {
        Test.startTest();
        List<String> results = OIP_DependencySummarizerAction.summarizeDependencies(new List<String>{'NonExistentComponent'});
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].contains('No dependency data'), 'Should report missing data');
    }

    @IsTest
    static void testDeploymentAdvisorAction() {
        Test.startTest();
        List<List<String>> results = OIP_DeploymentAdvisorAction.adviseOnDeployment(new List<String>{'ApexClass1,ApexClass2'});
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return one advice list');
        System.assert(results[0].size() > 0, 'Should have advice items');
    }

    @IsTest
    static void testPermissionExplainerAction() {
        Test.startTest();
        List<String> results = OIP_PermissionExplainerAction.explainPermissions(new List<String>{'Account.Name'});
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return one explanation');
        System.assert(results[0].contains('Account.Name'), 'Should contain the query');
    }

    @IsTest
    static void testTestChecklistGeneratorAction() {
        Test.startTest();
        List<List<String>> results = OIP_TestChecklistGeneratorAction.generateTestChecklist(new List<String>{'Null reference'});
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return one checklist');
        System.assert(results[0].size() > 0, 'Checklist should have items');
    }
}