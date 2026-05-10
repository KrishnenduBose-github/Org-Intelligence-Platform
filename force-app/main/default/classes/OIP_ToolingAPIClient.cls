public with sharing class OIP_ToolingAPIClient {
    private static final String TOOLING_API_BASE = '/services/data/v66.0/tooling/';

    @TestVisible private static Boolean isTestMode = false;
    @TestVisible private static List<Map<String, Object>> testMockResults = new List<Map<String, Object>>();

    /**
     * @description Executes a SOQL query against the Tooling API.
     * @param soql The SOQL query string
     * @return List of maps representing query results
     */
    public static List<Map<String, Object>> query(String soql) {
        if (isTestMode) return testMockResults;
        if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
            OIP_DiagnosticsLogger.log('OIP_ToolingAPIClient', 'WARN', 'Callout limit reached, aborting query', null);
            return new List<Map<String, Object>>();
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + TOOLING_API_BASE + 'query/?q=' + EncodingUtil.urlEncode(soql, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (List<Map<String, Object>>) body.get('records');
        }

        OIP_DiagnosticsLogger.log('OIP_ToolingAPIClient', 'ERROR',
            'Tooling API call failed: ' + res.getStatusCode() + ' - ' + res.getBody(), null);
        return new List<Map<String, Object>>();
    }

    /**
     * @description Queries MetadataComponentDependency for a given component type.
     * @param componentTypes List of metadata component types
     * @return Dependencies as list of maps
     */
    public static List<Map<String, Object>> queryMetadataComponentDependencies(List<String> componentTypes) {
        String typeFilter = String.join(componentTypes, '\',\'');
        String soql = 'SELECT Id, MetadataComponentName, MetadataComponentType, ' +
            'RefMetadataComponentName, RefMetadataComponentType ' +
            'FROM MetadataComponentDependency ' +
            'WHERE MetadataComponentType IN (\'' + typeFilter + '\') LIMIT 2000';
        return query(soql);
    }

    /**
     * @description Fetches Apex class metadata including symbol tables via Tooling API.
     */
    public static List<Map<String, Object>> queryApexClasses(Integer limitCount) {
        String soql = 'SELECT Id, Name, NamespacePrefix, ApiVersion, Status, LengthWithoutComments ' +
            'FROM ApexClass LIMIT ' + (limitCount != null ? limitCount : 2000);
        return query(soql);
    }

    /**
     * @description Fetches Flow metadata via Tooling API.
     */
    public static List<Map<String, Object>> queryFlows(Integer limitCount) {
        String soql = 'SELECT Id, FullName, MasterLabel, VersionNumber, ProcessType, ' +
            'TriggerObjectOrEvent, Description, IsActive FROM Flow WHERE Status = \'Active\' LIMIT ' +
            (limitCount != null ? limitCount : 2000);
        return query(soql);
    }
}
