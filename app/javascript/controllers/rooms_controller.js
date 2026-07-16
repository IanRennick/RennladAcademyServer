import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ✅ Declare a target so Stimulus finds your messages panel automatically
  static targets = [ "scrollable" ]

  connect() {
    // A fallback guard in case the target hasn't fully rendered on screen yet
    if (!this.hasScrollableTarget) return;

    // Initialize our configuration options for the DOM watcher engine
    const config = { childList: true, subtree: true };

    // ✅ FIX: Arrow function syntax ensures "this" binds permanently to your Stimulus controller context!
    const callback = (mutationList) => {
      for (const mutation of mutationList) {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          this.resetScroll();
        }
      }
    };

    this.observer = new MutationObserver(callback);
    this.observer.observe(this.scrollableTarget, config);

    // Glide down to the latest message immediately upon loading the room view
    this.resetScroll();
  }

  disconnect() {
    // Clean up memory maps by turning off the observer when leaving the page cavity
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  resetForm() {
    // If attached to your message creation form element, clears input boxes smoothly
    this.element.reset();
  }

  resetScroll() {
    // ✅ FIX: Uses your explicit Stimulus target reference variables cleanly!
    const target = this.scrollableTarget;
    target.scrollTop = target.scrollHeight - target.clientHeight;
  }
}