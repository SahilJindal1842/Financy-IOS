import type { Knex } from "knex";
import dotenv from "dotenv";
import path from "path";

// Load .env from the root of the project
dotenv.config({ path: path.resolve(__dirname, "../../.env") });

const dbUrl = process.env.DATABASE_URL || "postgres://finpilot:finpilot@localhost:5433/finpilot";
const isCloudOrSsl =
  dbUrl.includes("supabase.co") ||
  dbUrl.includes("pooler.supabase.com") ||
  dbUrl.includes("sslmode=require") ||
  process.env.DB_SSL === "true";

const dbConfig: Knex.Config = {
  client: "pg",
  connection: isCloudOrSsl
    ? {
        connectionString: dbUrl,
        ssl: { rejectUnauthorized: false }
      }
    : dbUrl,
  pool: {
    min: 2,
    max: 20
  },
  migrations: {
    tableName: "knex_migrations",
    directory: "./migrations"
  },
  seeds: {
    directory: "./seeds"
  }
};

const config: { [key: string]: Knex.Config } = {
  development: dbConfig,
  production: dbConfig,
  test: dbConfig
};

export default config;
