// Financy - Official Landing Page JavaScript

// Configurable App Store Download URL (Random / Placeholder for iOS Store)
const APP_STORE_URL = "https://apps.apple.com/app/financy-smart-budgeting/id6478912345";

// Screen Data for Interactive Phone Mockup
const screensData = {
  budget: {
    src: "assets/images/screen_budget.png",
    title: "Real-Time Budget Burn & Concentric Gauges",
    description: "Visual circular gauge dynamically tracks daily safe spend, planned allowances, and month-end pace so you never run out of funds.",
    badge: "37% Used • On Track",
    badgeColor: "text-emerald-400 bg-emerald-500/10 border-emerald-500/20"
  },
  recurring: {
    src: "assets/images/screen_recurring.png",
    title: "Intelligent Subscription Radar",
    description: "Autodetect and track recurring memberships, SaaS tools, and rent. Receive proactive reminders 48 hours before auto-renewal charges.",
    badge: "Auto-Renew Alert",
    badgeColor: "text-amber-400 bg-amber-500/10 border-amber-500/20"
  },
  settings: {
    src: "assets/images/screen_settings.png",
    title: "Lifetime Premium & Native Preferences",
    description: "No recurring subscription fatigue. Enjoy full entitlement control, dark mode themes, biometric Face ID, and local currency support.",
    badge: "Lifetime Access",
    badgeColor: "text-indigo-400 bg-indigo-500/10 border-indigo-500/20"
  },
  auth: {
    src: "assets/images/screen_auth.png",
    title: "Zero-Trust Biometric & Social Auth",
    description: "One-tap native Apple Sign-In with private relay email support, Google OAuth, and secure backend token verification. No raw passwords stored.",
    badge: "Sign in with Apple",
    badgeColor: "text-sky-400 bg-sky-500/10 border-sky-500/20"
  }
};

document.addEventListener("DOMContentLoaded", () => {
  // Bind all App Store Buttons to APP_STORE_URL
  document.querySelectorAll(".app-store-link").forEach(btn => {
    btn.setAttribute("href", APP_STORE_URL);
    btn.setAttribute("target", "_blank");
    btn.setAttribute("rel", "noopener noreferrer");
  });

  // Setup Screen Switcher
  setupScreenSwitcher();

  // Setup Interactive Budget Calculator
  setupBudgetCalculator();

  // Setup FAQ Accordion
  setupFaqAccordion();

  // Setup QR Modal
  setupQrModal();

  // Setup Mobile Nav Toggle
  setupMobileNav();
});

// 1. Screen Switcher
function setupScreenSwitcher() {
  const tabs = document.querySelectorAll(".screen-tab");
  const phoneImg = document.getElementById("phone-mockup-img");
  const screenTitle = document.getElementById("screen-detail-title");
  const screenDesc = document.getElementById("screen-detail-desc");
  const screenBadge = document.getElementById("screen-detail-badge");

  if (!tabs.length || !phoneImg) return;

  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      const key = tab.getAttribute("data-screen");
      if (!screensData[key]) return;

      // Update active tab style
      tabs.forEach(t => t.classList.remove("active"));
      tab.classList.add("active");

      // Smooth fade transition on image
      phoneImg.style.opacity = "0.2";
      phoneImg.style.transform = "scale(0.97)";

      setTimeout(() => {
        phoneImg.src = screensData[key].src;
        phoneImg.style.opacity = "1";
        phoneImg.style.transform = "scale(1)";

        if (screenTitle) screenTitle.textContent = screensData[key].title;
        if (screenDesc) screenDesc.textContent = screensData[key].description;
        if (screenBadge) {
          screenBadge.textContent = screensData[key].badge;
          screenBadge.className = `px-3 py-1 rounded-full text-xs font-semibold border ${screensData[key].badgeColor}`;
        }
      }, 150);
    });
  });
}

// 2. Interactive Budget Burn Calculator
function setupBudgetCalculator() {
  const budgetInput = document.getElementById("calc-budget");
  const spentInput = document.getElementById("calc-spent");
  const budgetValDisplay = document.getElementById("calc-budget-val");
  const spentValDisplay = document.getElementById("calc-spent-val");

  const safeSpendDisplay = document.getElementById("calc-safe-spend");
  const remainingDisplay = document.getElementById("calc-remaining");
  const burnPaceDisplay = document.getElementById("calc-burn-pace");
  const paceStatusDisplay = document.getElementById("calc-pace-status");
  const progressBar = document.getElementById("calc-progress-bar");

  if (!budgetInput || !spentInput) return;

  function recalculate() {
    const budget = parseFloat(budgetInput.value) || 50000;
    const spent = parseFloat(spentInput.value) || 18500;
    const totalDays = 30;
    const currentDay = 8;
    const daysLeft = totalDays - currentDay;

    // Display formatted inputs
    budgetValDisplay.textContent = `₹ ${budget.toLocaleString("en-IN")}`;
    spentValDisplay.textContent = `₹ ${spent.toLocaleString("en-IN")}`;

    // Calculations
    const remaining = Math.max(0, budget - spent);
    const safeSpendDaily = Math.round(remaining / Math.max(1, daysLeft));
    const usagePercent = Math.min(100, Math.round((spent / budget) * 100));

    remainingDisplay.textContent = `₹ ${remaining.toLocaleString("en-IN")}`;
    safeSpendDisplay.textContent = `₹ ${safeSpendDaily.toLocaleString("en-IN")}/day`;
    burnPaceDisplay.textContent = `${usagePercent}%`;

    if (progressBar) {
      progressBar.style.width = `${usagePercent}%`;
    }

    // Status Pill
    if (usagePercent <= 40) {
      paceStatusDisplay.textContent = "Optimal Burn • Safe";
      paceStatusDisplay.className = "text-xs font-bold px-2.5 py-1 rounded-md bg-emerald-500/20 text-emerald-400 border border-emerald-500/30";
      if (progressBar) progressBar.className = "h-2.5 rounded-full bg-emerald-500 transition-all duration-300";
    } else if (usagePercent <= 75) {
      paceStatusDisplay.textContent = "Moderate Burn • Watch Pace";
      paceStatusDisplay.className = "text-xs font-bold px-2.5 py-1 rounded-md bg-amber-500/20 text-amber-400 border border-amber-500/30";
      if (progressBar) progressBar.className = "h-2.5 rounded-full bg-amber-500 transition-all duration-300";
    } else {
      paceStatusDisplay.textContent = "High Burn • Exceeding Target";
      paceStatusDisplay.className = "text-xs font-bold px-2.5 py-1 rounded-md bg-rose-500/20 text-rose-400 border border-rose-500/30";
      if (progressBar) progressBar.className = "h-2.5 rounded-full bg-rose-500 transition-all duration-300";
    }
  }

  budgetInput.addEventListener("input", recalculate);
  spentInput.addEventListener("input", recalculate);
  recalculate();
}

// 3. FAQ Accordion
function setupFaqAccordion() {
  const faqItems = document.querySelectorAll(".faq-item");
  faqItems.forEach(item => {
    const trigger = item.querySelector(".faq-trigger");
    const content = item.querySelector(".faq-content");
    const icon = item.querySelector(".faq-icon");

    if (!trigger || !content) return;

    trigger.addEventListener("click", () => {
      const isOpen = !content.classList.contains("hidden");

      // Close all
      document.querySelectorAll(".faq-content").forEach(c => c.classList.add("hidden"));
      document.querySelectorAll(".faq-icon").forEach(i => i.style.transform = "rotate(0deg)");

      if (!isOpen) {
        content.classList.remove("hidden");
        if (icon) icon.style.transform = "rotate(180deg)";
      }
    });
  });
}

// 4. QR Code Modal
function setupQrModal() {
  const qrTriggers = document.querySelectorAll(".open-qr-modal");
  const modal = document.getElementById("qr-modal");
  const closeModal = document.getElementById("close-qr-modal");
  const qrImg = document.getElementById("qr-code-img");

  if (!modal) return;

  // Use reliable QR generator service for APP_STORE_URL
  if (qrImg) {
    const encodedUrl = encodeURIComponent(APP_STORE_URL);
    qrImg.src = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodedUrl}&margin=10&color=059669`;
  }

  qrTriggers.forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      modal.classList.remove("hidden");
    });
  });

  if (closeModal) {
    closeModal.addEventListener("click", () => {
      modal.classList.add("hidden");
    });
  }

  modal.addEventListener("click", (e) => {
    if (e.target === modal) {
      modal.classList.add("hidden");
    }
  });
}

// 5. Mobile Nav Toggle
function setupMobileNav() {
  const toggle = document.getElementById("mobile-menu-btn");
  const menu = document.getElementById("mobile-menu");

  if (!toggle || !menu) return;

  toggle.addEventListener("click", () => {
    menu.classList.toggle("hidden");
  });

  // Close menu when clicking nav links
  menu.querySelectorAll("a").forEach(link => {
    link.addEventListener("click", () => {
      menu.classList.add("hidden");
    });
  });
}
