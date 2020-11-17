import { LightningElement, wire } from "lwc";
import getAllDSRs from "@salesforce/apex/PortabilityPolicyService.getAllDSRs";
import deleteAllDSRs from "@salesforce/apex/PortabilityPolicyService.deleteAllDSRs";
import deleteDSR from "@salesforce/apex/PortabilityPolicyService.deleteDSR";
import DSRMC from "@salesforce/messageChannel/DSRMessageChannel__c";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import {
  subscribe,
  MessageContext,
  APPLICATION_SCOPE
} from "lightning/messageService";
const VARIANT_OPTIONS = {
  error: "error",
  success: "success"
};
const COLS = [
  { label: "Request #", fieldName: "Name", editable: false },
  {
    label: "Subject Name",
    fieldName: "Data_Subject_Name__c",
    editable: false,
    sortable: false
  },
  {
    label: " Subject Type",
    fieldName: "Data_Subject_Type__c",
    editable: false,
    sortable: false
  },
  { label: "Status", fieldName: "Status__c", editable: false, sortable: true },

  {
    label: "Policy Name",
    fieldName: "Policy_Name__c",
    editable: false,
    sortable: false
  },
  {
    label: "Policy File URL",
    fieldName: "Policy_File_URL__c",
    type: "url",
    editable: false,
    sortable: false
  },
  {
    type: "action",
    typeAttributes: {
      rowActions: [{ label: "Delete", name: "delete" }],
      menuAlignment: "auto"
    }
  },
  {
    type: "button",
    typeAttributes: {
      iconName: "action:refresh",
      name: "refresh",
      title: "refresh",
      disabled: false,
      value: "refresh",
      iconPosition: "center"
    }
  }
];
export default class DsrList extends LightningElement {
  //requests;
  error;

  isLoading = false;
  recordId;

  hasRecords = false;
  get columns() {
    return COLS;
  }
  get recordsAvailable() {
    console.log(this.requests);
    return this.hasRecords;
  }
  // wired message context
  @wire(MessageContext)
  messageContext;

  @wire(getAllDSRs)
  wiredRequests(result) {
    this.isLoading = true;
    this.requests = result;
    if (this.requests.data) {
      if (this.requests.data.length > 0) {
        this.hasRecords = true;
      }
      this.isLoading = false;
    } else if (this.requests.error) {
      this.hasRecords = false;
      this.isLoading = false;
      const evt = new ShowToastEvent({
        title: "Error Loading Data",
        message: "Please check console for error message",
        variant: VARIANT_OPTIONS.error
      });
      this.dispatchEvent(evt);
    }
  }

  subscription;

  async refresh() {
    this.isLoading = true;
    try {
      await refreshApex(this.requests);
      this.isLoading = false;
    } catch (error) {
      this.error = error;
      this.isLoading = false;
      const evt = new ShowToastEvent({
        title: "Error Loading Data",
        message: "Please check console for error message",
        variant: VARIANT_OPTIONS.error
      });
      this.dispatchEvent(evt);
    }
  }
  subscribeMC() {
    this.subscription = subscribe(
      this.messageContext,
      DSRMC,
      (message) => {
        this.isLoading = true;
        this.refresh(message);
      },
      { scope: APPLICATION_SCOPE }
    );
  }
  // Runs when component is connected, subscribes to BoatMC
  connectedCallback() {
    this.isLoading = true;
    if (this.subscription || this.recordId) {
      return;
    }
    this.subscribeMC();
  }

  refreshRecord(event) {
    const recId = event.detail.row.Id;
    const actionName = event.detail.action.name;
    if (actionName === "refresh") {
      // eslint-disable-next-line no-alert
      alert(recId);
    } else if (actionName === "delete") {
      deleteDSR({ recordId: recId })
        .then(() => {
          this.refresh();
          this.isLoading = false;
          this.hasRecords = false;
          const evt = new ShowToastEvent({
            title: "Success",
            message: "Request Deleted!",
            variant: VARIANT_OPTIONS.success
          });
          this.dispatchEvent(evt);
        })
        .catch((error) => {
          this.error = error;
          this.isLoading = false;
          console.log(this.error);
          const evt = new ShowToastEvent({
            title: "Error in Processing",
            message: "Please check console for error message",
            variant: VARIANT_OPTIONS.error
          });
          this.dispatchEvent(evt);
        });
    }
  }

  deleteAll() {
    this.isLoading = true;
    deleteAllDSRs()
      .then(() => {
        this.refresh();
        this.isLoading = false;
        this.hasRecords = false;
        const evt = new ShowToastEvent({
          title: "Success",
          message: "All Requests deleted!",
          variant: VARIANT_OPTIONS.success
        });
        this.dispatchEvent(evt);
      })
      .catch((error) => {
        this.error = error;
        this.isLoading = false;
        console.log(this.error);
        const evt = new ShowToastEvent({
          title: "Error in Processing",
          message: "Please check console for error message",
          variant: VARIANT_OPTIONS.error
        });
        this.dispatchEvent(evt);
      });
  }
}
