import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
  }

  // Function for changing between normal comment body and the edit form
  toggleForm(event) {
    event.preventDefault();
    event.stopPropagation();

    // Toggle Edit Form visibility
    const formID = event.params["form"];
    const form = document.getElementById(formID)
    form.classList.toggle("d-none")
    form.classList.toggle("mt-5")

    // Toggle comment body visibility
    const  commentBodyID = event.params["body"]
    const commentBody = document.getElementById(commentBodyID)
    commentBody.classList.toggle("d-none")

    // Toggle Edit button text
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
