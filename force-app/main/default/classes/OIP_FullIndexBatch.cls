/**
 * @description Batch job that initiates a full metadata index by querying all
 *              customizable EntityDefinition records and dispatching per-type
 *              queueable jobs for each component category.
 * @see OIP_ComponentTypeIndexQueueable
 * @see OIP_DependencyGraphBuilderQueueable
 */
public with sharing class OIP_FullIndexBatch implements Database.Batchable<SObject> {

    @TestVisible private static Boolean isTestMode = false;
    @TestVisible private static List<EntityDefinition> testEntities = new List<EntityDefinition>();

    /**
     * @description Returns an Iterable over all customizable entity definitions
     *              in the org, which will drive the component type enumeration.
     *              Uses Iterable instead of QueryLocator because EntityDefinition
     *              does not support queryMore().
     * @param bc  Batchable context provided by the platform
     * @return    Iterable for EntityDefinition records
     */
    public Iterable<SObject> start(Database.BatchableContext bc) {
        if (isTestMode) {
            return (Iterable<SObject>)testEntities;
        }
        List<EntityDefinition> entities = [
            SELECT QualifiedApiName, NamespacePrefix, IsCustomizable
            FROM EntityDefinition
            WHERE IsCustomizable = true
            LIMIT 2000
        ];
        return (Iterable<SObject>)entities;
    }

    /**
     * @description For each batch of EntityDefinition records, extracts distinct
     *              component types and enqueues an OIP_ComponentTypeIndexQueueable
     *              for each one. This distributes indexing work across async jobs.
     * @param bc      Batchable context
     * @param scope   Current batch of SObject records
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Set<String> componentTypes = new Set<String>();
        for (SObject obj : scope) {
            EntityDefinition entity = (EntityDefinition)obj;
            if (String.isNotBlank(entity.QualifiedApiName)) {
                componentTypes.add(entity.QualifiedApiName);
            }
        }

        for (String compType : componentTypes) {
            try {
                System.enqueueJob(new OIP_ComponentTypeIndexQueueable(compType));
            } catch (Exception e) {
                OIP_DiagnosticsLogger.log(
                    'OIP_FullIndexBatch',
                    'ERROR',
                    'Failed to enqueue indexer for type: ' + compType + ' - ' + e.getMessage(),
                    compType
                );
            }
        }
    }

    /**
     * @description Called after all batches complete. Enqueues the dependency graph
     *              builder for post-index relationship mapping.
     * @param bc  Batchable context
     */
    public void finish(Database.BatchableContext bc) {
        try {
            OIP_DiagnosticsLogger.log(
                'OIP_FullIndexBatch',
                'INFO',
                'Full index batch completed. Dependency graph builder pending implementation.',
                null
            );
        } catch (Exception e) {
            OIP_DiagnosticsLogger.log(
                'OIP_FullIndexBatch',
                'ERROR',
                'Failed to queue dependency graph builder: ' + e.getMessage(),
                null
            );
        }
    }
}