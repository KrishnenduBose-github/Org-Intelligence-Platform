public with sharing class OIP_DashboardController {
    @TestVisible private static Boolean skipPermissionCheck = false;

    public class HealthScoreResult {
        @AuraEnabled public Integer score;
        @AuraEnabled public List<ScoreTrendItem> trend;
    }

    public class ScoreTrendItem {
        @AuraEnabled public String scoreDate;
        @AuraEnabled public Integer score;
    }

    @AuraEnabled(cacheable=true)
    public static HealthScoreResult getHealthScore() {
        if (!FeatureManagement.checkPermission('OIP_User') && !skipPermissionCheck) {
            throw new OIP_AccessException('You do not have permission to access OIP.');
        }

        HealthScoreResult result = new HealthScoreResult();

        try {
            if (!Schema.sObjectType.OIP_DiagnosticsLog__c.isAccessible()) {
                result.score = 100;
                result.trend = new List<ScoreTrendItem>();
                return result;
            }

            Integer errorPenalty = 0;
            Integer dependencyRiskPenalty = 0;
            Integer automationConflictPenalty = 0;
            Integer deploymentFailurePenalty = 0;

            List<OIP_DiagnosticsLog__c> recentErrors = [
                SELECT Id, OIP_LogLevel__c, OIP_Category__c
                FROM OIP_DiagnosticsLog__c
                WHERE OIP_Timestamp__c >= :Datetime.now().addDays(-7)
                  AND OIP_LogLevel__c IN ('ERROR', 'FATAL')
                LIMIT 500
            ];

            for (OIP_DiagnosticsLog__c log : recentErrors) {
                if (log.OIP_LogLevel__c == 'FATAL') {
                    errorPenalty += 5;
                } else {
                    errorPenalty += 2;
                }
                if (log.OIP_Category__c == 'Deployment') {
                    deploymentFailurePenalty += 3;
                }
            }
            errorPenalty = Math.min(errorPenalty, 30);

            List<OIP_DependencyNode__c> highRiskNodes = [
                SELECT Id, OIP_SeverityRating__c
                FROM OIP_DependencyNode__c
                WHERE OIP_SeverityRating__c IN ('High', 'Critical')
            ];
            for (OIP_DependencyNode__c node : highRiskNodes) {
                if (node.OIP_SeverityRating__c == 'Critical') {
                    dependencyRiskPenalty += 5;
                } else {
                    dependencyRiskPenalty += 3;
                }
            }
            dependencyRiskPenalty = Math.min(dependencyRiskPenalty, 25);

            Integer conflictCount = [
                SELECT COUNT()
                FROM OIP_DependencyEdge__c
                WHERE OIP_IsPotentialConflict__c = true
            ];
            automationConflictPenalty = Math.min(conflictCount * 4, 20);

            deploymentFailurePenalty = Math.min(deploymentFailurePenalty, 15);

            result.score = Math.max(0, 100 - (errorPenalty + dependencyRiskPenalty + automationConflictPenalty + deploymentFailurePenalty));
            result.trend = new List<ScoreTrendItem>();

            List<OIP_DiagnosticsLog__c> healthLogs = [
                SELECT OIP_Timestamp__c, OIP_Message__c
                FROM OIP_DiagnosticsLog__c
                WHERE OIP_LogLevel__c = 'INFO'
                  AND OIP_Category__c = 'Performance'
                  AND OIP_Timestamp__c >= :Datetime.now().addDays(-30)
                ORDER BY OIP_Timestamp__c ASC
                LIMIT 30
            ];
            for (OIP_DiagnosticsLog__c hl : healthLogs) {
                ScoreTrendItem item = new ScoreTrendItem();
                item.scoreDate = String.valueOf(hl.OIP_Timestamp__c);
                item.score = Integer.valueOf(hl.OIP_Message__c);
                result.trend.add(item);
            }
        } catch (Exception e) {
            result.score = 100;
            result.trend = new List<ScoreTrendItem>();
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<OIP_DebugSession__c> getRecentSessions() {
        if (!FeatureManagement.checkPermission('OIP_User') && !skipPermissionCheck) {
            throw new OIP_AccessException('You do not have permission to access OIP.');
        }
        return [
            SELECT Id, Name, OIP_QueryText__c, OIP_SessionType__c, OIP_Status__c,
                    OIP_ConfidenceScore__c, OIP_StartTime__c
            FROM OIP_DebugSession__c
            WHERE OIP_UserId__c = :UserInfo.getUserId()
            ORDER BY OIP_StartTime__c DESC
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkOIPUserPermission() {
        return FeatureManagement.checkPermission('OIP_User');
    }
}
