// app/javascript/controllers/rooms_controller.js
// =========================================================================
// REAL-TIME CHATROOM MUTATION OBSERVER CONTROLLER
// - Automatically glides chat windows down to capture incoming text packets
// - Leverages native MutationObserver engines to intercept async node updates
// - Clears memory maps and manages input form resets seamlessly
// =========================================================================
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Declare target parameters so the engine binds elements automatically
  static targets = [ "scrollable" ]

  // --- Stimulus Lifecycle Event Hooks ---

  connect() {
    // Structural Guard Shield: Abort early if the panel layout container is missing
    if (!this.hasScrollableTarget) return;

    // Initialize our configuration options for the DOM watcher engine
    const config = { childList: true, subtree: true };

    // permanent arrow mapping locks "this" cleanly to the active controller scope context
    const callback = (mutationList) => {
      for (const mutation of mutationList) {
        if (mutation.type === "childList" && mutation.addedNodes.length > 0) {
          // Pass true to enable smooth animated glides for real-time incoming posts
          this.resetScroll({ smooth: true });
        }
      }
    };

    this.observer = new MutationObserver(callback);
    this.observer.observe(this.scrollableTarget, config);

    // Instantly jump down to the base ceiling on initial load to hide previous logs
    this.resetScroll({ smooth: false });
  }

  disconnect() {
    // Turn off active observers to shield client browser memory channels from data leaks
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  // --- Action Endpoints ---

  // Clears out text areas and input boxes cleanly following form submission events
  resetForm() {
    this.element.reset();
  }

  // --- Utility State Engines ---

  // ADJUSTED SMOOTH GLIDE CORE: Automatically slides chat boxes down smoothly
  resetScroll(options = { smooth: false }) {
    const target = this.scrollableTarget;
    const targetTop = target.scrollHeight - target.clientHeight;

    if (options.smooth) {
      // Premium smooth glide execution transition option for active sessions
      target.scrollTo({
        top: targetTop,
        behavior: "smooth"
      });
    } else {
      // Instant hard jump baseline parameter for fresh page entries
      target.scrollTop = targetTop;
    }
  }
}