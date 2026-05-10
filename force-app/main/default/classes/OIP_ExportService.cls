public with sharing class OIP_ExportService {
    @TestVisible private static Boolean skipPermissionCheck = false;

    @AuraEnabled(cacheable=true)
    public static String exportSessionCSV(Id sessionId) {
        if (!FeatureManagement.checkPermission('OIP_User') && !skipPermissionCheck) return '';

        List<OIP_DiagnosticsLog__c> logs = [
            SELECT OIP_ServiceName__c, OIP_LogLevel__c, OIP_Message__c, OIP_Category__c, OIP_Timestamp__c
            FROM OIP_DiagnosticsLog__c WHERE OIP_DebugSessionId__c = :sessionId
            ORDER BY OIP_Timestamp__c DESC LIMIT 500
        ];

        String csv = 'Service,Level,Message,Category,Timestamp\n';
        for (OIP_DiagnosticsLog__c log : logs) {
            csv += '"' + escapeCsv(log.OIP_ServiceName__c) + '",';
            csv += '"' + escapeCsv(log.OIP_LogLevel__c) + '",';
            csv += '"' + escapeCsv(log.OIP_Message__c) + '",';
            csv += '"' + escapeCsv(log.OIP_Category__c) + '",';
            csv += '"' + String.valueOf(log.OIP_Timestamp__c) + '"\n';
        }
        return csv;
    }

    @AuraEnabled(cacheable=true)
    public static String exportFindingsCSV(String componentName) {
        List<OIP_MetadataIndex__c> records = [
            SELECT OIP_ComponentType__c, OIP_FullName__c, OIP_Status__c, OIP_HealthRisk__c, OIP_IndexedAt__c
            FROM OIP_MetadataIndex__c WHERE OIP_FullName__c = :componentName LIMIT 1
        ];
        if (records.isEmpty()) return '';
        String csv = 'ComponentType,FullName,Status,HealthRisk,IndexedAt\n';
        for (OIP_MetadataIndex__c rec : records) {
            csv += rec.OIP_ComponentType__c + ',' + rec.OIP_FullName__c + ',' + rec.OIP_Status__c + ',';
            csv += rec.OIP_HealthRisk__c + ',' + String.valueOf(rec.OIP_IndexedAt__c) + '\n';
        }
        return csv;
    }

    private static String escapeCsv(String value) {
        if (value == null) return '';
        return value.replace('"', '""');
    }
}
