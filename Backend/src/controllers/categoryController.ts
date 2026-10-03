import { Response } from "express";
import { AuthRequest } from "../middleware/auth";
import db from "../db/db";
import { getQueryScope } from "../utils/rbacUtils";

interface Category {
  id: string;
  parent_id: string | null;
  name: string;
  subcategories?: Category[];
  [key: string]: any;
}

const mapToCamel = (cat: any): any => ({
  id: cat.id,
  userId: cat.user_id,
  parentId: cat.parent_id,
  name: cat.name,
  icon: cat.icon,
  color: cat.color || "#3357ff",
  type: cat.type || "expense",
  isSystem: !cat.user_id,
  createdAt: cat.created_at,
  updatedAt: cat.updated_at,
  subcategories: cat.subcategories?.map(mapToCamel) || []
});

export const getCategories = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    
    // Fetch global categories (user_id is null) and user-specific categories
    const categories: Category[] = await db("categories")
      .whereNull("user_id")
      .orWhere(scope);

    // Build tree
    const categoryMap = new Map<string, Category>();
    const roots: Category[] = [];

    categories.forEach(cat => {
      categoryMap.set(cat.id, { ...cat, subcategories: [] });
    });

    categories.forEach(cat => {
      const node = categoryMap.get(cat.id)!;
      if (cat.parent_id) {
        const parent = categoryMap.get(cat.parent_id);
        if (parent) {
          parent.subcategories!.push(node);
        } else {
          roots.push(node);
        }
      } else {
        roots.push(node);
      }
    });

    res.json(roots.map(mapToCamel));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const createCategory = async (req: AuthRequest, res: Response) => {
  try {
    const { name, icon, color, type, parent_id } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: "Category name is required" });
    }

    const [category] = await db("categories").insert({
      user_id: req.user?.id,
      name,
      icon: icon || "tag.fill",
      color: color || "#3357ff",
      type: type || "expense",
      parent_id: parent_id || null
    }).returning("*");

    res.json(mapToCamel(category));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const updateCategory = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const { id } = req.params;
    const { name, icon, color, type } = req.body;

    // Make sure the category exists and user has access
    const category = await db("categories")
      .where({ id })
      .andWhere(function() {
        this.whereNull("user_id").orWhere(scope);
      })
      .first();

    if (!category) {
      return res.status(404).json({ error: "Category not found" });
    }

    const updated = await db("categories")
      .where({ id })
      .update({
        name: name !== undefined ? name : category.name,
        icon: icon !== undefined ? icon : category.icon,
        color: color !== undefined ? color : category.color,
        type: type !== undefined ? type : (category.type || "expense"),
        updated_at: new Date()
      })
      .returning("*");

    res.json(mapToCamel(updated[0]));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const deleteCategory = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    
    // Only allow deleting user-owned categories
    const category = await db("categories")
      .where({ id, user_id: req.user?.id })
      .first();

    if (!category) {
      return res.status(404).json({ error: "Category not found or cannot delete system categories" });
    }

    await db("categories").where({ id }).del();
    res.json({ success: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};
