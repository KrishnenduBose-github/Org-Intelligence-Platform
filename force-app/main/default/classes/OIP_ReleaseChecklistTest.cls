@IsTest
private class OIP_ReleaseChecklistTest {
    @IsTest
    static void testGetReleaseChecklist() {
        Test.startTest();
        List<OIP_ReleaseChecklist.ReleaseStatus> items = OIP_ReleaseChecklist.getReleaseChecklist();
        Test.stopTest();
        System.assertNotEquals(null, items, 'Should return checklist items');
        System.assert(items.size() > 0, 'Should have at least one checklist item');
    }

    @IsTest
    static void testChecklistItemStructure() {
        Test.startTest();
        List<OIP_ReleaseChecklist.ReleaseStatus> items = OIP_ReleaseChecklist.getReleaseChecklist();
        Test.stopTest();
        for (OIP_ReleaseChecklist.ReleaseStatus item : items) {
            System.assert(String.isNotBlank(item.item), 'Each item should have a name');
            System.assert(String.isNotBlank(item.status), 'Each item should have a status');
            System.assert(String.isNotBlank(item.details), 'Each item should have details');
        }
    }
}