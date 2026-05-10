public with sharing class OIP_DependencyGraphBuilderQueueable implements System.Queueable {
    private Integer offset;
    private Integer totalProcessed;

    public OIP_DependencyGraphBuilderQueueable() {
        this.offset = 0;
        this.totalProcessed = 0;
    }

    public OIP_DependencyGraphBuilderQueueable(Integer offset, Integer totalProcessed) {
        this.offset = offset;
        this.totalProcessed = totalProcessed;
    }

    /**
     * @description Executes the dependency graph build job, processes MetadataComponentDependency
     *              results in batches to avoid governor limits.
     */
    public void execute(System.QueueableContext ctx) {
        try {
            List<Map<String, Object>> deps = OIP_ToolingAPIClient.queryMetadataComponentDependencies(new List<String>());
            if (deps.isEmpty()) return;

            Map<String, Id> nodeCache = buildNodeCache();

            List<OIP_DependencyEdge__c> edges = new List<OIP_DependencyEdge__c>();
            Integer processed = 0;

            for (Map<String, Object> dep : deps) {
                String sourceName = (String) dep.get('MetadataComponentName');
                String sourceType = (String) dep.get('MetadataComponentType');
                String targetName = (String) dep.get('RefMetadataComponentName');
                String targetType = (String) dep.get('RefMetadataComponentType');

                if (String.isBlank(sourceName) || String.isBlank(targetName)) continue;

                String sourceFullName = sourceType + ':' + sourceName;
                String targetFullName = targetType + ':' + targetName;

                if (!nodeCache.containsKey(sourceFullName)) {
                    OIP_DependencyNode__c node = ensureNode(sourceFullName, sourceType, sourceName);
                    nodeCache.put(sourceFullName, node.Id);
                }
                if (!nodeCache.containsKey(targetFullName)) {
                    OIP_DependencyNode__c node = ensureNode(targetFullName, targetType, targetName);
                    nodeCache.put(targetFullName, node.Id);
                }

                edges.add(new OIP_DependencyEdge__c(
                    OIP_SourceNodeId__c = nodeCache.get(sourceFullName),
                    OIP_TargetNodeId__c = nodeCache.get(targetFullName),
                    OIP_EdgeType__c = 'References',
                    OIP_Strength__c = 'Strong'
                ));

                processed++;
                if (edges.size() >= 200) {
                    Database.insert(edges, false);
                    edges.clear();
                }
            }

            if (!edges.isEmpty()) {
                Database.insert(edges, false);
            }

            totalProcessed += processed;
            OIP_DiagnosticsLogger.log('OIP_DependencyGraphBuilderQueueable', 'INFO',
                'Processed ' + totalProcessed + ' dependencies', 'DependencyGraph');
        } catch (Exception e) {
            OIP_DiagnosticsLogger.log('OIP_DependencyGraphBuilderQueueable', 'ERROR',
                'Graph build failed: ' + e.getMessage(), 'DependencyGraph');
        }
    }

    private Map<String, Id> buildNodeCache() {
        Map<String, Id> cache = new Map<String, Id>();
        for (OIP_DependencyNode__c node : [
            SELECT Id, OIP_FullName__c, OIP_ComponentType__c
            FROM OIP_DependencyNode__c LIMIT 10000
        ]) {
            cache.put(node.OIP_ComponentType__c + ':' + node.OIP_FullName__c, node.Id);
        }
        return cache;
    }

    private OIP_DependencyNode__c ensureNode(String fullName, String componentType, String shortName) {
        List<OIP_DependencyNode__c> existing = [
            SELECT Id FROM OIP_DependencyNode__c WHERE OIP_FullName__c = :shortName LIMIT 1
        ];
        if (!existing.isEmpty()) return existing[0];

        OIP_DependencyNode__c node = new OIP_DependencyNode__c(
            OIP_ComponentType__c = componentType,
            OIP_FullName__c = shortName
        );
        insert node;
        return node;
    }
}
