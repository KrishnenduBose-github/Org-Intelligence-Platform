/**
 * @description Batch job that calculates an org health score (0-100) based on
 *              aggregated diagnostics data. Penalizes errors, dependency risks,
 *              automation conflicts, and deployment failures with configurable caps.
 *              Final score is persisted as a summary log entry.
 * @see OIP_DiagnosticsLog__c
 */
public with sharing class OIP_HealthScoreBatch implements Database.Batchable<SObject> {

    // Accumulated counts across all execute chunks
    private Integer errorCount = 0;
    private Integer fatalCount = 0;
    private Integer highSeverityCount = 0;
    private Integer criticalSeverityCount = 0;
    private Integer automationConflictCount = 0;
    private Integer deploymentFailureCount = 0;

    /**
     * @description Returns a QueryLocator over all OIP_DiagnosticsLog__c records
     *              for health score computation.
     * @param bc  Batchable context
     * @return    QueryLocator for diagnostics logs
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OIP_LogLevel__c, OIP_ServiceName__c, OIP_Message__c,
                   OIP_Severity__c, OIP_Category__c
            FROM OIP_DiagnosticsLog__c
        ]);
    }

    /**
     * @description Processes each batch of logs and accumulates counts for each
     *              penalty category used in the health score formula.
     * @param bc      Batchable context
     * @param scope   Current batch of OIP_DiagnosticsLog__c records
     */
    public void execute(Database.BatchableContext bc, List<OIP_DiagnosticsLog__c> scope) {
        for (OIP_DiagnosticsLog__c logEntry : scope) {
            // Accumulate error and fatal counts for error penalty
            if (logEntry.OIP_LogLevel__c == 'ERROR') {
                errorCount++;
            } else if (logEntry.OIP_LogLevel__c == 'FATAL') {
                fatalCount++;
            }

            // Accumulate dependency risk counts based on severity field
            if (logEntry.OIP_Severity__c == 'High') {
                highSeverityCount++;
            } else if (logEntry.OIP_Severity__c == 'Critical') {
                criticalSeverityCount++;
            }

            // Accumulate automation conflict counts
            if (logEntry.OIP_Category__c == 'Automation Conflict') {
                automationConflictCount++;
            }

            // Accumulate deployment failure counts
            if (logEntry.OIP_Category__c == 'Deployment Failure') {
                deploymentFailureCount++;
            }
        }
    }

    /**
     * @description Computes the final health score after all batches are processed.
     *              Applies penalty caps and persists the result as a diagnostics log.
     *
     *              Formula:
     *              - errorPenalty = MIN(30, ERROR*2 + FATAL*5)
     *              - dependencyRiskPenalty = MIN(25, High*3 + Critical*5)
     *              - automationConflictPenalty = MIN(20, conflicts*4)
     *              - deploymentFailurePenalty = MIN(15, failures*3)
     *              - HealthScore = MAX(0, 100 - totalPenalties)
     *
     * @param bc  Batchable context
     */
    public void finish(Database.BatchableContext bc) {
        // Calculate error penalty: ERROR * 2 + FATAL * 5, capped at 30
        Integer errorPenalty = Math.min(30, (errorCount * 2) + (fatalCount * 5));

        // Calculate dependency risk penalty: High * 3 + Critical * 5, capped at 25
        Integer dependencyRiskPenalty = Math.min(25, (highSeverityCount * 3) + (criticalSeverityCount * 5));

        // Calculate automation conflict penalty: conflicts * 4, capped at 20
        Integer automationConflictPenalty = Math.min(20, automationConflictCount * 4);

        // Calculate deployment failure penalty: failures * 3, capped at 15
        Integer deploymentFailurePenalty = Math.min(15, deploymentFailureCount * 3);

        // Final health score: 100 minus total penalties, floored at 0
        Integer totalPenalty = errorPenalty + dependencyRiskPenalty + automationConflictPenalty + deploymentFailurePenalty;
        Integer healthScore = Math.max(0, 100 - totalPenalty);

        // Build a human-readable breakdown for the log message
        String scoreBreakdown = 'HealthScore=' + healthScore
            + ' | ErrorPenalty=' + errorPenalty + ' (' + errorCount + ' errors, ' + fatalCount + ' fatal)'
            + ' | DepRiskPenalty=' + dependencyRiskPenalty + ' (' + highSeverityCount + ' high, ' + criticalSeverityCount + ' critical)'
            + ' | AutoConflictPenalty=' + automationConflictPenalty + ' (' + automationConflictCount + ' conflicts)'
            + ' | DeployFailurePenalty=' + deploymentFailurePenalty + ' (' + deploymentFailureCount + ' failures)';

        // Persist the health score as a diagnostics log entry
        OIP_DiagnosticsLogger.log(
            'OIP_HealthScoreBatch',
            'INFO',
            scoreBreakdown,
            'HealthScore'
        );
    }
}
