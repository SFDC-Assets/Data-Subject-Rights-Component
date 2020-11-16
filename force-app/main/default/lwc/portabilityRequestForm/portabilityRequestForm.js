import { LightningElement, wire, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { MessageContext, publish } from "lightning/messageService";
import getPolicyDetails from "@salesforce/apex/PortabilityPolicyService.getPolicyDetails";
import createDSR from "@salesforce/apex/PortabilityPolicyService.createDSR";
import DSRMC from "@salesforce/messageChannel/DSRMessageChannel__c";
const OBJECT_OPTIONS = [
  { label: "Account", value: "Account" },
  { label: "Contact", value: "Contact" },
  { label: "User", value: "User" },
  { label: "Lead", value: "Lead" },
  { label: "Individual", value: "Individual" }
];
const ICONS = {
  Account: "standard:account",
  Lead: "standard:lead",
  Contact: "standard:contact",
  User: "standard:user",
  Individual: "standard:individual"
};
const DSR_SUCCESS_TITLE = "Success! DSR Request Sent";
const DSR_SUCCESS_MESSAGE =
  "Check the DSR Record in some time to check file generation status.";
const APEX_ERROR_MESSAGE =
  "There was a problem processing your request. Please try again.";
const APEX_ERROR_TITLE = "Error: Request Not Sent";
const VARIANT_OPTIONS = {
  error: "error",
  success: "success"
};

export default class PorabilityRequestForm extends LightningElement {
  selectedPolicyName;
  selectedObjectType;
  selectedRecordId;
  selectedRecordName;

  selectedIcon;
  error;
  @track policyOptions;

  @wire(MessageContext)
  messageContext;

  @wire(getPolicyDetails)
  wiredPolicies({ data, error }) {
    if (data) {
      this.policyOptions = data.map((policy) => {
        return { label: policy.DeveloperName, value: policy.DeveloperName };
      });
    } else if (error) {
      this.policyOptions = undefined;
      this.error = error;
      console.log(error.body);
    }
  }

  get objectOptions() {
    return OBJECT_OPTIONS;
  }
  handlePolicyOptionChange(event) {
    this.selectedPolicyName = event.target.value;
  }

  handleObjectTypeChange(event) {
    this.selectedObjectType = event.target.value;
    this.selectedIcon = ICONS[this.selectedObjectType];
  }

  onRecordSelection(event) {
    this.selectedRecordName = event.detail.selectedValue;
    this.selectedRecordId = event.detail.selectedRecordId;
  }

  sendRequest() {
    createDSR({
      dataSubjectId: this.selectedRecordId,
      policyName: this.selectedPolicyName,
      selectedObjectName: this.selectedObjectType,
      subjectName: this.selectedRecordName
    })
      .then((result) => {
        console.log(result);
        this.error = undefined;
        this.selectedRecordId = undefined;
        this.selectedRecordName = undefined;
        this.querySelector();
        publish(this.messageContext, DSRMC, { msg: "New DSR Created" });
        const evt = new ShowToastEvent({
          title: DSR_SUCCESS_TITLE,
          message: DSR_SUCCESS_MESSAGE,
          variant: VARIANT_OPTIONS.success
        });
        this.dispatchEvent(evt);
        this.resetComponent();
      })
      .catch((error) => {
        this.error = error;
        this.selectedRecordId = undefined;
        this.selectedRecordName = undefined;
        const evt = new ShowToastEvent({
          title: APEX_ERROR_TITLE,
          message: APEX_ERROR_MESSAGE,
          variant: VARIANT_OPTIONS.error
        });
        this.dispatchEvent(evt);
        this.resetComponent();
      });
  }

  resetComponent() {
    this.selectedPolicyName = null;
    this.selectedObjectType = null;
    this.selectedRecordId = null;
    this.selectedRecordName = null;
    this.selectedIcon = null;
  }
}
