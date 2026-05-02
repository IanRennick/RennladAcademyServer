import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Method for showing correct question form
  openForm(event) {
    event.preventDefault();
    event.stopPropagation();

    const formID = event.params["form"];
    const form = document.getElementById(formID)
    form.classList.toggle("d-none")
    this.hideLinks(event)
  }

  // Hide links once a form has been opened
  hideLinks(event) {
    const linksID = event.params["links"];
    const links = document.getElementById(linksID)
    links.classList.toggle("d-none")
  }
}
