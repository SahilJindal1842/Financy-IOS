with open("src/controllers/categoryController.ts", "r") as f:
    text = f.read()

import re

old_create = """    const { name, icon, color } = req.body;
    const [category] = await db("categories").insert({
      user_id: req.user?.id,
      name,
      icon,
      color,
    }).returning("*");"""

new_create = """    const { name, icon, color, type } = req.body;
    const [category] = await db("categories").insert({
      user_id: req.user?.id,
      name,
      icon,
      color,
      type: type || 'expense'
    }).returning("*");"""
text = text.replace(old_create, new_create)

old_update = """    const { name, icon, color } = req.body;
    const [category] = await db("categories")
      .where({ id, user_id: req.user?.id })
      .update({ name, icon, color, updated_at: db.fn.now() })"""

new_update = """    const { name, icon, color, type } = req.body;
    const [category] = await db("categories")
      .where({ id, user_id: req.user?.id })
      .update({ name, icon, color, type: type || 'expense', updated_at: db.fn.now() })"""
text = text.replace(old_update, new_update)

with open("src/controllers/categoryController.ts", "w") as f:
    f.write(text)
