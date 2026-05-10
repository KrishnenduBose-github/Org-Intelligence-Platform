public with sharing class OIP_AutomationConflictDetector {
    public class ConflictReport {
        @AuraEnabled public String objectName;
        @AuraEnabled public List<TriggerConflict> triggerConflicts;
        @AuraEnabled public List<FlowConflict> flowConflicts;
        @AuraEnabled public List<ValidationConflict> validationConflicts;
        @AuraEnabled public Integer totalConflicts;
    }

    public class TriggerConflict {
        @AuraEnabled public String triggerName;
        @AuraEnabled public String eventType;
        @AuraEnabled public String conflictDescription;
    }

    public class FlowConflict {
        @AuraEnabled public String flowName;
        @AuraEnabled public String triggerType;
        @AuraEnabled public String conflictDescription;
    }

    public class ValidationConflict {
        @AuraEnabled public String ruleName;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String conflictDescription;
    }

    @AuraEnabled(cacheable=true)
    public static ConflictReport detectAllConflictsForObject(String objectApiName) {
        ConflictReport report = new ConflictReport();
        report.objectName = objectApiName;
        report.triggerConflicts = new List<TriggerConflict>();
        report.flowConflicts = new List<FlowConflict>();
        report.validationConflicts = new List<ValidationConflict>();
        report.totalConflicts = 0;

        List<ApexTrigger> triggers = [
            SELECT Id, Name, TableEnumOrId
            FROM ApexTrigger WHERE TableEnumOrId = :objectApiName
        ];
        Map<String, List<ApexTrigger>> triggersByEvent = new Map<String, List<ApexTrigger>>();
        for (ApexTrigger t : triggers) {
            if (!triggersByEvent.containsKey('all')) triggersByEvent.put('all', new List<ApexTrigger>());
            triggersByEvent.get('all').add(t);
        }
        if (triggers.size() > 1) {
            TriggerConflict tc = new TriggerConflict();
            tc.triggerName = triggers.size() + ' triggers on ' + objectApiName;
            tc.conflictDescription = 'Multiple triggers on same object may have conflicting logic';
            report.triggerConflicts.add(tc);
        }

        List<OIP_MetadataIndex__c> flowRecords = [
            SELECT Id, OIP_FullName__c, OIP_ComponentType__c
            FROM OIP_MetadataIndex__c
            WHERE OIP_ComponentType__c = 'Flow' AND OIP_FullName__c LIKE :('%' + objectApiName + '%')
            LIMIT 50
        ];
        if (flowRecords.size() > 1) {
            FlowConflict fc = new FlowConflict();
            fc.flowName = flowRecords.size() + ' flows';
            fc.triggerType = 'Record-triggered';
            fc.conflictDescription = 'Multiple flows may trigger on ' + objectApiName + ' records';
            report.flowConflicts.add(fc);
        }

        report.totalConflicts = report.triggerConflicts.size() + report.flowConflicts.size() + report.validationConflicts.size();

        OIP_DiagnosticsLogger.log('OIP_AutomationConflictDetector', 'INFO',
            'Detected ' + report.totalConflicts + ' conflicts for ' + objectApiName, objectApiName);

        return report;
    }
}
