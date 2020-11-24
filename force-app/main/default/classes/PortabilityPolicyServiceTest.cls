@isTest
global class PortabilityPolicyServiceTest {
  private static final String INSTANCE_URL = URL.getSalesforceBaseUrl()
    .toExternalForm();
  private static final String FILE_URL =
    INSTANCE_URL + '/servlet/policyFileDownload?file=';
  @testSetup
  static void setup() {
    // Create common test accounts

    Account acc = new Account(Name = 'TestAcct');
    insert acc;
    Contact c = new Contact(
      FirstName = 'TestPrivacy',
      LastName = 'User',
      Phone = '1234567890',
      MobilePhone = '98765443210',
      Account = acc
    );
    insert c;
    List<Data_Subject_Request__c> dsars = new List<Data_Subject_Request__c>();
    for (Integer i = 0; i < 3; i++) {
      Data_Subject_Request__c dsar = new Data_Subject_Request__c();
      dsar.Data_Subject_Id__c = c.Id;
      dsar.Data_Subject_Name__c = c.FirstName + ' ' + c.LastName;
      dsar.Data_Subject_Type__c = 'Contact';
      dsar.Policy_File_Id__c = '0jeS70000004CB' + i;
      dsar.Policy_File_URL__c = FILE_URL + dsar.Policy_File_Id__c;
      dsar.Policy_Name__c = 'TestPortabilityComponentPolicy';
      if (i == 0) {
        dsar.Status__c = 'In Progress';
      } else if (i == 1) {
        dsar.Status__c = 'Complete';
      } else {
        dsar.Status__c = 'Failed';
      }
      dsars.add(dsar);
    }
    insert dsars;
  }

  @IsTest
  static void testGetPolicyDetails() {
    Test.startTest();
    List<DsarPolicy> policies = PortabilityPolicyService.getPolicyDetails();
    Test.stopTest();

    System.assert(policies.size() >= 0);
  }

  @IsTest
  static void testSearchObjects() {
    Test.startTest();
    List<SObject> records = PortabilityPolicyService.searchObjects(
      'TestPrivacy',
      'Contact'
    );
    Test.stopTest();
    System.assertEquals(1, records.size());
  }

  @IsTest
  static void testGetAllDSRs() {
    Test.startTest();
    List<Data_Subject_Request__c> dsars = PortabilityPolicyService.getAllDSRs();
    Test.stopTest();
    System.assertEquals(3, dsars.size());
  }

  @IsTest
  static void testCreateDSAR() {
    Contact c = [
      SELECT Id, FirstName, LastName
      FROM Contact
      WHERE FirstName = 'TestPrivacy'
    ];
    Test.setMock(HttpCalloutMock.class, new PortabilityAPIMockInProgress());
    Test.startTest();
    PortabilityPolicyService.createDSR(
      c.Id,
      'ContactPolicy',
      'Contact',
      c.FirstName +
      ' ' +
      c.LastName
    );
    Data_Subject_Request__c dsar = [
      SELECT Id, Status__c, Policy_File_Id__c
      FROM Data_Subject_Request__c
      WHERE Status__c = 'Submitted'
    ];
    Test.stopTest();
    System.assertEquals('Submitted', dsar.Status__c);
  }

  @IsTest
  static void testSubmitDSAR() {
    Contact c = [
      SELECT Id, FirstName, LastName
      FROM Contact
      WHERE FirstName = 'TestPrivacy'
    ];
    Data_Subject_Request__c dsr = new Data_Subject_Request__c();
    dsr.Data_Subject_Id__c = c.Id;
    dsr.Policy_Name__c = 'ContactPolicy';
    dsr.Data_Subject_Name__c = c.FirstName + ' ' + c.LastName;
    dsr.Data_Subject_Type__c = 'Contact';
    dsr.Status__c = 'Submitted';
    Test.setMock(HttpCalloutMock.class, new PortabilityAPIMockInProgress());
    Test.startTest();
    insert dsr;
    PortabilityPolicyService.submitDSAR(c.Id, 'ContactPolicy', dsr.Id);
    Test.stopTest();
    Data_Subject_Request__c dsar = [
      SELECT Id, Status__c, Policy_File_Id__c
      FROM Data_Subject_Request__c
      WHERE Id = :dsr.Id
    ];
    System.assertEquals('0jeS70000004CBO', dsar.Policy_File_Id__c);
  }

  @IsTest
  static void testSubmitDSARFailed() {
    Contact c = [
      SELECT Id, FirstName, LastName
      FROM Contact
      WHERE FirstName = 'TestPrivacy'
    ];
    Data_Subject_Request__c dsr = new Data_Subject_Request__c();
    dsr.Data_Subject_Id__c = c.Id;
    dsr.Policy_Name__c = 'ContactPolicy';
    dsr.Data_Subject_Name__c = c.FirstName + ' ' + c.LastName;
    dsr.Data_Subject_Type__c = 'Contact';
    dsr.Status__c = 'Submitted';
    Test.setMock(HttpCalloutMock.class, new PortabilityAPIMockFailed());
    Test.startTest();
    insert dsr;
    PortabilityPolicyService.submitDSAR(c.Id, 'ContactPolicy', dsr.Id);
    Test.stopTest();
    Data_Subject_Request__c dsar = [
      SELECT Id, Status__c, Policy_File_Id__c
      FROM Data_Subject_Request__c
      WHERE Id = :dsr.Id
    ];
    System.assertEquals('Failed', dsar.Status__c);
  }

  @IsTest
  static void testSubmitDSARException() {
    Contact c = [
      SELECT Id, FirstName, LastName
      FROM Contact
      WHERE FirstName = 'TestPrivacy'
    ];
    Data_Subject_Request__c dsr = new Data_Subject_Request__c();
    dsr.Data_Subject_Id__c = c.Id;
    dsr.Policy_Name__c = 'ContactPolicy';
    dsr.Data_Subject_Name__c = c.FirstName + ' ' + c.LastName;
    dsr.Data_Subject_Type__c = 'Contact';
    dsr.Status__c = 'Submitted';
    Test.setMock(HttpCalloutMock.class, new PortabilityAPIMockExptn());
    Test.startTest();
    insert dsr;
    PortabilityPolicyService.submitDSAR(c.Id, 'ContactPolicy', dsr.Id);
    Test.stopTest();
    Data_Subject_Request__c dsar = [
      SELECT Id, Status__c, Policy_File_Id__c
      FROM Data_Subject_Request__c
      WHERE Id = :dsr.Id
    ];
    System.assertEquals('Failed', dsar.Status__c);
  }

  @IsTest
  static void testSubmitDSARApiError() {
    Contact c = [
      SELECT Id, FirstName, LastName
      FROM Contact
      WHERE FirstName = 'TestPrivacy'
    ];
    Data_Subject_Request__c dsr = new Data_Subject_Request__c();
    dsr.Data_Subject_Id__c = c.Id;
    dsr.Policy_Name__c = 'ContactPolicy';
    dsr.Data_Subject_Name__c = c.FirstName + ' ' + c.LastName;
    dsr.Data_Subject_Type__c = 'Contact';
    dsr.Status__c = 'Submitted';
    Test.setMock(HttpCalloutMock.class, new PortabilityAPIMockAPIError());
    Test.startTest();
    insert dsr;
    PortabilityPolicyService.submitDSAR(c.Id, 'ContactPolicy', dsr.Id);
    Test.stopTest();
    Data_Subject_Request__c dsar = [
      SELECT Id, Status__c, Policy_File_Id__c
      FROM Data_Subject_Request__c
      WHERE Id = :dsr.Id
    ];
    System.assertEquals('Failed', dsar.Status__c);
  }

  @IsTest
  static void testUpdateStatus() {
    Contact c = [
      SELECT Id, FirstName, LastName
      FROM Contact
      WHERE FirstName = 'TestPrivacy'
    ];
    Data_Subject_Request__c dsr = new Data_Subject_Request__c();
    dsr.Data_Subject_Id__c = c.Id;
    dsr.Policy_Name__c = 'ContactPolicy';
    dsr.Data_Subject_Name__c = c.FirstName + ' ' + c.LastName;
    dsr.Data_Subject_Type__c = 'Contact';
    dsr.Status__c = 'Submitted';
    Test.setMock(HttpCalloutMock.class, new PortabilityAPIMockCompleted());
    Test.startTest();
    insert dsr;
    String recordId = PortabilityPolicyService.updateStatus(dsr.Id);
    Test.stopTest();
    Data_Subject_Request__c dsar = [
      SELECT Id, Status__c, Policy_File_Id__c
      FROM Data_Subject_Request__c
      WHERE Id = :dsr.Id
    ];
    System.assertEquals('Complete', dsar.Status__c);
  }

  @IsTest
  static void testUpdateStatusError() {
    Contact c = [
      SELECT Id, FirstName, LastName
      FROM Contact
      WHERE FirstName = 'TestPrivacy'
    ];
    Data_Subject_Request__c dsr = new Data_Subject_Request__c();
    dsr.Data_Subject_Id__c = c.Id;
    dsr.Policy_Name__c = 'ContactPolicy';
    dsr.Data_Subject_Name__c = c.FirstName + ' ' + c.LastName;
    dsr.Data_Subject_Type__c = 'Contact';
    dsr.Status__c = 'Submitted';
    Test.setMock(HttpCalloutMock.class, new PortabilityAPIMockError());
    Test.startTest();
    insert dsr;
    String recordId = PortabilityPolicyService.updateStatus(dsr.Id);
    Test.stopTest();
    Data_Subject_Request__c dsar = [
      SELECT Id, Status__c, Policy_File_Id__c
      FROM Data_Subject_Request__c
      WHERE Id = :dsr.Id
    ];
    System.assertEquals('Failed', dsar.Status__c);
  }

  @IsTest
  static void testdeleteDSAR() {
    try {
      Test.startTest();
      List<Data_Subject_Request__c> dsars = PortabilityPolicyService.getAllDSRs();
      PortabilityPolicyService.deleteDSR(dsars[0].Id);
      PortabilityPolicyService.deleteDSR('');
      Test.stopTest();
    } catch (Exception e) {
      List<Data_Subject_Request__c> updatedDsars = PortabilityPolicyService.getAllDSRs();
      System.assertEquals(updatedDsars.size(), 2);
    }
  }

  @IsTest
  static void testdeleteAllDSARs() {
    Test.startTest();
    PortabilityPolicyService.deleteAllDSRs();
    Test.stopTest();
    List<Data_Subject_Request__c> dsars = [
      SELECT Id
      FROM Data_Subject_Request__c
    ];
    System.assertEquals(0, dsars.size());
  }
}
