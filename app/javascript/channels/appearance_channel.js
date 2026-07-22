// app/javascript/channels/appearance_channel.js
// =========================================================================
// - CLIENT-SIDE ACTIONCABLE PRESENCE TRACKING SUITE
// - Manages local user interaction listen arrays (online, away, offline)
// - Features an idle activity timeout monitor set to a strict 5-minute cap
// - Integrates state transition throttles to shield the server from spam
// =========================================================================
import consumer from "channels/consumer";

let idleTimer = null;
let currentClientState = "offline";
let appearanceSubscription = null;

// Clean wrapper isolating the subscription interface setup safely
const initializePresenceTracker = () => {
  if (appearanceSubscription) return; // Prevent building duplicate channel instances

  appearanceSubscription = consumer.subscriptions.create("AppearanceChannel", {
    connected() {
      console.log("Presence tracking websocket stream established safely.");
      
      this.stateTransitions = {
        online: () => { if (currentClientState !== "online") { this.perform("online"); currentClientState = "online"; } },
        away:   () => { if (currentClientState !== "away")   { this.perform("away");   currentClientState = "away"; } },
        offline:() => { if (currentClientState !== "offline") { this.perform("offline"); currentClientState = "offline"; } }
      };
      
      this.installListeners();
    },

    disconnected() {
      this.removeListeners();
    },

    received(data) {
      // SPA CAPABILITY HOOK: Future React apps tap straight into this raw JSON payload mapping
      console.log("Global Real-Time Presence Payload Received:", data);
    },

    installListeners() {
      this.boundReset = () => this.handleActivity();
      
      // Captured standard inputs alongside Hotwire turbo navigation load steps
      ["click", "keydown", "turbo:load", "mousemove"].forEach(eventName => {
        window.addEventListener(eventName, this.boundReset, { passive: true });
      });
      
      this.handleActivity();
    },

    removeListeners() {
      ["click", "keydown", "turbo:load", "mousemove"].forEach(eventName => {
        window.removeEventListener(eventName, this.boundReset);
      });
      clearTimeout(idleTimer);
      currentClientState = "offline";
    },

    handleActivity() {
      // GHOST PROTECTION SHIELD: If they exit the chat container, drop their connection to offline mode instantly
      const trackingAnchor = document.getElementById("appearance_channel");
      if (!trackingAnchor) {
        this.stateTransitions.offline();
        return;
      }

      this.stateTransitions.online();
      clearTimeout(idleTimer);

      // Trigger standard idle flag shifts if no movements occur for 5 consecutive minutes
      const idlePeriod = 5 * 60 * 1000; 
      idleTimer = setTimeout(() => {
        this.stateTransitions.away();
      }, idlePeriod);
    }
  });
};

// Automatic initialization hook wires up channels smoothly across standard Turbo load cycles
document.addEventListener("turbo:load", () => {
  const trackingAnchor = document.getElementById("appearance_channel");
  if (trackingAnchor) {
    initializePresenceTracker();
  } else if (appearanceSubscription) {
    // If the anchor disappears on a page swap, cleanly unsubscribe the active stream object
    appearanceSubscription.unsubscribe();
    appearanceSubscription = null;
  }
});