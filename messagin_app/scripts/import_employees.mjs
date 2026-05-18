// One-off importer: reads a JSON dump of Supabase employees and upserts
// into Neon users (phone-prefixed +91). Idempotent via ON CONFLICT.
//
// Usage:
//   DATABASE_URL=postgresql://... node scripts/import_employees.mjs <path-to-json>

import { readFileSync } from 'node:fs';
import { neon } from '@neondatabase/serverless';

const DEFAULT_FILE =
  '/Users/raghunandanmali/.claude/projects/-Users-raghunandanmali-Desktop-APP-STORE-Messagin-app/c269e043-a298-4ec3-b8f3-24769bf1f46b/tool-results/mcp-plugin_supabase_supabase-execute_sql-1779126728979.txt';

const filePath = process.argv[2] || DEFAULT_FILE;
const dbUrl = process.env.DATABASE_URL;
if (!dbUrl) {
  console.error('Set DATABASE_URL env var');
  process.exit(1);
}

const raw = readFileSync(filePath, 'utf8');

// MCP tool wraps the SQL result in {"result": "Below is the result...<untrusted-data-XXX>[...JSON...]</untrusted-data-XXX>..."}
function extractRows(text) {
  let body = text;
  try {
    const outer = JSON.parse(text);
    if (outer && typeof outer.result === 'string') body = outer.result;
  } catch {}
  const start = body.indexOf('[{');
  const end = body.lastIndexOf('}]');
  if (start === -1 || end === -1) throw new Error('No JSON array found');
  const slice = body.slice(start, end + 2);
  const arr = JSON.parse(slice);
  if (Array.isArray(arr) && arr[0]?.data) return arr[0].data;
  return arr;
}

const rows = extractRows(raw);
console.log(`Loaded ${rows.length} employees`);

const sql = neon(dbUrl);

const BATCH = 100;
let inserted = 0;
let skipped = 0;

for (let i = 0; i < rows.length; i += BATCH) {
  const slice = rows.slice(i, i + BATCH);
  const placeholders = [];
  const params = [];
  let pi = 1;
  for (const r of slice) {
    const phone = `+91${r.mobile}`;
    placeholders.push(`($${pi++}, $${pi++}, $${pi++}, $${pi++}, $${pi++})`);
    params.push(phone, r.name || `Employee ${r.emp_id}`, r.emp_id, r.role, r.location);
  }
  const q = `INSERT INTO users (phone, name, emp_id, role, location)
             VALUES ${placeholders.join(',')}
             ON CONFLICT (phone) DO UPDATE SET
               name = EXCLUDED.name,
               emp_id = COALESCE(EXCLUDED.emp_id, users.emp_id),
               role = COALESCE(EXCLUDED.role, users.role),
               location = COALESCE(EXCLUDED.location, users.location)
             RETURNING (xmax = 0) AS inserted`;
  try {
    const res = await sql(q, params);
    for (const row of res) {
      if (row.inserted) inserted++; else skipped++;
    }
    console.log(`Batch ${Math.floor(i / BATCH) + 1}: ${slice.length} rows processed`);
  } catch (e) {
    console.error(`Batch failed at offset ${i}:`, e.message);
  }
}

console.log(`\nDone. Inserted: ${inserted}, Updated: ${skipped}`);

const [{ n }] = await sql('SELECT COUNT(*)::int AS n FROM users');
console.log(`Total users in Neon now: ${n}`);
