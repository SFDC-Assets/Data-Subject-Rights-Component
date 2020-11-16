import { LightningElement, wire, track } from "lwc";
import getAllDSRs from "@salesforce/apex/PortabilityPolicyService.getAllDSRs";
import DSRMC from "@salesforce/messageChannel/DSRMessageChannel__c";
import { refreshApex } from "@salesforce/apex";
import {
  subscribe,
  MessageContext,
  APPLICATION_SCOPE
} from "lightning/messageService";
const COLS = [
  { label: "Request #", fieldName: "Name", editable: false },
  {
    label: "Subject Name",
    fieldName: "Data_Subject_Name__c",
    editable: false,
    sortable: true
  },
  {
    label: " Subject Type",
    fieldName: "Data_Subject_Type__c",
    editable: false,
    sortable: true
  },
  { label: "Status", fieldName: "Status__c", editable: false, sortable: true },

  {
    label: "Policy Name",
    fieldName: "Policy_Name__c",
    editable: false,
    sortable: true
  },
  {
    label: "Policy File URL",
    fieldName: "Policy_File_URL__c",
    type: "url",
    editable: false,
    sortable: true
  },
  {
    type: "button",
    typeAttributes: {
      iconName: "action:refresh",
      name: "View",
      title: "View",
      disabled: false,
      value: "view",
      iconPosition: "left"
    }
  }
];
export default class DsrList extends LightningElement {
  requests;
  error;

  recordId;
  get columns() {
    return COLS;
  }

  // wired message context
  @wire(MessageContext)
  messageContext;

  @track requests;

  refresh() {
    getAllDSRs()
      .then((result) => {
        this.requests = result;
        return this.requests;
      })
      .catch((error) => {
        this.error = error;
      });
  }
  subscribeMC() {
    console.log("Inside Subscription");
    this.subscription = subscribe(
      this.messageContext,
      DSRMC,
      (message) => {
        console.log("Received Message" + message.toString());
        this.refresh(message);
      },
      { scope: APPLICATION_SCOPE }
    );
  }
  // Runs when component is connected, subscribes to BoatMC
  connectedCallback() {
    // recordId is populated on Record Pages, and this component
    // should not update when this component is on a record page.
    if (this.subscription || this.recordId) {
      return;
    }
    // Subscribe to the message channel to retrieve the recordID and assign it to boatId.
    this.subscribeMC();

    getAllDSRs()
      .then((result) => {
        this.requests = result;
      })
      .catch((error) => {
        this.error = error;
      });
  }
}
