import { LightningElement, wire } from "lwc";
import getAllDSRs from "@salesforce/apex/PortabilityPolicyService.getAllDSRs";
import deleteAllDSRs from "@salesforce/apex/PortabilityPolicyService.deleteAllDSRs";
import deleteDSR from "@salesforce/apex/PortabilityPolicyService.deleteDSR";
import updateStatus from "@salesforce/apex/PortabilityPolicyService.updateStatus";
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
  success: "success",
  info: "info"
};
const APEX_ERROR_TITLE = "Error Loading Data";
const APEX_ERROR_MESSAGE = "Please check console for error message";

const DATA_REFRESH_TITLE = "Data Updated";
const DATA_REFRESH_MESSAGE = "One or more records have received updates!";

const SUCCESS_TITLE = "Success!";

const DELETE_ALL_MESSAGE = "All Requests deleted!";
const DELETE_MESSAGE = "Request Deleted!";

const UPDATE_MESSAGE = "Update Request Submitted!";

const COLS = [
  {
    label: "Request #",
    fieldName: "Name",
    editable: false,
    hideDefaultActions: true,
    sortable: false
  },
  {
    label: "Subject Name",
    fieldName: "Data_Subject_Name__c",
    editable: false,
    sortable: false,
    hideDefaultActions: true
  },
  {
    label: " Subject Type",
    fieldName: "Data_Subject_Type__c",
    editable: false,
    sortable: false,
    hideDefaultActions: true
  },
  {
    label: "Status",
    fieldName: "Status__c",
    editable: false,
    sortable: true,
    hideDefaultActions: true
  },

  {
    label: "Policy Name",
    fieldName: "Policy_Name__c",
    editable: false,
    sortable: false,
    hideDefaultActions: true
  },
  {
    label: "Policy File URL",
    fieldName: "Policy_File_URL__c",
    type: "url",
    typeAttributes: {
      target: "_blank"
    },
    editable: false,
    sortable: false,
    hideDefaultActions: true
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

  refreshStates;
  isLoading = false;
  recordId;

  hasRecords = false;
  get columns() {
    return COLS;
  }
  get recordsAvailable() {
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
        title: APEX_ERROR_TITLE,
        message: APEX_ERROR_MESSAGE,
        variant: VARIANT_OPTIONS.error
      });
      this.dispatchEvent(evt);
    }
  }

  subscription;

  async refresh(showMessage) {
    this.isLoading = true;
    try {
      await refreshApex(this.requests);
      this.isLoading = false;
      if (showMessage) {
        const evt = new ShowToastEvent({
          title: DATA_REFRESH_TITLE,
          message: DATA_REFRESH_MESSAGE,
          variant: VARIANT_OPTIONS.info
        });
        this.dispatchEvent(evt);
      }
    } catch (error) {
      this.error = error;
      this.isLoading = false;
      const evt = new ShowToastEvent({
        title: APEX_ERROR_TITLE,
        message: APEX_ERROR_MESSAGE,
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
        this.refresh(true);
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

  handleRowActions(event) {
    const recId = event.detail.row.Id;
    const actionName = event.detail.action.name;
    if (actionName === "refresh") {
      this.updateStatus(recId, event);
    } else if (actionName === "delete") {
      deleteDSR({ recordId: recId })
        .then(() => {
          this.refresh(false);
          this.isLoading = false;
          this.hasRecords = false;
          const evt = new ShowToastEvent({
            title: SUCCESS_TITLE,
            message: DELETE_MESSAGE,
            variant: VARIANT_OPTIONS.success
          });
          this.dispatchEvent(evt);
        })
        .catch((error) => {
          this.error = error;
          this.isLoading = false;
          console.log(this.error);
          const evt = new ShowToastEvent({
            title: APEX_ERROR_TITLE,
            message: APEX_ERROR_MESSAGE,
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
        this.refresh(false);
        this.isLoading = false;
        this.hasRecords = false;
        const evt = new ShowToastEvent({
          title: SUCCESS_TITLE,
          message: DELETE_ALL_MESSAGE,
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

  updateStatus(recordId, event) {
    this.isLoading = true;
    updateStatus({
      recordId
    })
      .then((result) => {
        this.error = undefined;
        this.isLoading = false;
        const evt = new ShowToastEvent({
          title: SUCCESS_TITLE,
          message: UPDATE_MESSAGE,
          variant: VARIANT_OPTIONS.success
        });
        this.dispatchEvent(evt);
      })
      .catch((error) => {
        this.error = error;
        console.log(this.error);
        const evt = new ShowToastEvent({
          title: APEX_ERROR_TITLE,
          message: APEX_ERROR_MESSAGE,
          variant: VARIANT_OPTIONS.error
        });
        this.dispatchEvent(evt);
      });
  }
}
