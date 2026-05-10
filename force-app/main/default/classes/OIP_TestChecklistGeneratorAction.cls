public with sharing class OIP_TestChecklistGeneratorAction {
    @InvocableMethod(label='Generate Test Checklist' description='Produces verification checklists for root causes')
    public static List<List<String>> generateTestChecklist(List<String> rootCauses) {
        List<List<String>> allChecklists = new List<List<String>>();
        for (String cause : rootCauses) {
            allChecklists.add(OIP_RootCauseAnalyzerService.generateChecklist(cause));
        }
        return allChecklists;
    }
}
