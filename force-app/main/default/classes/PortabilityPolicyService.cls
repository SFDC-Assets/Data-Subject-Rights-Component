public with sharing class PortabilityPolicyService {
  
    private static final String INSTANCE_URL = URL.getSalesforceBaseUrl().toExternalForm();
    private static final String PORTABILITY_API_URL = INSTANCE_URL+'/services/data/v50.0/consent/dsr/rtp/execute';
    

    @AuraEnabled(cacheable=true)
    public static List<DsarPolicy> getPolicyDetails(){
        List<DsarPolicy> policies = [SELECT DeveloperName,Id,IsActive,MasterLabel FROM DsarPolicy ];
        return policies;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> searchObjects(String searchKey, String objectType) {
        List<SObject> results = new List<SObject>();
        if( searchKey!=null && !searchKey.equals('')){
            String key = '\'%' + searchKey + '%\'';
            String query = 'SELECT Id, Name FROM '+objectType+' WHERE Name LIKE '+key+' LIMIT 5';
            results = Database.query(query);
        }
        return results;
    }

    @AuraEnabled
    public static void createDSR(String dataSubjectId, String policyName, String selectedObjectName, String subjectName){
        try {
            submitDSAR(dataSubjectId, policyName, selectedObjectName, subjectName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Data_Subject_Request__c> getAllDSRs(){
        try {
            List<Data_Subject_Request__c> requests = new List<Data_Subject_Request__c>();
            requests = [SELECT Id, Status__c, Data_Subject_Id__c, Policy_File_Id__c , Policy_File_URL__c , Policy_Name__c , Name, Data_Subject_Name__c, Data_Subject_Type__c FROM Data_Subject_Request__c];
            return requests;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @future(callout=true)
    private static void submitDSAR(String dataSubjectId, String policyName, String selectedObjectName, String subjectName){
        try{
        String body =  '{"dataSubjectId" : "'+dataSubjectId+'", "policyName" : "'+policyName+'"}';   
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(PORTABILITY_API_URL);
        request.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId()); 
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(body);
        HttpResponse response = http.send(request);
        Data_Subject_Request__c dsr = new Data_Subject_Request__c();
        dsr.Data_Subject_Id__c = dataSubjectId;
        dsr.Policy_Name__c = policyName;
        dsr.Data_Subject_Name__c = subjectName;
        dsr.Data_Subject_Type__c = selectedObjectName;
        

        if(response.getStatusCode()==200){  
            Map<String, Object> o = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if(o.get('status') != 'Failure'){
                Map<String,Object> result = (Map<String,Object>) o.get('result');
                dsr.Status__c = (String)result.get('policyFileStatus');
                dsr.Policy_File_URL__c = (String)result.get('policyFileUrl');
                dsr.Policy_File_Id__c = (String)result.get('policyFileId');
                
            } else {
                dsr.Status__c = 'Failed';
                System.debug(' httpResponse ' + response.getBody() ); 
                throw new CalloutException( response.getBody() ); 
            }
            insert dsr;
        }
        else {
            dsr.Status__c = 'Failed';
            insert dsr;
            System.debug(' httpResponse ' + response.getBody() ); 
            throw new CalloutException( response.getBody() ); 
        }
    } catch (Exception e){
        System.debug(e);
        throw e;
    }
 }


}
