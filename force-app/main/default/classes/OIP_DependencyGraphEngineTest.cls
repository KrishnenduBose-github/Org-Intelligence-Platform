@IsTest
private class OIP_DependencyGraphEngineTest {
    @TestSetup
    static void makeData() {
        OIP_MetadataIndex__c idxA = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'ApexClass',
            OIP_FullName__c = 'TestServiceA',
            OIP_CompoundKey__c = 'ApexClass||TestServiceA',
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idxA;

        OIP_MetadataIndex__c idxB = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'Flow',
            OIP_FullName__c = 'TestFlowB',
            OIP_CompoundKey__c = 'Flow||TestFlowB',
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idxB;

        OIP_MetadataIndex__c idxC = new OIP_MetadataIndex__c(
            OIP_ComponentType__c = 'ApexTrigger',
            OIP_FullName__c = 'TestTriggerC',
            OIP_CompoundKey__c = 'ApexTrigger||TestTriggerC',
            OIP_IsActive__c = true,
            OIP_Status__c = 'Active',
            OIP_IndexedAt__c = Datetime.now()
        );
        insert idxC;

        OIP_DependencyNode__c nodeA = new OIP_DependencyNode__c(
            OIP_ComponentType__c = 'ApexClass',
            OIP_FullName__c = 'TestServiceA',
            OIP_MetadataIndexId__c = idxA.Id,
            OIP_DependentCount__c = 10
        );
        insert nodeA;

        OIP_DependencyNode__c nodeB = new OIP_DependencyNode__c(
            OIP_ComponentType__c = 'Flow',
            OIP_FullName__c = 'TestFlowB',
            OIP_MetadataIndexId__c = idxB.Id,
            OIP_DependentCount__c = 5
        );
        insert nodeB;

        OIP_DependencyNode__c nodeC = new OIP_DependencyNode__c(
            OIP_ComponentType__c = 'ApexTrigger',
            OIP_FullName__c = 'TestTriggerC',
            OIP_MetadataIndexId__c = idxC.Id,
            OIP_DependentCount__c = 60
        );
        insert nodeC;

        OIP_DependencyEdge__c edge1 = new OIP_DependencyEdge__c(
            OIP_SourceNodeId__c = nodeA.Id,
            OIP_TargetNodeId__c = nodeB.Id,
            OIP_EdgeType__c = 'Calls',
            OIP_Strength__c = 'Strong'
        );
        insert edge1;

        OIP_DependencyEdge__c edge2 = new OIP_DependencyEdge__c(
            OIP_SourceNodeId__c = nodeB.Id,
            OIP_TargetNodeId__c = nodeC.Id,
            OIP_EdgeType__c = 'References',
            OIP_Strength__c = 'Weak'
        );
        insert edge2;
    }

    @IsTest
    static void testTraverseBFS() {
        List<OIP_DependencyNode__c> nodes = [SELECT Id FROM OIP_DependencyNode__c WHERE OIP_FullName__c = 'TestServiceA'];
        System.assertEquals(1, nodes.size(), 'Should find TestServiceA');

        Test.startTest();
        List<OIP_DependencyGraphEngine.TraversalResult> results = OIP_DependencyGraphEngine.traverseBFS(nodes[0].Id, 3);
        Test.stopTest();

        System.assert(results.size() >= 3, 'Should traverse all 3 connected nodes');
    }

    @IsTest
    static void testTraverseReverseBFS() {
        List<OIP_DependencyNode__c> nodes = [SELECT Id FROM OIP_DependencyNode__c WHERE OIP_FullName__c = 'TestTriggerC'];
        System.assertEquals(1, nodes.size());

        Test.startTest();
        List<OIP_DependencyGraphEngine.TraversalResult> results = OIP_DependencyGraphEngine.traverseReverseBFS(nodes[0].Id, 3);
        Test.stopTest();

        System.assert(results.size() >= 3, 'Should traverse all 3 connected nodes in reverse');
    }

    @IsTest
    static void testCalculateSeverity() {
        List<OIP_DependencyNode__c> nodes = [SELECT Id FROM OIP_DependencyNode__c WHERE OIP_FullName__c = 'TestTriggerC'];
        System.assertEquals(1, nodes.size());

        Test.startTest();
        String severity = OIP_DependencyGraphEngine.calculateSeverity(nodes[0].Id);
        Test.stopTest();

        System.assertEquals('Critical', severity, 'Node with 60 dependents should be Critical');
    }

    @IsTest
    static void testGetNodeByName() {
        Test.startTest();
        OIP_DependencyNode__c node = OIP_DependencyGraphEngine.getNodeByName('TestServiceA');
        Test.stopTest();
        System.assertNotEquals(null, node, 'Should find node by full name');
        System.assertEquals('ApexClass', node.OIP_ComponentType__c);
    }

    @IsTest
    static void testGetOutgoingEdges() {
        List<OIP_DependencyNode__c> nodes = [SELECT Id FROM OIP_DependencyNode__c WHERE OIP_FullName__c = 'TestServiceA'];
        System.assertEquals(1, nodes.size());

        Test.startTest();
        List<OIP_DependencyEdge__c> edges = OIP_DependencyGraphEngine.getOutgoingEdges(nodes[0].Id);
        Test.stopTest();

        System.assert(edges.size() >= 1, 'Should have at least 1 outgoing edge');
    }

    @IsTest
    static void testSearchNodes() {
        Test.startTest();
        List<OIP_DependencyNode__c> results = OIP_DependencyGraphEngine.searchNodes('TestService');
        Test.stopTest();

        System.assert(results.size() >= 1, 'Should find matching nodes');
    }

    @IsTest
    static void testTraverseBFSMaxDepth() {
        List<OIP_DependencyNode__c> nodes = [SELECT Id FROM OIP_DependencyNode__c WHERE OIP_FullName__c = 'TestServiceA'];
        Test.startTest();
        List<OIP_DependencyGraphEngine.TraversalResult> results = OIP_DependencyGraphEngine.traverseBFS(nodes[0].Id, 1);
        Test.stopTest();
        System.assert(results.size() >= 1, 'Should return at least the start node with depth limit 1');
    }
}
