// Financy - Official Landing Page JavaScript (Hyper-Interactive Edition)

// Configurable App Store Download URL (Random / Placeholder for iOS Store)
const APP_STORE_URL = "https://apps.apple.com/app/financy-smart-budgeting/id6478912345";

// Screen Data for Interactive Phone Mockup
const screensData = {
  home: {
    src: "assets/images/screen_home.png",
    title: "Consolidated Wealth & Real-Time Balance",
    description: "View total net worth, active accounts, recent transactions, and monthly burn velocity in one unified, glanceable dashboard.",
    badge: "Dashboard Overview",
    badgeColor: "text-emerald-400 bg-emerald-500/10 border-emerald-500/20"
  },
  transactions: {
    src: "assets/images/screen_transactions.png",
    title: "Zero-Latency Transaction Ledger",
    description: "Search, filter, and drill into transactions by category, payment method, or date with instant search and merchant recognition.",
    badge: "Smart Ledger",
    badgeColor: "text-sky-400 bg-sky-500/10 border-sky-500/20"
  },
  budget: {
    src: "assets/images/screen_budget.png",
    title: "Concentric Circular Burn Gauges",
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

// Web Audio API Synthesizer for Subtle Haptic Sound Effects
let audioCtx = null;
let soundEnabled = true;

function playHapticSound(type = "click") {
  if (!soundEnabled) return;
  try {
    if (!audioCtx) {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioCtx.state === "suspended") {
      audioCtx.resume();
    }

    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.connect(gain);
    gain.connect(audioCtx.destination);

    const now = audioCtx.currentTime;

    if (type === "click") {
      osc.type = "sine";
      osc.frequency.setValueAtTime(800, now);
      osc.frequency.exponentialRampToValueAtTime(400, now + 0.04);
      gain.gain.setValueAtTime(0.08, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
      osc.start(now);
      osc.stop(now + 0.04);
    } else if (type === "splash") {
      osc.type = "triangle";
      osc.frequency.setValueAtTime(320, now);
      osc.frequency.exponentialRampToValueAtTime(640, now + 0.18);
      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
      osc.start(now);
      osc.stop(now + 0.25);
    } else if (type === "success") {
      osc.type = "sine";
      osc.frequency.setValueAtTime(523.25, now); // C5
      osc.frequency.setValueAtTime(659.25, now + 0.08); // E5
      gain.gain.setValueAtTime(0.09, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      osc.start(now);
      osc.stop(now + 0.2);
    }
  } catch (e) {
    // Audio context silently fails gracefully
  }
}

document.addEventListener("DOMContentLoaded", () => {
  // Bind all App Store Buttons to APP_STORE_URL
  document.querySelectorAll(".app-store-link").forEach(btn => {
    btn.setAttribute("href", APP_STORE_URL);
    btn.setAttribute("target", "_blank");
    btn.setAttribute("rel", "noopener noreferrer");
  });

  // Setup Sound Toggle
  setupSoundToggle();

  // Setup Theme Switcher (Light / Dark)
  setupThemeToggle();

  // Setup Interactive Phone Simulator & Controls
  setupPhoneSimulator();

  // Setup Screen Switcher
  setupScreenSwitcher();

  // Setup Interactive Budget Calculator
  setupBudgetCalculator();

  // Setup AI Auto-Categorizer Playground
  setupAiCategorizerPlayground();

  // Setup Subscription Drain Calculator
  setupSubscriptionDrain();

  // Setup Multi-Currency Net Worth Switcher
  setupCurrencySwitcher();

  // Setup Lifetime ROI Calculator
  setupLifetimeRoiCalculator();

  // Setup FAQ Accordion
  setupFaqAccordion();

  // Setup QR Modal
  setupQrModal();

  // Setup Mobile Nav Toggle
  setupMobileNav();
});

// 1. Sound Toggle
function setupSoundToggle() {
  const soundBtn = document.getElementById("sound-toggle-btn");
  if (!soundBtn) return;

  soundBtn.addEventListener("click", () => {
    soundEnabled = !soundEnabled;
    soundBtn.innerHTML = soundEnabled 
      ? '<i data-lucide="volume-2" class="w-4 h-4 text-emerald-400"></i><span class="hidden sm:inline">Audio On</span>'
      : '<i data-lucide="volume-x" class="w-4 h-4 text-slate-400"></i><span class="hidden sm:inline">Audio Off</span>';
    if (window.lucide) lucide.createIcons();
    if (soundEnabled) playHapticSound("click");
  });
}

// 2. Theme Toggle
function setupThemeToggle() {
  const themeBtn = document.getElementById("theme-toggle-btn");
  if (!themeBtn) return;

  const urlParams = new URLSearchParams(window.location.search);
  const currentTheme = urlParams.get("theme") || localStorage.getItem("financy-theme") || "dark";
  
  function applyTheme(isLight) {
    if (isLight) {
      document.documentElement.classList.add("light");
      themeBtn.innerHTML = `<i data-lucide="moon" class="w-4 h-4 text-indigo-500"></i>`;
      themeBtn.setAttribute("title", "Switch to Dark Theme");
    } else {
      document.documentElement.classList.remove("light");
      themeBtn.innerHTML = `<i data-lucide="sun" class="w-4 h-4 text-amber-400"></i>`;
      themeBtn.setAttribute("title", "Switch to Light Theme");
    }
    if (window.lucide) window.lucide.createIcons();
  }

  const initialLight = currentTheme === "light";
  applyTheme(initialLight);
  localStorage.setItem("financy-theme", initialLight ? "light" : "dark");

  themeBtn.addEventListener("click", () => {
    playHapticSound("click");
    const isNowLight = !document.documentElement.classList.contains("light");
    applyTheme(isNowLight);
    localStorage.setItem("financy-theme", isNowLight ? "light" : "dark");
  });
}

// 3. Interactive Phone Simulator & Controls
function setupPhoneSimulator() {
  const phoneImgs = document.querySelectorAll(".phone-mockup-img, #phone-mockup-img");
  const splashOverlays = document.querySelectorAll(".phone-splash-overlay, #phone-splash-overlay");
  const splashFills = document.querySelectorAll(".splash-progress-fill, #splash-progress-fill");
  const splashTriggers = document.querySelectorAll(".trigger-splash-btn, #trigger-splash-btn");

  const dynamicIslands = document.querySelectorAll(".dynamic-island, #dynamic-island");
  const addTxTriggers = document.querySelectorAll(".trigger-add-tx-btn, #trigger-add-tx-btn");
  const txSheets = document.querySelectorAll(".phone-tx-sheet, #phone-tx-sheet");
  const closeTxSheets = document.querySelectorAll(".close-tx-sheet, #close-tx-sheet");
  const submitTxBtns = document.querySelectorAll(".submit-tx-btn, #submit-tx-btn");

  // Bottom Nav inside Phone
  const phoneTabs = document.querySelectorAll(".phone-tab-btn");

  // A. Splash Screen Replay
  function runSplashScreen() {
    playHapticSound("splash");
    if (!splashOverlays.length) return;

    splashOverlays.forEach(overlay => overlay.classList.add("active"));
    splashFills.forEach(fill => { fill.style.width = "0%"; });

    setTimeout(() => {
      splashFills.forEach(fill => { fill.style.width = "100%"; });
    }, 50);

    setTimeout(() => {
      splashOverlays.forEach(overlay => overlay.classList.remove("active"));
      playHapticSound("success");
      // Show budget or home screen
      switchScreen("budget");
    }, 1700);
  }

  splashTriggers.forEach(btn => {
    btn.addEventListener("click", runSplashScreen);
  });

  // B. Clickable Dynamic Island
  dynamicIslands.forEach(island => {
    island.addEventListener("click", () => {
      playHapticSound("click");
      island.classList.toggle("expanded");
      if (island.classList.contains("expanded")) {
        setTimeout(() => {
          island.classList.remove("expanded");
        }, 4000);
      }
    });
  });

  // C. Interactive Add Transaction Sheet
  addTxTriggers.forEach(trigger => {
    trigger.addEventListener("click", () => {
      playHapticSound("click");
      txSheets.forEach(sheet => {
        sheet.classList.toggle("active");
      });
    });
  });

  closeTxSheets.forEach(btn => {
    btn.addEventListener("click", () => {
      txSheets.forEach(sheet => {
        sheet.classList.remove("active");
      });
    });
  });

  submitTxBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      playHapticSound("success");
      submitTxBtns.forEach(b => {
        b.textContent = "✓ Logged to Ledger!";
        b.classList.remove("bg-emerald-500");
        b.classList.add("bg-emerald-400");
      });

      setTimeout(() => {
        txSheets.forEach(sheet => {
          sheet.classList.remove("active");
        });
        submitTxBtns.forEach(b => {
          b.textContent = "Log Transaction";
          b.classList.add("bg-emerald-500");
          b.classList.remove("bg-emerald-400");
        });
        switchScreen("budget");
      }, 700);
    });
  });

  // Presets in Tx Sheet
  document.querySelectorAll(".tx-preset-chip").forEach(chip => {
    chip.addEventListener("click", () => {
      playHapticSound("click");
      const amt = chip.getAttribute("data-amount");
      document.querySelectorAll(".tx-amount-input, #tx-amount-input").forEach(input => {
        input.value = amt;
      });
    });
  });

  // D. Phone Bottom Tabs
  phoneTabs.forEach(tab => {
    tab.addEventListener("click", () => {
      const screenKey = tab.getAttribute("data-screen");
      switchScreen(screenKey);
    });
  });
}

// 4. Universal Screen Switcher
function switchScreen(key) {
  playHapticSound("click");
  const phoneImgs = document.querySelectorAll(".phone-mockup-img, #phone-mockup-img");
  const screenTitle = document.getElementById("screen-detail-title");
  const screenDesc = document.getElementById("screen-detail-desc");
  const screenBadge = document.getElementById("screen-detail-badge");
  const externalTabs = document.querySelectorAll(".screen-tab");
  const phoneTabs = document.querySelectorAll(".phone-tab-btn");

  if (!screensData[key] || !phoneImgs.length) return;

  // Sync external tab buttons
  externalTabs.forEach(t => {
    if (t.getAttribute("data-screen") === key) {
      t.classList.add("active");
    } else {
      t.classList.remove("active");
    }
  });

  // Sync internal phone tabs
  phoneTabs.forEach(t => {
    if (t.getAttribute("data-screen") === key) {
      t.classList.add("active");
    } else {
      t.classList.remove("active");
    }
  });

  // Smooth fade transition on all phone images
  phoneImgs.forEach(img => {
    img.style.opacity = "0.2";
    img.style.transform = "scale(0.97)";
  });

  setTimeout(() => {
    phoneImgs.forEach(img => {
      img.src = screensData[key].src;
      img.style.opacity = "1";
      img.style.transform = "scale(1)";
    });

    if (screenTitle) screenTitle.textContent = screensData[key].title;
    if (screenDesc) screenDesc.textContent = screensData[key].description;
    if (screenBadge) {
      screenBadge.textContent = screensData[key].badge;
      screenBadge.className = `px-3 py-1 rounded-full text-xs font-semibold border ${screensData[key].badgeColor} no-wrap`;
    }
  }, 120);
}

function setupScreenSwitcher() {
  const tabs = document.querySelectorAll(".screen-tab");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      const key = tab.getAttribute("data-screen");
      switchScreen(key);
    });
  });
}

// 5. Interactive Budget Burn Calculator
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

  budgetInput.addEventListener("input", () => {
    playHapticSound("click");
    recalculate();
  });
  spentInput.addEventListener("input", () => {
    playHapticSound("click");
    recalculate();
  });
  recalculate();
}

// 6. AI Smart Categorization & Expense Parser Playground
function setupAiCategorizerPlayground() {
  const input = document.getElementById("ai-expense-input");
  const chips = document.querySelectorAll(".ai-sample-chip");

  const catIcon = document.getElementById("ai-result-icon");
  const catName = document.getElementById("ai-result-category");
  const catAmount = document.getElementById("ai-result-amount");
  const catAccount = document.getElementById("ai-result-account");
  const catImpact = document.getElementById("ai-result-impact");

  if (!input) return;

  const sampleRules = [
    { match: /starbucks|coffee|latte|cafe/i, cat: "Dining & Coffee", icon: "coffee", acc: "HDFC Debit Card", impact: "-₹350 from Daily Safe Spend" },
    { match: /uber|ola|cab|flight|airline|fuel|petrol/i, cat: "Travel & Transport", icon: "car", acc: "Apple Pay (ICICI)", impact: "-₹850 from Daily Safe Spend" },
    { match: /netflix|spotify|chatgpt|amazon prime|youtube/i, cat: "Subscriptions & SaaS", icon: "repeat", acc: "Auto-Debit Bank Mandate", impact: "Tracked in Subscription Radar" },
    { match: /groceries|grocery|supermarket|spencer|nature/i, cat: "Groceries & Household", icon: "shopping-cart", acc: "SBI Checking", impact: "-₹3,200 (Within 50k Limit)" },
    { match: /salary|bonus|freelance|client/i, cat: "Income & Earnings", icon: "arrow-down-left", acc: "Primary Salary Account", impact: "+₹1,20,000 Surplus Added" }
  ];

  function parseExpense(text) {
    if (!text.trim()) return;

    // Extract amount if present
    const amtMatch = text.match(/₹?\s?(\d+[\d,]*)/);
    const amt = amtMatch ? `₹ ${amtMatch[1]}` : "₹ 450";

    let found = sampleRules.find(r => r.match.test(text));
    if (!found) {
      found = { cat: "General Expense", icon: "tag", acc: "Primary Account", impact: "Categorized via AI NLP" };
    }

    if (catName) catName.textContent = found.cat;
    if (catAmount) catAmount.textContent = amt;
    if (catAccount) catAccount.textContent = found.acc;
    if (catImpact) catImpact.textContent = found.impact;

    if (catIcon) {
      catIcon.setAttribute("data-lucide", found.icon);
      if (window.lucide) lucide.createIcons();
    }
  }

  input.addEventListener("input", (e) => {
    parseExpense(e.target.value);
  });

  chips.forEach(chip => {
    chip.addEventListener("click", () => {
      playHapticSound("click");
      const val = chip.getAttribute("data-text");
      input.value = val;
      parseExpense(val);
    });
  });
}

// 7. Interactive Subscription Drain Calculator
function setupSubscriptionDrain() {
  const checkboxes = document.querySelectorAll(".sub-drain-checkbox");
  const monthlyTotal = document.getElementById("sub-drain-monthly");
  const annualTotal = document.getElementById("sub-drain-annual");

  if (!checkboxes.length || !monthlyTotal) return;

  function recalculateSubs() {
    let sum = 0;
    checkboxes.forEach(cb => {
      if (cb.checked) {
        sum += parseFloat(cb.getAttribute("data-cost")) || 0;
      }
    });

    const yearly = sum * 12;
    monthlyTotal.textContent = `₹ ${sum.toLocaleString("en-IN")}/mo`;
    annualTotal.textContent = `₹ ${yearly.toLocaleString("en-IN")}/yr`;
  }

  checkboxes.forEach(cb => {
    cb.addEventListener("change", () => {
      playHapticSound("click");
      recalculateSubs();
    });
  });
  recalculateSubs();
}

// 8. Multi-Currency Net Worth Converter
function setupCurrencySwitcher() {
  const buttons = document.querySelectorAll(".currency-btn");
  const netWorthEl = document.getElementById("currency-net-worth");
  const liquidEl = document.getElementById("currency-liquid");
  const investEl = document.getElementById("currency-invest");

  if (!buttons.length || !netWorthEl) return;

  // Base is INR (₹ 2,45,000)
  const rates = {
    INR: { symbol: "₹", rate: 1, net: 245000, liquid: 85000, invest: 160000 },
    USD: { symbol: "$", rate: 0.012, net: 2940, liquid: 1020, invest: 1920 },
    EUR: { symbol: "€", rate: 0.011, net: 2695, liquid: 935, invest: 1760 },
    GBP: { symbol: "£", rate: 0.0095, net: 2327, liquid: 807, invest: 1520 },
    AED: { symbol: "AED ", rate: 0.044, net: 10780, liquid: 3740, invest: 7040 }
  };

  buttons.forEach(btn => {
    btn.addEventListener("click", () => {
      playHapticSound("click");
      buttons.forEach(b => b.classList.remove("active"));
      btn.classList.add("active");

      const curr = btn.getAttribute("data-currency");
      const d = rates[curr] || rates.INR;

      netWorthEl.textContent = `${d.symbol}${d.net.toLocaleString()}`;
      if (liquidEl) liquidEl.textContent = `${d.symbol}${d.liquid.toLocaleString()}`;
      if (investEl) investEl.textContent = `${d.symbol}${d.invest.toLocaleString()}`;
    });
  });
}

// 9. Lifetime ROI vs Subscription Calculator
function setupLifetimeRoiCalculator() {
  const yearsSlider = document.getElementById("roi-years-slider");
  const yearsDisplay = document.getElementById("roi-years-val");
  const competitorDisplay = document.getElementById("roi-competitor-val");
  const financyDisplay = document.getElementById("roi-financy-val");
  const savingsDisplay = document.getElementById("roi-savings-val");

  if (!yearsSlider) return;

  function recalculateRoi() {
    const years = parseInt(yearsSlider.value) || 3;
    if (yearsDisplay) yearsDisplay.textContent = `${years} ${years === 1 ? "Year" : "Years"}`;

    // Competitors: $9.99/mo = $119.88/year
    const competitorCost = years * 119.88;
    // Financy Lifetime: one-time $9.99 only after trial
    const financyCost = 9.99;
    const savings = Math.max(0, competitorCost - financyCost);

    if (competitorDisplay) competitorDisplay.textContent = `$${competitorCost.toFixed(2)}`;
    if (financyDisplay) financyDisplay.textContent = `$${financyCost.toFixed(2)} (Once)`;
    if (savingsDisplay) savingsDisplay.textContent = `$${savings.toFixed(2)} Saved!`;
  }

  yearsSlider.addEventListener("input", () => {
    playHapticSound("click");
    recalculateRoi();
  });
  recalculateRoi();
}

// 10. FAQ Accordion
function setupFaqAccordion() {
  const faqItems = document.querySelectorAll(".faq-item");
  faqItems.forEach(item => {
    const trigger = item.querySelector(".faq-trigger");
    const content = item.querySelector(".faq-content");
    const icon = item.querySelector(".faq-icon");

    if (!trigger || !content) return;

    trigger.addEventListener("click", () => {
      playHapticSound("click");
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

// 11. QR Code Modal
function setupQrModal() {
  const qrTriggers = document.querySelectorAll(".open-qr-modal");
  const modal = document.getElementById("qr-modal");
  const closeModal = document.getElementById("close-qr-modal");
  const qrImg = document.getElementById("qr-code-img");

  if (!modal) return;

  if (qrImg) {
    const encodedUrl = encodeURIComponent(APP_STORE_URL);
    qrImg.src = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodedUrl}&margin=10&color=059669`;
  }

  qrTriggers.forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      playHapticSound("click");
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

// 12. Mobile Nav Toggle
function setupMobileNav() {
  const toggle = document.getElementById("mobile-menu-btn");
  const menu = document.getElementById("mobile-menu");

  if (!toggle || !menu) return;

  toggle.addEventListener("click", () => {
    playHapticSound("click");
    menu.classList.toggle("hidden");
  });

  menu.querySelectorAll("a").forEach(link => {
    link.addEventListener("click", () => {
      menu.classList.add("hidden");
    });
  });
}
