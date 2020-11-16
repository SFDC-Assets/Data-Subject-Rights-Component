import { LightningElement, api } from "lwc";

export default class ResultTile extends LightningElement {
  @api result;

  selectClick(event) {
    // Prevents the anchor element from navigating to a URL.
    event.preventDefault();

    // Creates the event with the contact ID data.
    const idSelectedEvent = new CustomEvent("idselected", {
      detail: { result: this.result }
    });

    // Dispatches the event.
    this.dispatchEvent(idSelectedEvent);
  }
}
