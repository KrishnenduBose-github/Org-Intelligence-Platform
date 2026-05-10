public with sharing class OIP_DeltaRefreshQueueable implements System.Queueable {
    private Datetime lastSync;

    public OIP_DeltaRefreshQueueable() {
        this.lastSync = Datetime.now().addDays(-1);
    }

    public void execute(System.QueueableContext ctx) {
        Integer refreshed = 0;

        try {
            List<OIP_MetadataIndex__c> stale = [
                SELECT Id, OIP_ComponentType__c, OIP_FullName__c
                FROM OIP_MetadataIndex__c
                WHERE OIP_IndexedAt__c < :lastSync
                LIMIT 200
            ];

            for (OIP_MetadataIndex__c record : stale) {
                record.OIP_IndexedAt__c = Datetime.now();
                record.OIP_Status__c = 'Active';
                refreshed++;
            }

            if (!stale.isEmpty()) {
                OIP_MetadataIndexerService.upsertIndexRecords(stale);
            }

            if (refreshed >= 200) {
                System.enqueueJob(new OIP_DeltaRefreshQueueable());
            }

            OIP_DiagnosticsLogger.log('OIP_DeltaRefreshQueueable', 'INFO',
                'Delta refresh completed: ' + refreshed + ' records updated', null);
        } catch (Exception e) {
            OIP_DiagnosticsLogger.log('OIP_DeltaRefreshQueueable', 'ERROR',
                'Delta refresh failed: ' + e.getMessage(), null);
        }
    }
}
