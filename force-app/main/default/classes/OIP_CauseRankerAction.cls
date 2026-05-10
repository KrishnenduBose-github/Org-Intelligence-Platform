public with sharing class OIP_CauseRankerAction {
    @InvocableMethod(label='Rank Root Causes' description='Ranks probable root causes by confidence from symptoms')
    public static List<List<String>> rankCauses(List<String> componentFullNames) {
        List<List<String>> results = new List<List<String>>();
        for (String fullName : componentFullNames) {
            List<String> rankedCauses = new List<String>();
            OIP_RootCauseAnalyzerService.RootCauseResult analysis = OIP_RootCauseAnalyzerService.analyzeFailure(fullName);
            for (OIP_RootCauseAnalyzerService.Hypothesis h : analysis.hypotheses) {
                rankedCauses.add(h.confidenceScore + '% - ' + h.causeDescription + ' (Severity: ' + h.severity + ')');
            }
            if (rankedCauses.isEmpty()) rankedCauses.add('No root causes identified for ' + fullName);
            results.add(rankedCauses);
        }
        return results;
    }
}
