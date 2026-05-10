public with sharing class OIP_RootCauseAnalyzerService {
    public class RootCauseResult {
        @AuraEnabled public String componentName;
        @AuraEnabled public String componentType;
        @AuraEnabled public List<Hypothesis> hypotheses;
        @AuraEnabled public Integer overallConfidence;
        @AuraEnabled public String summary;
    }

    public class Hypothesis {
        @AuraEnabled public String causeDescription;
        @AuraEnabled public Integer confidenceScore;
        @AuraEnabled public String severity;
        @AuraEnabled public List<String> evidenceRefs;
        @AuraEnabled public String recommendation;
    }

    public class Symptom {
        @AuraEnabled public String componentName;
        @AuraEnabled public String componentType;
        @AuraEnabled public String errorType;
        @AuraEnabled public Integer weight;
    }

    @AuraEnabled(cacheable=true)
    public static RootCauseResult analyzeFailure(String componentFullName) {
        RootCauseResult result = new RootCauseResult();
        List<OIP_MetadataIndex__c> components = [
            SELECT Id, OIP_FullName__c, OIP_ComponentType__c, OIP_HealthRisk__c
            FROM OIP_MetadataIndex__c WHERE OIP_FullName__c = :componentFullName LIMIT 1
        ];
        if (components.isEmpty()) {
            result.summary = 'Component not found: ' + componentFullName;
            result.overallConfidence = 0;
            result.hypotheses = new List<Hypothesis>();
            return result;
        }

        OIP_MetadataIndex__c component = components[0];
        result.componentName = component.OIP_FullName__c;
        result.componentType = component.OIP_ComponentType__c;

        List<OIP_DiagnosticsLog__c> logs = [
            SELECT OIP_Message__c, OIP_LogLevel__c, OIP_Category__c
            FROM OIP_DiagnosticsLog__c WHERE OIP_ComponentRef__c = :componentFullName
            AND OIP_Timestamp__c >= :Datetime.now().addDays(-7)
            ORDER BY OIP_Timestamp__c DESC LIMIT 100
        ];

        List<Symptom> symptoms = extractSymptoms(component, logs);
        List<Hypothesis> hypotheses = generateHypotheses(component, symptoms, logs);
        hypotheses.sort(new HypothesisComparator());
        result.hypotheses = hypotheses;
        result.overallConfidence = hypotheses.isEmpty() ? 0 : hypotheses[0].confidenceScore;
        result.summary = buildSummary(component, hypotheses);
        return result;
    }

    public static List<Hypothesis> rankHypotheses(List<Symptom> symptoms) {
        List<Hypothesis> hypotheses = new List<Hypothesis>();
        for (Symptom symptom : symptoms) {
            Hypothesis h = new Hypothesis();
            h.causeDescription = symptom.errorType + ' detected at ' + symptom.componentName;
            h.confidenceScore = calculateConfidence(symptom, symptoms);
            h.severity = symptom.weight >= 3 ? 'High' : (symptom.weight >= 2 ? 'Medium' : 'Low');
            h.evidenceRefs = new List<String>{symptom.componentName};
            h.recommendation = 'Review ' + symptom.errorType + ' for ' + symptom.componentName;
            hypotheses.add(h);
        }
        hypotheses.sort(new HypothesisComparator());
        return hypotheses;
    }

    public static Integer calculateConfidence(Symptom primarySymptom, List<Symptom> allSymptoms) {
        Integer score = 50;
        score += primarySymptom.weight * 10;
        score = Math.min(score, 99);
        if (allSymptoms.size() == 1) score = Math.min(score, 40);
        return score;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> generateChecklist(String rootCauseDescription) {
        List<String> checklist = new List<String>();
        checklist.add('Verify the component is active and deployed.');
        checklist.add('Check recent deployment history for changes.');
        checklist.add('Review dependency graph for missing references.');
        checklist.add('Inspect related automation (flows, triggers) for conflicts.');
        checklist.add('Validate field-level and object-level permissions.');
        checklist.add('Check debug logs for related error messages.');
        return checklist;
    }

    private static List<Symptom> extractSymptoms(OIP_MetadataIndex__c component, List<OIP_DiagnosticsLog__c> logs) {
        List<Symptom> symptoms = new List<Symptom>();
        Set<String> seen = new Set<String>();
        for (OIP_DiagnosticsLog__c log : logs) {
            String errorType = categorizeError(log.OIP_Message__c, log.OIP_Category__c);
            if (!seen.contains(errorType)) {
                Symptom s = new Symptom();
                s.componentName = component.OIP_FullName__c;
                s.componentType = component.OIP_ComponentType__c;
                s.errorType = errorType;
                s.weight = (log.OIP_LogLevel__c == 'ERROR' || log.OIP_LogLevel__c == 'FATAL') ? 3 : 1;
                symptoms.add(s);
                seen.add(errorType);
            }
        }
        if (symptoms.isEmpty()) {
            Symptom s = new Symptom();
            s.componentName = component.OIP_FullName__c;
            s.componentType = component.OIP_ComponentType__c;
            s.errorType = 'No recent errors found';
            s.weight = 1;
            symptoms.add(s);
        }
        return symptoms;
    }

    private static List<Hypothesis> generateHypotheses(OIP_MetadataIndex__c component, List<Symptom> symptoms, List<OIP_DiagnosticsLog__c> logs) {
        List<Hypothesis> hypotheses = rankHypotheses(symptoms);
        List<OIP_DependencyNode__c> relatedNodes = OIP_DependencyGraphEngine.searchNodes(component.OIP_FullName__c);
        for (OIP_DependencyNode__c node : relatedNodes) {
            Hypothesis h = new Hypothesis();
            h.causeDescription = 'Dependency issue with ' + node.OIP_FullName__c + ' (' + node.OIP_ComponentType__c + ')';
            h.confidenceScore = 35;
            h.severity = node.OIP_SeverityRating__c != null ? node.OIP_SeverityRating__c : 'Medium';
            h.evidenceRefs = new List<String>{'DependencyNode:' + node.Id};
            h.recommendation = 'Investigate dependency on ' + node.OIP_FullName__c;
            hypotheses.add(h);
        }
        hypotheses.sort(new HypothesisComparator());
        return hypotheses;
    }

    private static String categorizeError(String message, String category) {
        if (category == 'Security') return 'Permission or access issue';
        if (category == 'Governor') return 'Governor limit violation';
        if (category == 'Dependency') return 'Missing or broken dependency';
        if (category == 'Deployment') return 'Deployment blocker';
        if (category == 'Automation') return 'Automation conflict';
        if (String.isNotBlank(message) && message.containsIgnoreCase('null')) return 'Null reference error';
        if (String.isNotBlank(message) && message.containsIgnoreCase('limit')) return 'Limit exceeded error';
        return 'Unknown error';
    }

    private static String buildSummary(OIP_MetadataIndex__c component, List<Hypothesis> hypotheses) {
        if (hypotheses.isEmpty()) return 'No root cause hypotheses found.';
        return 'Most likely: ' + hypotheses[0].causeDescription + ' (' + hypotheses[0].confidenceScore + '% confidence)';
    }

    private class HypothesisComparator implements Comparator<Hypothesis> {
        public Integer compare(Hypothesis a, Hypothesis b) { return b.confidenceScore - a.confidenceScore; }
    }
}
