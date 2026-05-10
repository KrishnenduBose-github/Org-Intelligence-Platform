@IsTest
private class OIP_PermissionResolverServiceTest {
    @TestSetup
    static void makeData() {
        OIP_MetadataIndex__c idx = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'CustomField',
            OIP_FullName__c = 'Account.Name',
            OIP_CompoundKey__c = 'CustomField||Account.Name',
            OIP_IsPHI__c = true,
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idx;
    }

    @IsTest
    static void testResolveFieldAccess() {
        Id currentUserId = UserInfo.getUserId();
        Test.startTest();
        OIP_PermissionResolverService.PermissionTrace trace =
            OIP_PermissionResolverService.resolveFieldAccess(currentUserId, 'Account', 'Name');
        Test.stopTest();
        System.assertNotEquals(null, trace, 'Should return a trace result');
        System.assertEquals('Account', trace.objectName, 'Object name should match');
    }

    @IsTest
    static void testResolveFieldAccessInvalidField() {
        Id currentUserId = UserInfo.getUserId();
        Test.startTest();
        OIP_PermissionResolverService.PermissionTrace trace =
            OIP_PermissionResolverService.resolveFieldAccess(currentUserId, 'InvalidObject', 'InvalidField');
        Test.stopTest();
        System.assertEquals('None', trace.accessLevel, 'No permissions for invalid field');
    }

    @IsTest
    static void testTracePHIAccess() {
        Test.startTest();
        OIP_PermissionResolverService.PHITrace trace =
            OIP_PermissionResolverService.tracePHIAccess('Account');
        Test.stopTest();
        System.assertNotEquals(null, trace, 'Should return PHI trace');
    }

    @IsTest
    static void testTracePHIAccessNoPHI() {
        Test.startTest();
        OIP_PermissionResolverService.PHITrace trace =
            OIP_PermissionResolverService.tracePHIAccess('NotReal');
        Test.stopTest();
        System.assertEquals(false, trace.isPHIField, 'Should not have PHI fields');
    }
}
