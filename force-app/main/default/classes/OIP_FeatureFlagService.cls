public with sharing class OIP_FeatureFlagService {
    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getAllFeatureFlags() {
        Map<String, Boolean> flags = new Map<String, Boolean>();
        List<OIP_Config__mdt> configs = [
            SELECT DeveloperName, OIP_IsEnabled__c FROM OIP_Config__mdt
        ];
        for (OIP_Config__mdt cfg : configs) {
            flags.put(cfg.DeveloperName, cfg.OIP_IsEnabled__c);
        }
        return flags;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isFeatureEnabled(String featureName) {
        List<OIP_Config__mdt> configs = [
            SELECT OIP_IsEnabled__c FROM OIP_Config__mdt WHERE DeveloperName = :featureName LIMIT 1
        ];
        return !configs.isEmpty() && configs[0].OIP_IsEnabled__c;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isPHIModeEnabled() {
        return isFeatureEnabled('Enable_PHI_Mode');
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isExportCSVEnabled() {
        return isFeatureEnabled('Enable_Export_CSV');
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isExportPDFEnabled() {
        return isFeatureEnabled('Enable_Export_PDF');
    }
}
