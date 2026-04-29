import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("HEY");
  }

  // Open Multiple Choice Form
  openMCForm(event) {
    event.preventDefault();
    event.stopPropagation();

    console.log("HO1");
    console.log(event.params["form"]);

    const formID = event.params["form"];
    const form = document.getElementById(formID)
    form.classList.toggle("d-none")
    this.hideLinks(event)
  }

  // Open open cloze Form
  openOCForm(event) {
    event.preventDefault();
    event.stopPropagation();

    console.log("HO2");

    const formID = event.params["form"];
    const form = document.getElementById(formID)
    form.classList.toggle("d-none")
    this.hideLinks(event)
  }

  // Open word formation Form
  openWFForm(event) {
    event.preventDefault();
    event.stopPropagation();

    console.log("HO3");

    const formID = event.params["form"];
    const form = document.getElementById(formID)
    form.classList.toggle("d-none")
    this.hideLinks(event)
  }

  // Open sentence close Form
  openSCForm(event) {
    event.preventDefault();
    event.stopPropagation();

    console.log("HO4");

    const formID = event.params["form"];
    const form = document.getElementById(formID)
    form.classList.toggle("d-none")
    this.hideLinks(event)
  }

  hideLinks(event) {
    const linksID = event.params["links"];
    const links = document.getElementById(linksID)
    links.classList.toggle("d-none")
  }
}
