/**
 * @description Batch job that initiates a full metadata index by querying all
 *              customizable EntityDefinition records and dispatching per-type
 *              queueable jobs for each component category.
 * @see OIP_ComponentTypeIndexQueueable
 * @see OIP_DependencyGraphBuilderQueueable
 */
public with sharing class OIP_FullIndexBatch implements Database.Batchable<SObject> {

    /**
     * @description Returns a QueryLocator over all customizable entity definitions
     *              in the org, which will drive the component type enumeration.
     * @param bc  Batchable context provided by the platform
     * @return    QueryLocator for EntityDefinition records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT QualifiedApiName, NamespacePrefix, IsCustomizable
            FROM EntityDefinition
            WHERE IsCustomizable = true
        ]);
    }

    /**
     * @description For each batch of EntityDefinition records, extracts distinct
     *              component types and enqueues an OIP_ComponentTypeIndexQueueable
     *              for each one. This distributes indexing work across async jobs.
     * @param bc      Batchable context
     * @param scope   Current batch of EntityDefinition records
     */
    public void execute(Database.BatchableContext bc, List<EntityDefinition> scope) {
        // Collect distinct component types from the entity definitions
        Set<String> componentTypes = new Set<String>();
        for (EntityDefinition entity : scope) {
            if (String.isNotBlank(entity.QualifiedApiName)) {
                componentTypes.add(entity.QualifiedApiName);
            }
        }

        // Enqueue a queueable job for each component type
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
            // Placeholder: queue dependency graph builder once indexing is complete
            // System.enqueueJob(new OIP_DependencyGraphBuilderQueueable());
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
