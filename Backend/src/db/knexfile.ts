import type { Knex } from "knex";
import dotenv from "dotenv";
import path from "path";

// Load .env from the root of the project
dotenv.config({ path: path.resolve(__dirname, "../../.env") });

const config: { [key: string]: Knex.Config } = {
  development: {
    client: "pg",
    connection: process.env.DATABASE_URL || "postgres://finpilot:finpilot@localhost:5433/finpilot",
    pool: {
      min: 2,
      max: 10
    },
    migrations: {
      tableName: "knex_migrations",
      directory: "./migrations"
    },
    seeds: {
      directory: "./seeds"
    }
  }
};

export default config;
