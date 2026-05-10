public with sharing class OIP_DependencySummarizerAction {
    @InvocableMethod(label='Summarize Dependencies' description='Produces human-readable dependency chain summaries')
    public static List<String> summarizeDependencies(List<String> componentFullNames) {
        List<String> summaries = new List<String>();
        for (String fullName : componentFullNames) {
            OIP_DependencyNode__c node = OIP_DependencyGraphEngine.getNodeByName(fullName);
            if (node == null) {
                summaries.add('No dependency data for: ' + fullName);
                continue;
            }
            String summary = 'Component: ' + node.OIP_FullName__c + ' (' + node.OIP_ComponentType__c + '). ';
            summary += 'Dependent count: ' + (node.OIP_DependentCount__c != null ? node.OIP_DependentCount__c : 0) + '. ';
            summary += 'Severity: ' + (node.OIP_SeverityRating__c != null ? node.OIP_SeverityRating__c : 'Unrated') + '.';
            summaries.add(summary);
        }
        return summaries;
    }
}
