// app/javascript/controllers/questions_controller.js
// =========================================================================
// BACKEND CURRICULUM MANAGEMENT CREATION SYSTEM STIMULUS CONTROLLER
// - Toggles specialized entry form layouts for polymorphic question variants
// - Handles single-instance workspace state resets by clearing visibility loops
// - Enforces strict DOM node safety guards to protect against console crashes
// =========================================================================
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // --- Action Event Endpoints ---

  // Reveals the targeted creation form and hides the base routing choice links
  openForm(event) {
    event.preventDefault();
    event.stopPropagation();

    // 1. Extract dynamic target identifier handles
    const formId = event.params["form"];
    const formElement = document.getElementById(formId);

    // SAFETY SHIELD: Enforce a guard clause to protect against console crashes if elements fail to map
    if (!formElement) {
      console.warn(`Questions Controller Error: Form element with ID '${formId}' could not be located.`);
      return;
    }

    // 2. Clear visibility layouts to bring the form panel into focus
    formElement.classList.toggle("d-none");
    
    // 3. Dispatch internal sequence loop to hide selection tags
    this.#hideSelectionLinks(event);
  }

  // --- Private Utility Methods ---

  // Conceals the base selection list row container when an active form path launches
  #hideSelectionLinks(event) {
    const linksId = event.params["links"];
    const linksElement = document.getElementById(linksId);

    // SAFETY SHIELD: Enforce a guard clause to protect against unmapped layout link nodes
    if (!linksElement) {
      console.warn(`Questions Controller Error: Navigation panel element with ID '${linksId}' could not be located.`);
      return;
    }

    linksElement.classList.toggle("d-none");
  }
}