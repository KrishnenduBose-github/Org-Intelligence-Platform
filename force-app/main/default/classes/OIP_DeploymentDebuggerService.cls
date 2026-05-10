public with sharing class OIP_DeploymentDebuggerService {
    public class DeploymentDiff {
        @AuraEnabled public String targetOrgId;
        @AuraEnabled public List<MissingDependency> missingDependencies;
        @AuraEnabled public List<VersionConflict> versionConflicts;
        @AuraEnabled public Integer totalBlockers;
    }

    public class MissingDependency {
        @AuraEnabled public String componentName;
        @AuraEnabled public String componentType;
        @AuraEnabled public String dependencyName;
        @AuraEnabled public String dependencyType;
    }

    public class VersionConflict {
        @AuraEnabled public String componentName;
        @AuraEnabled public String sourceVersion;
        @AuraEnabled public String targetVersion;
    }

    @AuraEnabled(cacheable=true)
    public static DeploymentDiff detectMissingDependencies(List<String> componentFullNames, String targetOrgId) {
        DeploymentDiff diff = new DeploymentDiff();
        diff.targetOrgId = targetOrgId;
        diff.missingDependencies = new List<MissingDependency>();
        diff.versionConflicts = new List<VersionConflict>();
        diff.totalBlockers = 0;

        for (String fullName : componentFullNames) {
            OIP_DependencyNode__c node = OIP_DependencyGraphEngine.getNodeByName(fullName);
            if (node == null) continue;

            List<OIP_DependencyEdge__c> edges = OIP_DependencyGraphEngine.getOutgoingEdges(node.Id);
            for (OIP_DependencyEdge__c edge : edges) {
                if (edge.OIP_Strength__c == 'Strong') {
                    MissingDependency md = new MissingDependency();
                    md.componentName = fullName;
                    md.componentType = node.OIP_ComponentType__c;
                    md.dependencyName = edge.OIP_TargetNodeId__c;
                    md.dependencyType = 'Lookup';
                    diff.missingDependencies.add(md);
                }
            }
        }
        diff.totalBlockers = diff.missingDependencies.size() + diff.versionConflicts.size();
        return diff;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> generateFixActions(Id dependencyId) {
        List<String> actions = new List<String>();
        actions.add('Verify the dependency component exists in the target org.');
        actions.add('Check API version compatibility.');
        actions.add('Ensure all required fields are deployed.');
        actions.add('Run a validation deployment before proceeding.');
        return actions;
    }
}
