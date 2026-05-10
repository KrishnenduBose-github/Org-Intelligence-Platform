public with sharing class OIP_DependencyGraphEngine {
    public class TraversalResult {
        @AuraEnabled public Id nodeId;
        @AuraEnabled public String fullName;
        @AuraEnabled public String componentType;
        @AuraEnabled public Integer depth;
        @AuraEnabled public String severityRating;
    }

    /**
     * @description Traverses the dependency graph BFS from a starting node to find all dependents.
     * @param startNodeId The OIP_DependencyNode__c Id to start from
     * @param maxDepth Maximum traversal depth (capped at 5)
     * @return Ordered list of TraversalResult objects by depth level
     */
    @AuraEnabled(cacheable=true)
    public static List<TraversalResult> traverseBFS(Id startNodeId, Integer maxDepth) {
        if (maxDepth == null || maxDepth > 5) maxDepth = 5;
        List<TraversalResult> results = new List<TraversalResult>();
        Set<Id> visited = new Set<Id>();
        Map<Integer, Set<Id>> levelNodes = new Map<Integer, Set<Id>>();
        levelNodes.put(0, new Set<Id>{startNodeId});
        visited.add(startNodeId);

        for (Integer depth = 0; depth <= maxDepth; depth++) {
            if (!levelNodes.containsKey(depth) || levelNodes.get(depth).isEmpty()) break;
            Set<Id> currentLevel = levelNodes.get(depth);
            List<OIP_DependencyNode__c> nodes = [
                SELECT Id, OIP_FullName__c, OIP_ComponentType__c, OIP_SeverityRating__c
                FROM OIP_DependencyNode__c WHERE Id IN :currentLevel
            ];
            for (OIP_DependencyNode__c node : nodes) {
                results.add(buildTraversalResult(node, depth));
            }
            if (depth < maxDepth && results.size() < 500) {
                List<OIP_DependencyEdge__c> edges = [
                    SELECT OIP_TargetNodeId__c FROM OIP_DependencyEdge__c
                    WHERE OIP_SourceNodeId__c IN :currentLevel
                ];
                Set<Id> nextLevel = new Set<Id>();
                for (OIP_DependencyEdge__c edge : edges) {
                    if (!visited.contains(edge.OIP_TargetNodeId__c)) {
                        nextLevel.add(edge.OIP_TargetNodeId__c);
                        visited.add(edge.OIP_TargetNodeId__c);
                    }
                }
                if (!nextLevel.isEmpty()) levelNodes.put(depth + 1, nextLevel);
            }
        }
        return results;
    }

    /**
     * @description Traverses the dependency graph in reverse to find all components that depend on the given node.
     * @param startNodeId The OIP_DependencyNode__c Id
     * @param maxDepth Maximum traversal depth (capped at 5)
     * @return Ordered list of TraversalResult objects
     */
    @AuraEnabled(cacheable=true)
    public static List<TraversalResult> traverseReverseBFS(Id startNodeId, Integer maxDepth) {
        if (maxDepth == null || maxDepth > 5) maxDepth = 5;
        List<TraversalResult> results = new List<TraversalResult>();
        Set<Id> visited = new Set<Id>();
        Map<Integer, Set<Id>> levelNodes = new Map<Integer, Set<Id>>();
        levelNodes.put(0, new Set<Id>{startNodeId});
        visited.add(startNodeId);

        for (Integer depth = 0; depth <= maxDepth; depth++) {
            if (!levelNodes.containsKey(depth) || levelNodes.get(depth).isEmpty()) break;
            Set<Id> currentLevel = levelNodes.get(depth);
            List<OIP_DependencyNode__c> nodes = [
                SELECT Id, OIP_FullName__c, OIP_ComponentType__c, OIP_SeverityRating__c
                FROM OIP_DependencyNode__c WHERE Id IN :currentLevel
            ];
            for (OIP_DependencyNode__c node : nodes) {
                results.add(buildTraversalResult(node, depth));
            }
            if (depth < maxDepth && results.size() < 500) {
                List<OIP_DependencyEdge__c> edges = [
                    SELECT OIP_SourceNodeId__c FROM OIP_DependencyEdge__c
                    WHERE OIP_TargetNodeId__c IN :currentLevel
                ];
                Set<Id> nextLevel = new Set<Id>();
                for (OIP_DependencyEdge__c edge : edges) {
                    if (!visited.contains(edge.OIP_SourceNodeId__c)) {
                        nextLevel.add(edge.OIP_SourceNodeId__c);
                        visited.add(edge.OIP_SourceNodeId__c);
                    }
                }
                if (!nextLevel.isEmpty()) levelNodes.put(depth + 1, nextLevel);
            }
        }
        return results;
    }

    /**
     * @description Gets a single dependency node by its Id.
     * @param nodeId The OIP_DependencyNode__c Id
     * @return The dependency node or null
     */
    @AuraEnabled(cacheable=true)
    public static OIP_DependencyNode__c getNode(Id nodeId) {
        List<OIP_DependencyNode__c> nodes = [
            SELECT Id, OIP_FullName__c, OIP_ComponentType__c, OIP_SeverityRating__c,
                   OIP_DependencyCount__c, OIP_DependentCount__c, OIP_MetadataIndexId__c
            FROM OIP_DependencyNode__c WHERE Id = :nodeId LIMIT 1
        ];
        return nodes.isEmpty() ? null : nodes[0];
    }

    /**
     * @description Looks up a dependency node by its full component name.
     * @param fullName The OIP_FullName__c value
     * @return The dependency node or null
     */
    @AuraEnabled(cacheable=true)
    public static OIP_DependencyNode__c getNodeByName(String fullName) {
        List<OIP_DependencyNode__c> nodes = [
            SELECT Id, OIP_FullName__c, OIP_ComponentType__c, OIP_SeverityRating__c,
                   OIP_DependencyCount__c, OIP_DependentCount__c
            FROM OIP_DependencyNode__c WHERE OIP_FullName__c = :fullName LIMIT 1
        ];
        return nodes.isEmpty() ? null : nodes[0];
    }

    /**
     * @description Gets all edges from a given source node.
     * @param sourceNodeId The source OIP_DependencyNode__c Id
     * @return List of edges
     */
    @AuraEnabled(cacheable=true)
    public static List<OIP_DependencyEdge__c> getOutgoingEdges(Id sourceNodeId) {
        return [
            SELECT Id, OIP_TargetNodeId__c, OIP_TargetNodeId__r.OIP_FullName__c,
                   OIP_TargetNodeId__r.OIP_ComponentType__c, OIP_EdgeType__c, OIP_Strength__c, OIP_Description__c
            FROM OIP_DependencyEdge__c WHERE OIP_SourceNodeId__c = :sourceNodeId
        ];
    }

    /**
     * @description Gets all edges pointing to a given target node.
     * @param targetNodeId The target OIP_DependencyNode__c Id
     * @return List of edges
     */
    @AuraEnabled(cacheable=true)
    public static List<OIP_DependencyEdge__c> getIncomingEdges(Id targetNodeId) {
        return [
            SELECT Id, OIP_SourceNodeId__c, OIP_SourceNodeId__r.OIP_FullName__c,
                   OIP_SourceNodeId__r.OIP_ComponentType__c, OIP_EdgeType__c, OIP_Strength__c, OIP_Description__c
            FROM OIP_DependencyEdge__c WHERE OIP_TargetNodeId__c = :targetNodeId
        ];
    }

    /**
     * @description Calculates severity rating based on dependent count.
     * @param nodeId The OIP_DependencyNode__c Id
     * @return Severity rating string
     */
    @AuraEnabled(cacheable=true)
    public static String calculateSeverity(Id nodeId) {
        List<OIP_DependencyNode__c> nodes = [
            SELECT OIP_DependentCount__c FROM OIP_DependencyNode__c WHERE Id = :nodeId LIMIT 1
        ];
        if (nodes.isEmpty()) return 'None';
        Integer count = nodes[0].OIP_DependentCount__c != null ? (Integer)nodes[0].OIP_DependentCount__c : 0;
        if (count > 50) return 'Critical';
        if (count > 20) return 'High';
        if (count > 5) return 'Medium';
        return 'Low';
    }

    /**
     * @description Finds all nodes matching a search term by partial name match.
     * @param searchTerm Partial name to search for
     * @return Matching dependency nodes
     */
    @AuraEnabled(cacheable=true)
    public static List<OIP_DependencyNode__c> searchNodes(String searchTerm) {
        String likeTerm = '%' + searchTerm + '%';
        return [
            SELECT Id, OIP_FullName__c, OIP_ComponentType__c, OIP_SeverityRating__c,
                   OIP_DependencyCount__c, OIP_DependentCount__c
            FROM OIP_DependencyNode__c
            WHERE OIP_FullName__c LIKE :likeTerm
            LIMIT 50
        ];
    }

    private static TraversalResult buildTraversalResult(OIP_DependencyNode__c node, Integer depth) {
        TraversalResult result = new TraversalResult();
        result.nodeId = node.Id;
        result.fullName = node.OIP_FullName__c;
        result.componentType = node.OIP_ComponentType__c;
        result.depth = depth;
        result.severityRating = node.OIP_SeverityRating__c;
        return result;
    }
}
