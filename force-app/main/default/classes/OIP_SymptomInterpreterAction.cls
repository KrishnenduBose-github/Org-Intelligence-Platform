public with sharing class OIP_SymptomInterpreterAction {
    public class SymptomResult {
        @AuraEnabled public String componentName;
        @AuraEnabled public String componentType;
        @AuraEnabled public String errorType;
        @AuraEnabled public String severity;
    }

    @InvocableMethod(label='Interpret OIP Symptoms' description='Parses natural language descriptions into structured component references')
    public static List<String> interpretSymptoms(List<String> queries) {
        List<String> results = new List<String>();
        for (String query : queries) {
            OIP_RootCauseAnalyzerService.RootCauseResult analysis = OIP_RootCauseAnalyzerService.analyzeFailure(query.trim());
            String summary = analysis.componentName + ' (' + analysis.componentType + '): ' + analysis.summary;
            results.add(summary);
        }
        return results;
    }
}
