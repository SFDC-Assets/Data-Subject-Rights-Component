import { LightningElement, track, api } from "lwc";
import findRecords from "@salesforce/apex/PortabilityPolicyService.searchObjects";
export default class ObjectLookUp extends LightningElement {
  @track recordsList;
  searchKey = "";
  @api selectedValue;
  @api selectedRecordId;
  objectApiName;
  @api iconName;
  @api lookupLabel;
  message;

  onLeave(event) {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      this.searchKey = "";
      this.recordsList = null;
    }, 300);
  }

  onRecordSelection(event) {
    this.selectedRecordId = event.target.dataset.key;
    this.selectedValue = event.target.dataset.name;
    this.searchKey = "";
    this.onSeletedRecordUpdate();
  }

  handleKeyChange(event) {
    const searchKey = event.target.value;
    this.searchKey = searchKey;
    this.getLookupResult();
  }

  removeRecordOnLookup(event) {
    this.searchKey = "";
    this.selectedValue = null;
    this.selectedRecordId = null;
    this.recordsList = null;
    this.onSeletedRecordUpdate();
  }

  getLookupResult() {
    findRecords({
      searchKey: this.searchKey,
      objectType: this.objectApiName
    })
      .then((result) => {
        if (result.length === 0) {
          this.recordsList = [];
          this.message = "No Records Found";
        } else {
          this.recordsList = result;
          this.message = "";
        }
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        this.recordsList = undefined;
      });
  }

  @api
  get objectName() {
    return this.objectApiName;
  }

  set objectName(name) {
    this.objectApiName = name;
    this.removeRecordOnLookup();
  }
  onSeletedRecordUpdate() {
    const passEventr = new CustomEvent("recordselection", {
      detail: {
        selectedRecordId: this.selectedRecordId,
        selectedValue: this.selectedValue
      }
    });
    this.dispatchEvent(passEventr);
  }
}
