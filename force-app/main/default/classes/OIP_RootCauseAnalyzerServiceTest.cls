@IsTest
private class OIP_RootCauseAnalyzerServiceTest {
    @TestSetup
    static void makeData() {
        OIP_MetadataIndex__c idx = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'ApexClass',
            OIP_FullName__c = 'TestFailingService',
            OIP_CompoundKey__c = 'ApexClass||TestFailingService',
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idx;

        OIP_DiagnosticsLog__c log1 = new OIP_DiagnosticsLog__c(
            OIP_ServiceName__c = 'TestService',
            OIP_LogLevel__c = 'ERROR',
            OIP_Message__c = 'Null pointer exception in handler',
            OIP_Category__c = 'Governor',
            OIP_ComponentRef__c = 'TestFailingService',
            OIP_Timestamp__c = Datetime.now()
        );
        insert log1;

        OIP_DiagnosticsLog__c log2 = new OIP_DiagnosticsLog__c(
            OIP_ServiceName__c = 'TestService',
            OIP_LogLevel__c = 'WARN',
            OIP_Message__c = 'Dependency check failed',
            OIP_Category__c = 'Dependency',
            OIP_ComponentRef__c = 'TestFailingService',
            OIP_Timestamp__c = Datetime.now()
        );
        insert log2;
    }

    @IsTest
    static void testAnalyzeFailureWithErrors() {
        Test.startTest();
        OIP_RootCauseAnalyzerService.RootCauseResult result = OIP_RootCauseAnalyzerService.analyzeFailure('TestFailingService');
        Test.stopTest();
        System.assertEquals('TestFailingService', result.componentName, 'Should return the correct component');
        System.assert(result.hypotheses.size() > 0, 'Should generate hypotheses');
    }

    @IsTest
    static void testAnalyzeFailureNotFound() {
        Test.startTest();
        OIP_RootCauseAnalyzerService.RootCauseResult result = OIP_RootCauseAnalyzerService.analyzeFailure('NonExistentClass');
        Test.stopTest();
        System.assertEquals(0, result.overallConfidence, 'Unknown component should have 0 confidence');
    }

    @IsTest
    static void testGenerateChecklist() {
        Test.startTest();
        List<String> checklist = OIP_RootCauseAnalyzerService.generateChecklist('Null reference');
        Test.stopTest();
        System.assert(checklist.size() > 0, 'Should generate checklist items');
    }

    @IsTest
    static void testConfidenceScoring() {
        OIP_RootCauseAnalyzerService.Symptom s = new OIP_RootCauseAnalyzerService.Symptom();
        s.componentName = 'Test';
        s.componentType = 'ApexClass';
        s.errorType = 'Null pointer';
        s.weight = 3;

        Test.startTest();
        Integer confidence = OIP_RootCauseAnalyzerService.calculateConfidence(s, new List<OIP_RootCauseAnalyzerService.Symptom>{s});
        Test.stopTest();
        System.assert(confidence >= 40 && confidence <= 99, 'Confidence should be in valid range');
    }
}
