public with sharing class OIP_HealthScoreBatch implements Database.Batchable<SObject> {
    private Integer errorCount = 0;
    private Integer fatalCount = 0;
    private Integer highSeverityCount = 0;
    private Integer criticalSeverityCount = 0;
    private Integer automationConflictCount = 0;
    private Integer deploymentFailureCount = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OIP_LogLevel__c, OIP_Category__c
            FROM OIP_DiagnosticsLog__c
            WHERE OIP_LogLevel__c IN ('ERROR', 'FATAL')
               OR OIP_Category__c IN ('Deployment', 'Automation')
        ]);
    }

    public void execute(Database.BatchableContext bc, List<OIP_DiagnosticsLog__c> scope) {
        for (OIP_DiagnosticsLog__c logEntry : scope) {
            if (logEntry.OIP_LogLevel__c == 'ERROR') {
                errorCount++;
            } else if (logEntry.OIP_LogLevel__c == 'FATAL') {
                fatalCount++;
            }
            if (logEntry.OIP_Category__c == 'Deployment') {
                deploymentFailureCount++;
            } else if (logEntry.OIP_Category__c == 'Automation') {
                automationConflictCount++;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        List<OIP_DependencyNode__c> highRiskNodes = [
            SELECT Id, OIP_SeverityRating__c
            FROM OIP_DependencyNode__c
            WHERE OIP_SeverityRating__c IN ('High', 'Critical')
        ];
        for (OIP_DependencyNode__c node : highRiskNodes) {
            if (node.OIP_SeverityRating__c == 'Critical') {
                criticalSeverityCount++;
            } else if (node.OIP_SeverityRating__c == 'High') {
                highSeverityCount++;
            }
        }

        List<OIP_DependencyEdge__c> conflicts = [
            SELECT Id FROM OIP_DependencyEdge__c WHERE OIP_IsPotentialConflict__c = true
        ];
        automationConflictCount += conflicts.size();

        Integer errorPenalty = Math.min(30, (errorCount * 2) + (fatalCount * 5));
        Integer dependencyRiskPenalty = Math.min(25, (highSeverityCount * 3) + (criticalSeverityCount * 5));
        Integer automationConflictPenalty = Math.min(20, automationConflictCount * 4);
        Integer deploymentFailurePenalty = Math.min(15, deploymentFailureCount * 3);
        Integer healthScore = Math.max(0, 100 - (errorPenalty + dependencyRiskPenalty + automationConflictPenalty + deploymentFailurePenalty));

        OIP_DiagnosticsLogger.log(
            'OIP_HealthScoreBatch',
            'INFO',
            String.valueOf(healthScore),
            'Performance'
        );
    }
}
