"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
// Load .env from the root of the project
dotenv_1.default.config({ path: path_1.default.resolve(__dirname, "../../.env") });
const config = {
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
exports.default = config;
