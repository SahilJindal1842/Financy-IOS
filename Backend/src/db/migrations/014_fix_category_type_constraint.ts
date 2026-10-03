import { Pool } from 'pg';

export const up = async (pool: Pool) => {
    await pool.query(`
        ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_type_check;
        ALTER TABLE categories ADD CONSTRAINT categories_type_check CHECK (type IN ('income', 'expense', 'recurring'));
    `);
};

export const down = async (pool: Pool) => {
    await pool.query(`
        ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_type_check;
        ALTER TABLE categories ADD CONSTRAINT categories_type_check CHECK (type IN ('income', 'expense'));
    `);
};
