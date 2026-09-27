#!/bin/bash
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
docker compose down -v
docker compose up -d
echo "Waiting for DB to start..."
sleep 5
node --import tsx ./node_modules/.bin/knex migrate:latest --knexfile src/db/knexfile.ts
node --import tsx ./node_modules/.bin/knex seed:run --knexfile src/db/knexfile.ts
echo "DB setup complete. You can start the server with: npx tsx src/index.ts"
