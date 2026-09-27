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
          // If parent is not found, treat as root
          roots.push(node);
        }
      } else {
        roots.push(node);
      }
    });

    const mapToCamel = (cat: any): any => ({
      id: cat.id,
      userId: cat.user_id,
      parentId: cat.parent_id,
      name: cat.name,
      icon: cat.icon,
      color: cat.color,
      type: cat.type,
      createdAt: cat.created_at,
      updatedAt: cat.updated_at,
      subcategories: cat.subcategories?.map(mapToCamel) || []
    });

    res.json(roots.map(mapToCamel));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};
