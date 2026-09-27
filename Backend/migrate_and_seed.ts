import { knex } from 'knex';
import config from './src/db/knexfile';

async function run() {
    const db = knex(config.development);
    try {
        console.log("Running migrations...");
        await db.migrate.latest({ directory: './src/db/migrations' });
        console.log("Migrations successful!");
        
        console.log("Running seeds...");
        await db.seed.run({ directory: './src/db/seeds' });
        console.log("Seeds successful!");
        
        console.log("Database is fully initialized!");
    } catch (err) {
        console.error("Error:", err);
    } finally {
        await db.destroy();
    }
}
run();
