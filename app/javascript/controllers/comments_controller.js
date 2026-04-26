import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
  }

  // Toggle Edit Form visibility
  toggleForm(event) {
    event.preventDefault();
    event.stopPropagation();

    const formID = event.params["form"];
    const form = document.getElementById(formID)
    form.classList.toggle("d-none")
    form.classList.toggle("mt-5")

    const  commentBodyID = event.params["body"]
    const commentBody = document.getElementById(commentBodyID)
    commentBody.classList.toggle("d-none")

    const editButtonID = event.params["edit"];
    const editButton = document.getElementById(editButtonID)
    this.toggleEditButton(editButton);
  }

  // Toggle Text on Edit Button
  toggleEditButton(editButton) {
    if (editButton.innerText === "Edit") {
      editButton.innerText = "Cancel";
      this.toggleEditButtonClass(editButton);
    } else {
      editButton.innerText = "Edit";
      this.toggleEditButtonClass(editButton);
    }
  }

  // Toggle Edit Button colour
  toggleEditButtonClass(editButton) {
    editButton.classList.toggle("btn-secondary");
    editButton.classList.toggle("btn-warning");
  }
}
