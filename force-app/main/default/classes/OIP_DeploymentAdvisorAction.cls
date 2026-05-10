public with sharing class OIP_DeploymentAdvisorAction {
    @InvocableMethod(label='Advise on Deployment' description='Advises on deployment blockers and remediation steps')
    public static List<List<String>> adviseOnDeployment(List<String> componentLists) {
        List<List<String>> allAdvice = new List<List<String>>();
        for (String compList : componentLists) {
            List<String> advice = new List<String>();
            advice.add('Analyze dependencies for all components in: ' + compList);
            advice.add('Run deployment validation before proceeding.');
            advice.add('Check for circular dependencies.');
            advice.add('Verify all required custom fields and objects exist in target org.');
            allAdvice.add(advice);
        }
        return allAdvice;
    }
}
