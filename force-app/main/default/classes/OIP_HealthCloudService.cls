public with sharing class OIP_HealthCloudService {
    public class PHIFieldReport {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public Boolean isPHI;
        @AuraEnabled public Boolean isEncrypted;
        @AuraEnabled public String complianceRisk;
    }

    public class CarePlanDependencyReport {
        @AuraEnabled public String componentName;
        @AuraEnabled public String componentType;
        @AuraEnabled public String dependencyChain;
        @AuraEnabled public String severity;
    }

    @AuraEnabled(cacheable=true)
    public static List<PHIFieldReport> getPHIFields() {
        List<PHIFieldReport> reports = new List<PHIFieldReport>();
        List<OIP_MetadataIndex__c> phiRecords = [
            SELECT OIP_FullName__c, OIP_IsPHI__c, OIP_IsEncrypted__c, OIP_ComponentType__c
            FROM OIP_MetadataIndex__c WHERE OIP_IsPHI__c = true AND OIP_ComponentType__c = 'CustomField'
            LIMIT 200
        ];
        for (OIP_MetadataIndex__c rec : phiRecords) {
            PHIFieldReport report = new PHIFieldReport();
            String[] parts = rec.OIP_FullName__c.split('\\.');
            report.objectApiName = parts.size() > 0 ? parts[0] : '';
            report.fieldApiName = parts.size() > 1 ? parts[1] : rec.OIP_FullName__c;
            report.isPHI = rec.OIP_IsPHI__c;
            report.isEncrypted = rec.OIP_IsEncrypted__c;
            report.complianceRisk = rec.OIP_IsEncrypted__c ? 'Low' : 'Medium';
            reports.add(report);
        }
        return reports;
    }

    @AuraEnabled(cacheable=true)
    public static List<CarePlanDependencyReport> getCarePlanDependencies() {
        List<CarePlanDependencyReport> results = new List<CarePlanDependencyReport>();
        List<OIP_MetadataIndex__c> carePlanRecords = [
            SELECT OIP_FullName__c, OIP_ComponentType__c
            FROM OIP_MetadataIndex__c
            WHERE OIP_FullName__c LIKE '%CarePlan%' OR OIP_FullName__c LIKE '%Care_Plan%'
            LIMIT 100
        ];
        for (OIP_MetadataIndex__c rec : carePlanRecords) {
            CarePlanDependencyReport report = new CarePlanDependencyReport();
            report.componentName = rec.OIP_FullName__c;
            report.componentType = rec.OIP_ComponentType__c;
            report.dependencyChain = 'Direct dependency';
            report.severity = 'Medium';
            results.add(report);
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<CarePlanDependencyReport> getConsentDependencies() {
        List<CarePlanDependencyReport> results = new List<CarePlanDependencyReport>();
        List<OIP_MetadataIndex__c> consentRecords = [
            SELECT OIP_FullName__c, OIP_ComponentType__c
            FROM OIP_MetadataIndex__c WHERE OIP_FullName__c LIKE '%Consent%' LIMIT 100
        ];
        for (OIP_MetadataIndex__c rec : consentRecords) {
            CarePlanDependencyReport report = new CarePlanDependencyReport();
            report.componentName = rec.OIP_FullName__c;
            report.componentType = rec.OIP_ComponentType__c;
            report.dependencyChain = 'Consent dependency';
            report.severity = 'High';
            results.add(report);
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<CarePlanDependencyReport> getEHRDependencies() {
        List<CarePlanDependencyReport> results = new List<CarePlanDependencyReport>();
        List<OIP_MetadataIndex__c> ehrRecords = [
            SELECT OIP_FullName__c, OIP_ComponentType__c
            FROM OIP_MetadataIndex__c
            WHERE OIP_FullName__c LIKE '%EHR%' OR OIP_FullName__c LIKE '%Ehr%'
            LIMIT 100
        ];
        for (OIP_MetadataIndex__c rec : ehrRecords) {
            CarePlanDependencyReport report = new CarePlanDependencyReport();
            report.componentName = rec.OIP_FullName__c;
            report.componentType = rec.OIP_ComponentType__c;
            report.dependencyChain = 'EHR integration dependency';
            report.severity = 'High';
            results.add(report);
        }
        return results;
    }
}
