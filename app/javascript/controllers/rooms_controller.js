import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 1. Select the node to watch (e.g., body or a specific container)
    const messages = document.getElementById("messages");

    // 2. Options for the observer (what to watch)
    const config = { childList: true, subtree: true };

    // 3. Callback function to execute when mutations are observed
    const callback = (mutationList, observer) => {
      for (const mutation of mutationList) {
        if (mutation.type === 'childList') {
          mutation.addedNodes.forEach((node) => {
            // Ensure it's an element node (nodeType 1)
            if (node.nodeType === 1) {
              this.resetScroll(messages);
            }
          });
        }
      }
    };

    // 4. Create an observer instance linked to the callback function
    const observer = new MutationObserver(callback);

    // 5. Start observing the target node
    observer.observe(messages, config);

    // Reset Scroll when opened
    this.resetScroll(messages);
  }

  // Reset form after message is sent
  resetForm() {
    this.element.reset()
  }

  // Reset scroll so newest message is shown
  resetScroll() {
    console.log("HELLO")
    messages.scrollTop = messages.scrollHeight - messages.clientHeight;
  }
}