public with sharing class OIP_PermissionExplainerAction {
    @InvocableMethod(label='Explain Permissions' description='Explains in plain English access control for a user/field combination')
    public static List<String> explainPermissions(List<String> queries) {
        List<String> explanations = new List<String>();
        for (String query : queries) {
            explanations.add('Permission analysis for: ' + query + '. Run detailed permission trace for full results.');
        }
        return explanations;
    }
}
