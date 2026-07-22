// app/javascript/controllers/comments_controller.js
// =========================================================================
// REAL-TIME COMMENTARY WORKSPACE INTERFACE CONTROLLER
// - Manages inline form transitions between view and edit layouts dynamically
// - Leverages structural event parameters to decouple DOM tracking lookups
// - Implements translation-safe attribute guards to isolate state changes
// =========================================================================
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // --- Action Event Endpoints ---

  // Swaps interface elements to reveal or conceal target comment edit forms
  toggleForm(event) {
    event.preventDefault();
    event.stopPropagation();

    // 1. Extract component target identifier handles
    const formId = event.params["form"];
    const bodyId = event.params["body"];
    const buttonId = event.params["edit"];

    const formElement   = document.getElementById(formId);
    const bodyElement   = document.getElementById(bodyId);
    const buttonElement = document.getElementById(buttonId);

    // Safety guard protecting against template execution crashes if nodes fail to load
    if (!formElement || !bodyElement || !buttonElement) return;

    // 2. Mutate visibility layouts using atomic display classes
    formElement.classList.toggle("d-none");
    bodyElement.classList.toggle("d-none");

    // 3. Dispatch the localized state adjustment thread to your button engine
    this.toggleEditButtonState(buttonElement);
  }

  private

  // TRANSLATION SAFE STATE ENGINE: Swaps classes and switches text values using dataset boundaries
  toggleEditButtonState(button) {
    // Read clean structural states from data-attributes instead of visible inner text strings
    const isEditing = button.getAttribute("data-comment-editing") === "true";

    if (isEditing) {
      // Revert back to view layout parameters
      button.setAttribute("data-comment-editing", "false");
      button.innerText = button.getAttribute("data-original-text") || "Edit";
    } else {
      // Advance forward into active edit state parameters
      button.setAttribute("data-comment-editing", "true");
      button.setAttribute("data-original-text", button.innerText);
      button.innerText = button.getAttribute("data-cancel-text") || "Cancel";
    }

    // Toggle button coloration themes safely
    button.classList.toggle("btn-secondary");
    button.classList.toggle("btn-warning");
  }
}