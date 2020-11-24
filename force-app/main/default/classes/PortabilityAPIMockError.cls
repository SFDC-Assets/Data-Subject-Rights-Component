global class PortabilityAPIMockError implements HttpCalloutMock {
  global HttpResponse respond(HttpRequest request) {
    HttpResponse response = new HttpResponse();
    response.setStatusCode(500);
    response.setHeader('Content-Type', 'application/json');
    response.setBody(
      '{"status" : "Failure","warnings" : [ ], "result" : { "policyFileStatus" : "Failed", "policyFileUrl" : "https://na45.stmfb.stm.salesforce.com/servlet/policyFileDownload?file=0jeS70000004CBO", "policyFileId" : "0jeS70000004CBO" } }'
    );
    return response;
  }
}
