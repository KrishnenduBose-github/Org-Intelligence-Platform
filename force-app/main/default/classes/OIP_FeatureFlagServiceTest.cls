@IsTest
private class OIP_FeatureFlagServiceTest {
    @IsTest
    static void testGetAllFeatureFlags() {
        Test.startTest();
        Map<String, Boolean> flags = OIP_FeatureFlagService.getAllFeatureFlags();
        Test.stopTest();
        System.assertNotEquals(null, flags, 'Should return a map of flags');
        System.assert(flags.size() > 0, 'Should have at least one feature flag');
    }

    @IsTest
    static void testIsFeatureEnabledDashboard() {
        Test.startTest();
        Boolean enabled = OIP_FeatureFlagService.isFeatureEnabled('Enable_Dashboard');
        Test.stopTest();
        System.assertNotEquals(null, enabled, 'Should return a value');
    }

    @IsTest
    static void testIsPHIModeEnabled() {
        Test.startTest();
        Boolean phiMode = OIP_FeatureFlagService.isPHIModeEnabled();
        Test.stopTest();
        System.assertEquals(false, phiMode, 'PHI Mode should be disabled by default');
    }

    @IsTest
    static void testIsExportCSVEnabled() {
        Test.startTest();
        Boolean csvEnabled = OIP_FeatureFlagService.isExportCSVEnabled();
        Test.stopTest();
        System.assertNotEquals(null, csvEnabled, 'Should return a value');
    }

    @IsTest
    static void testIsExportPDFEnabled() {
        Test.startTest();
        Boolean pdfEnabled = OIP_FeatureFlagService.isExportPDFEnabled();
        Test.stopTest();
        System.assertNotEquals(null, pdfEnabled, 'Should return a value');
    }

    @IsTest
    static void testIsFeatureEnabledNonExistent() {
        Test.startTest();
        Boolean enabled = OIP_FeatureFlagService.isFeatureEnabled('NonExistentFeature');
        Test.stopTest();
        System.assertEquals(false, enabled, 'Non-existent feature should return false');
    }
}