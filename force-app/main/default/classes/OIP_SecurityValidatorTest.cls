@IsTest
private class OIP_SecurityValidatorTest {
    @IsTest
    static void testRunSecurityReview() {
        Test.startTest();
        OIP_SecurityValidator.SecurityReport report = OIP_SecurityValidator.runSecurityReview();
        Test.stopTest();
        System.assertNotEquals(null, report, 'Should return a security report');
        System.assertNotEquals(null, report.findings, 'Should have findings list');
        System.assertNotEquals(null, report.recommendations, 'Should have recommendations list');
    }

    @IsTest
    static void testSecurityReportFindings() {
        Test.startTest();
        OIP_SecurityValidator.SecurityReport report = OIP_SecurityValidator.runSecurityReview();
        Test.stopTest();
        System.assert(report.findings.size() > 0, 'Should have at least one finding');
    }
}