public with sharing class PortabilityPolicyService {
  private static final String INSTANCE_URL = URL.getSalesforceBaseUrl()
    .toExternalForm();
  private static final String PORTABILITY_API_URL =
    INSTANCE_URL + '/services/data/v50.0/consent/dsr/rtp/execute';
  private static final String GET_DSAR_STATUS_URL =
    PORTABILITY_API_URL + '?policyFileId=';

  @AuraEnabled(cacheable=true)
  public static List<DsarPolicy> getPolicyDetails() {
    List<DsarPolicy> policies = [
      SELECT DeveloperName, Id, IsActive, MasterLabel
      FROM DsarPolicy
    ];
    return policies;
  }

  @AuraEnabled(cacheable=true)
  public static List<SObject> searchObjects(
    String searchKey,
    String objectType
  ) {
    List<SObject> results = new List<SObject>();
    if (searchKey != null && !searchKey.equals('')) {
      String key = '\'%' + searchKey + '%\'';
      String query =
        'SELECT Id, Name FROM ' +
        objectType +
        ' WHERE Name LIKE ' +
        key +
        ' LIMIT 5';
      results = Database.query(query);
    }
    return results;
  }

  @AuraEnabled
  public static String createDSR(
    String dataSubjectId,
    String policyName,
    String selectedObjectName,
    String subjectName
  ) {
    try {
      Data_Subject_Request__c dsr = new Data_Subject_Request__c();
      dsr.Data_Subject_Id__c = dataSubjectId;
      dsr.Policy_Name__c = policyName;
      dsr.Data_Subject_Name__c = subjectName;
      dsr.Data_Subject_Type__c = selectedObjectName;
      dsr.Status__c = 'Submitted';
      insert dsr;
      submitDSAR(dataSubjectId, policyName, dsr.Id);
      return dsr.Id;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static String updateStatus(String recordId) {
    try {
      updateDSRStatus(recordId);
      return recordId;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Data_Subject_Request__c> getAllDSRs() {
    try {
      List<Data_Subject_Request__c> requests = new List<Data_Subject_Request__c>();
      requests = [
        SELECT
          Id,
          Status__c,
          Data_Subject_Id__c,
          Policy_File_Id__c,
          Policy_File_URL__c,
          Policy_Name__c,
          Name,
          Data_Subject_Name__c,
          Data_Subject_Type__c,
          CreatedDate
        FROM Data_Subject_Request__c
        ORDER BY CreatedDate DESC
      ];
      for (Data_Subject_Request__c dsar : requests) {
        if (dsar.Status__c != 'Complete') {
          dsar.Policy_File_URL__c = '';
        }
      }
      return requests;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void deleteAllDSRs() {
    try {
      List<Data_Subject_Request__c> requests = new List<Data_Subject_Request__c>();
      requests = [SELECT Id FROM Data_Subject_Request__c];
      delete requests;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void deleteDSR(String recordId) {
    try {
      Data_Subject_Request__c request = new Data_Subject_Request__c();
      request.Id = recordId;
      delete request;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @future(callout=true)
  private static void submitDSAR(
    String dataSubjectId,
    String policyName,
    String dsrId
  ) {
    try {
      String body =
        '{"dataSubjectId" : "' +
        dataSubjectId +
        '", "policyName" : "' +
        policyName +
        '"}';
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
      dsr.Id = dsrId;
      if (response.getStatusCode() == 200) {
        Map<String, Object> o = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        if (o.get('status') != 'Failure') {
          Map<String, Object> result = (Map<String, Object>) o.get('result');
          dsr.Status__c = (String) result.get('policyFileStatus');
          dsr.Policy_File_URL__c = (String) result.get('policyFileUrl');
          dsr.Policy_File_Id__c = (String) result.get('policyFileId');
          update dsr;
          Data_Subject_Request_Event__e dsrEvent = new Data_Subject_Request_Event__e();
          dsrEvent.DSR_ID__c = dsrId;
          Database.SaveResult sr = Eventbus.publish(dsrEvent);
          if (sr.getErrors().size() > 0) {
            String errorMessage = '';
            Boolean isError = false;
            for (Database.Error err : sr.getErrors()) {
              if ((err.getStatusCode() + '') == 'OPERATION_ENQUEUED') {
                isError = false;
                break;
              } else {
                errorMessage +=
                  err.getStatusCode() +
                  ' - ' +
                  err.getMessage() +
                  '\n';
                isError = true;
              }
            }
            if (isError) {
              dsr.Status__c = 'Failed';
              update dsr;
              throw new EventObjectException(errorMessage);
            }
          }
        } else {
          System.debug(' httpResponse ' + response.getBody());
          throw new CalloutException(response.getBody());
        }
      } else {
        System.debug(' httpResponse ' + response.getBody());
        throw new CalloutException(response.getBody());
      }
    } catch (Exception e) {
      Data_Subject_Request__c dsar = new Data_Subject_Request__c();
      dsar.Id = dsrId;
      dsar.Status__c = 'Failed';
      update dsar;
      Data_Subject_Request_Event__e dsrEvent = new Data_Subject_Request_Event__e();
      dsrEvent.DSR_ID__c = dsar.Id;
      Database.SaveResult sr = Eventbus.publish(dsrEvent);
      System.debug(e);
    }
  }

  @future(callout=true)
  private static void updateDSRStatus(String recordId) {
    try {
      Data_Subject_Request__c dsar = [
        SELECT Id, Status__c, Policy_File_URL__c, Policy_File_Id__c
        FROM Data_Subject_Request__c
        WHERE Id = :recordId
      ];
      if (dsar != null) {
        String url = GET_DSAR_STATUS_URL + dsar.Policy_File_Id__c;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(url);
        request.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
          Map<String, Object> o = (Map<String, Object>) JSON.deserializeUntyped(
            response.getBody()
          );
          if (o.get('status') != 'Failure') {
            Map<String, Object> result = (Map<String, Object>) o.get('result');
            dsar.Status__c = (String) result.get('policyFileStatus');
            dsar.Policy_File_URL__c = (String) result.get('policyFileUrl');
            dsar.Policy_File_Id__c = (String) result.get('policyFileId');
            update dsar;
            Data_Subject_Request_Event__e dsrEvent = new Data_Subject_Request_Event__e();
            dsrEvent.DSR_ID__c = dsar.Id;
            Database.SaveResult sr = Eventbus.publish(dsrEvent);
            if (sr.getErrors().size() > 0) {
              String errorMessage = '';
              Boolean isError = false;
              for (Database.Error err : sr.getErrors()) {
                if ((err.getStatusCode() + '') == 'OPERATION_ENQUEUED') {
                  isError = false;
                  break;
                } else {
                  errorMessage +=
                    err.getStatusCode() +
                    ' - ' +
                    err.getMessage() +
                    '\n';
                  isError = true;
                }
              }
              if (isError) {
                dsar.Status__c = 'Failed';
                update dsar;
                throw new EventObjectException(errorMessage);
              }
            }
          } else {
            System.debug(' httpResponse ' + response.getBody());
            throw new CalloutException(response.getBody());
          }
        } else {
          System.debug(' httpResponse ' + response.getBody());
          throw new CalloutException(response.getBody());
        }
      }
    } catch (Exception e) {
      Data_Subject_Request__c dsar = new Data_Subject_Request__c();
      dsar.Id = recordId;
      dsar.Status__c = 'Failed';
      update dsar;
      Data_Subject_Request_Event__e dsrEvent = new Data_Subject_Request_Event__e();
      dsrEvent.DSR_ID__c = dsar.Id;
      Database.SaveResult sr = Eventbus.publish(dsrEvent);
      System.debug(e);
    }
  }
}
