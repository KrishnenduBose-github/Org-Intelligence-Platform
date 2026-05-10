/**
 * @description Queueable job that indexes a single component type by delegating
 *              to OIP_MetadataIndexerService. Supports chaining when there are
 *              more records to process than can be handled in a single transaction.
 * @see OIP_MetadataIndexerService
 */
public with sharing class OIP_ComponentTypeIndexQueueable implements System.Queueable {

    private String componentType;
    private Integer offset;

    /**
     * @description Constructor for initial indexing of a component type.
     * @param componentType  The metadata type to index (e.g. ApexClass, Flow)
     */
    public OIP_ComponentTypeIndexQueueable(String componentType) {
        this.componentType = componentType;
        this.offset = 0;
    }

    /**
     * @description Constructor for chained indexing with a continuation offset.
     * @param componentType  The metadata type to index
     * @param offset         The record offset for the next batch
     */
    public OIP_ComponentTypeIndexQueueable(String componentType, Integer offset) {
        this.componentType = componentType;
        this.offset = offset;
    }

    /**
     * @description Executes the indexing operation for the assigned component type.
     *              If the indexer returns a full batch (200 records), chains another
     *              queueable to continue processing.
     * @param qc  Queueable context provided by the platform
     */
    public void execute(QueueableContext qc) {
        if (String.isBlank(componentType)) {
            OIP_DiagnosticsLogger.log(
                'OIP_ComponentTypeIndexQueueable',
                'WARN',
                'Cannot index blank component type.',
                null
            );
            return;
        }

        try {
            Integer indexedCount = OIP_MetadataIndexerService.indexBySOQL(componentType);

            OIP_DiagnosticsLogger.log(
                'OIP_ComponentTypeIndexQueueable',
                'INFO',
                'Indexed ' + indexedCount + ' records for type: ' + componentType,
                componentType
            );

            // If we indexed a full batch, there may be more records to process
            if (indexedCount >= OIP_MetadataIndexerService.BATCH_SIZE) {
                System.enqueueJob(new OIP_ComponentTypeIndexQueueable(
                    componentType,
                    offset + OIP_MetadataIndexerService.BATCH_SIZE
                ));
            }
        } catch (Exception e) {
            OIP_DiagnosticsLogger.log(
                'OIP_ComponentTypeIndexQueueable',
                'ERROR',
                'Indexing failed for type ' + componentType + ': ' + e.getMessage(),
                componentType
            );
        }
    }
}
