with open("src/controllers/userController.ts", "r") as f:
    text = f.read()

# Add upcoming bills logic
old_response = """    res.json({
      userName: user?.name || "User",
      currency: user?.currency || "INR",
      monthlyIncome,
      totalIncome,
      totalExpenses,
      balance,
      transactions: formattedTransactions
    });"""

new_response = """
    // 3. Fetch upcoming recurring bills
    const today = new Date();
    const nextWeek = new Date();
    nextWeek.setDate(today.getDate() + 14); // Next 14 days
    
    const upcomingBills = await db("recurring_transactions")
      .where({ user_id: userId, status: "active" })
      .whereNull("deleted_at")
      .where("next_due_date", ">=", today.toISOString().split("T")[0])
      .where("next_due_date", "<=", nextWeek.toISOString().split("T")[0])
      .orderBy("next_due_date", "asc");

    res.json({
      userName: user?.name || "User",
      currency: user?.currency || "INR",
      monthlyIncome,
      totalIncome,
      totalExpenses,
      balance,
      transactions: formattedTransactions,
      upcomingBills: upcomingBills.map(b => ({
        id: b.id,
        merchant: b.merchant || "Bill",
        amount: Number(b.amount),
        nextDueDate: b.next_due_date,
        frequency: b.frequency,
        type: b.type
      }))
    });"""

text = text.replace(old_response, new_response)

with open("src/controllers/userController.ts", "w") as f:
    f.write(text)
