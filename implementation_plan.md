# FinPilot AI Native iOS - UI Refactor Plan

This plan outlines the complete UI refactoring of the SwiftUI iOS app to exactly match the 8-screen mockup design (green theme) that was previously built on the Windows/Next.js system.

## User Review Required

> [!IMPORTANT]
> The current SwiftUI iOS app was generated with a default blue theme and basic layout. Implementing the pixel-perfect design from the mockup will involve completely replacing the `DashboardView`, `TransactionsView`, `BudgetsView`, `AIInsightsView`, and `ProfileView`, as well as updating the core `DesignSystem.swift` to use the new Green gradient theme. Please review this plan and confirm if you want me to proceed with these extensive UI rewrites!

## Proposed Changes

### Core Design System & Theming

- **[MODIFY]** `iOS/FinPilotAI/Sources/Core/DesignSystem/DesignSystem.swift`
  - Update `FinPilotColors.primary` to the specific deep green (`#0F9D58` or similar) from the mockup.
  - Define custom gradients (like the Monthly Budget card gradient).
  - Define custom background colors (off-white/light gray) used in the mockup.
  - Define specific typography weights and rounded fonts to match the clean aesthetic.

---

### Dashboard (Home Screen)

- **[MODIFY]** `iOS/FinPilotAI/Sources/Features/Dashboard/DashboardView.swift`
  - Remove standard Navigation Title and replace with custom Header: "Good Morning, Sahil" with a subtitle.
  - **Monthly Budget Card:** Replace simple balance card with the large green gradient card showing "₹ 30,000", a horizontal progress bar, and "spent" vs "left" values.
  - **Quick Actions:** Replace standard icons with custom colored circular icons for: `Add Expense`, `View Insights`, `Set Budget`, and `Goals`.
  - **Today's Expenses:** Replace "Recent Activity" empty state with a styled list of transactions featuring category-specific icons (Food, Transport, Groceries) and right-aligned amounts.

---

### New "Add Expense" Screen

- **[NEW]** `iOS/FinPilotAI/Sources/Features/Transactions/AddExpenseView.swift`
  - Build the full-screen modal or navigation push screen for "Add Expense".
  - Large centered amount input (`₹ 0`).
  - "Select Category" grid with multi-colored circular category icons.
  - Date Picker row and Note input field.
  - Large green "Save Expense" sticky button at the bottom.

---

### Transactions Tab

- **[MODIFY]** `iOS/FinPilotAI/Sources/Features/Transactions/TransactionsView.swift`
  - Add custom segmented control pill toggle: `All` | `Expenses` | `Income`.
  - Group transactions by date with headers (e.g., "Today", "16 Sep 2025").
  - Implement the list item UI: circular category icon, title, subtitle (time/note), and amount (negative/positive coloring).

---

### Budgets Tab

- **[MODIFY]** `iOS/FinPilotAI/Sources/Features/Budgets/BudgetsView.swift`
  - Add top toggle: `Monthly` | `Weekly`.
  - Implement a large interactive Donut Chart showing total budget vs spent in the center.
  - Implement the "Category-wise Spending" list with horizontal progress bars and percentage indicators.

---

### AI Insights Tab

- **[MODIFY]** `iOS/FinPilotAI/Sources/Features/AIInsights/AIInsightsView.swift`
  - Add the AI bot icon and the positive message card ("You're doing great!").
  - Implement the "Spending Overview" bar chart.
  - Implement the "Top Spending Categories" list with percentage breakdowns.

---

### Profile Tab

- **[MODIFY]** `iOS/FinPilotAI/Sources/Features/Profile/ProfileView.swift`
  - Build the custom top half with a dark green curved/extended header.
  - Add user avatar, name, and email centered in the header.
  - Add the overlapping white "Financial Health - Good" card.
  - Build the clean list of settings rows (Account, Notifications, Export, Help, About, Log Out).

## Verification Plan

### Manual Verification
- Once the code is written, you will need to open the app in the iOS Simulator.
- Navigate through all 5 bottom tabs and verify they match the exact layout, colors, and styling of the provided image mockup.
- Click "Add Expense" from the Dashboard to test the new data entry screen.
