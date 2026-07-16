import consumer from "channels/consumer";

let idleTimer = null;
let currentClientState = "offline";

consumer.subscriptions.create("AppearanceChannel", {
  connected() {
    console.log("Presence tracker active.");
    this.stateTransitions = {
      online: () => { if (currentClientState !== "online") { this.perform("online"); currentClientState = "online"; } },
      away: () => { if (currentClientState !== "away") { this.perform("away"); currentClientState = "away"; } },
      offline: () => { if (currentClientState !== "offline") { this.perform("offline"); currentClientState = "offline"; } }
    };
    
    this.installListeners();
  },

  disconnected() {
    this.removeListeners();
  },

  received(data) {
    // ✅ REACT/API TRANSITION HOOK: 
    // When your future React app connects here, it reads this raw JSON payload 
    // to update state stores instantly, without relying on HTML partials!
    console.log("Global Status Change Received:", data);
  },

  installListeners() {
    this.boundReset = () => this.handleActivity();
    
    ["click", "keydown", "turbo:load", "mousemove"].forEach(eventName => {
      window.addEventListener(eventName, this.boundReset);
    });
    
    this.handleActivity();
  },

  removeListeners() {
    ["click", "keydown", "turbo:load", "mousemove"].forEach(eventName => {
      window.removeEventListener(eventName, this.boundReset);
    });
    clearTimeout(idleTimer);
  },

  handleActivity() {
    // ✅ DOM Check: Only track user states if viewing a page requiring presence
    const trackingAnchor = document.getElementById("appearance_channel");
    if (!trackingAnchor) {
      this.stateTransitions.offline();
      return;
    }

    this.stateTransitions.online();
    clearTimeout(idleTimer);

    // Set idle timeout length (e.g., 5 minutes = 300000 ms)
    const idlePeriod = 5 * 60 * 1000; 
    idleTimer = setTimeout(() => {
      this.stateTransitions.away();
    }, idlePeriod);
  }
});