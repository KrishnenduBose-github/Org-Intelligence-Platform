public with sharing class OIP_PermissionResolverService {
    public class PermissionTrace {
        @AuraEnabled public String objectName;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String accessLevel;
        @AuraEnabled public List<PermissionSource> sources;
    }

    public class PermissionSource {
        @AuraEnabled public String sourceType;
        @AuraEnabled public String sourceName;
        @AuraEnabled public String accessGranted;
    }

    public class PHITrace {
        @AuraEnabled public String objectName;
        @AuraEnabled public Boolean isPHIField;
        @AuraEnabled public String complianceRisk;
    }

    @AuraEnabled(cacheable=true)
    public static PermissionTrace resolveFieldAccess(Id userId, String objectApiName, String fieldApiName) {
        PermissionTrace trace = new PermissionTrace();
        trace.objectName = objectApiName;
        trace.fieldName = fieldApiName;
        trace.sources = new List<PermissionSource>();
        trace.accessLevel = 'None';

        List<PermissionSetAssignment> assignments = [
            SELECT PermissionSetId, PermissionSet.Name, PermissionSet.IsOwnedByProfile
            FROM PermissionSetAssignment WHERE AssigneeId = :userId
        ];
        if (assignments.isEmpty()) return trace;

        Set<Id> permSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : assignments) {
            permSetIds.add(psa.PermissionSetId);
        }

        List<FieldPermissions> fieldPerms = [
            SELECT Field, PermissionsRead, PermissionsEdit, ParentId, Parent.Name, Parent.IsOwnedByProfile
            FROM FieldPermissions
            WHERE Field = :objectApiName + '.' + fieldApiName AND ParentId IN :permSetIds
        ];
        for (FieldPermissions fp : fieldPerms) {
            PermissionSource source = new PermissionSource();
            source.sourceType = fp.Parent.IsOwnedByProfile ? 'Profile' : 'PermissionSet';
            source.sourceName = fp.Parent.Name;
            if (fp.PermissionsEdit) { source.accessGranted = 'Edit'; trace.accessLevel = 'Edit'; }
            else if (fp.PermissionsRead) { source.accessGranted = 'Read'; if (trace.accessLevel != 'Edit') trace.accessLevel = 'Read'; }
            trace.sources.add(source);
        }

        List<ObjectPermissions> objPerms = [
            SELECT PermissionsRead, PermissionsEdit, Parent.Name, Parent.IsOwnedByProfile
            FROM ObjectPermissions
            WHERE SobjectType = :objectApiName AND ParentId IN :permSetIds
        ];
        for (ObjectPermissions op : objPerms) {
            PermissionSource source = new PermissionSource();
            source.sourceType = op.Parent.IsOwnedByProfile ? 'Profile' : 'PermissionSet';
            source.sourceName = op.Parent.Name;
            source.accessGranted = op.PermissionsEdit ? 'Edit' : 'Read';
            trace.sources.add(source);
        }

        return trace;
    }

    @AuraEnabled(cacheable=true)
    public static PHITrace tracePHIAccess(String objectApiName) {
        PHITrace trace = new PHITrace();
        trace.objectName = objectApiName;
        trace.isPHIField = false;
        trace.complianceRisk = 'None';

        List<OIP_MetadataIndex__c> phiFields = [
            SELECT Id, OIP_FullName__c, OIP_IsPHI__c, OIP_IsEncrypted__c
            FROM OIP_MetadataIndex__c
            WHERE OIP_IsPHI__c = true AND OIP_FullName__c LIKE :objectApiName + '.%'
        ];
        if (phiFields.isEmpty()) return trace;

        trace.isPHIField = true;
        trace.complianceRisk = phiFields.size() > 3 ? 'High' : (phiFields.size() > 0 ? 'Medium' : 'Low');
        return trace;
    }
}
