@IsTest
private class OIP_HealthCloudServiceTest {
    @TestSetup
    static void makeData() {
        OIP_MetadataIndex__c idx = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'CustomField',
            OIP_FullName__c = 'Patient.Health_Status__c',
            OIP_CompoundKey__c = 'CustomField||Patient.Health_Status__c',
            OIP_IsPHI__c = true,
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idx;
    }

    @IsTest
    static void testGetPHIFields() {
        Test.startTest();
        List<OIP_HealthCloudService.PHIFieldReport> reports = OIP_HealthCloudService.getPHIFields();
        Test.stopTest();
        System.assert(reports.size() > 0, 'Should return PHI fields');
    }

    @IsTest
    static void testGetCarePlanDependencies() {
        Test.startTest();
        List<OIP_HealthCloudService.CarePlanDependencyReport> reports = OIP_HealthCloudService.getCarePlanDependencies();
        Test.stopTest();
        System.assertNotEquals(null, reports, 'Should return care plan dependencies');
    }

    @IsTest
    static void testGetConsentDependencies() {
        Test.startTest();
        List<OIP_HealthCloudService.CarePlanDependencyReport> reports = OIP_HealthCloudService.getConsentDependencies();
        Test.stopTest();
        System.assertNotEquals(null, reports, 'Should return consent dependencies');
    }

    @IsTest
    static void testGetEHRDependencies() {
        Test.startTest();
        List<OIP_HealthCloudService.CarePlanDependencyReport> reports = OIP_HealthCloudService.getEHRDependencies();
        Test.stopTest();
        System.assertNotEquals(null, reports, 'Should return EHR dependencies');
    }
}
