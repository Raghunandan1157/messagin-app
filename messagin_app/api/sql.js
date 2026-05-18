import { neon } from '@neondatabase/serverless';

const ALLOWED_TABLES = new Set([
  'users',
  'chats',
  'chat_members',
  'messages',
  'message_reads',
  'message_reactions',
]);

function isSafeStatement(sql) {
  const lower = sql.toLowerCase().trim();
  if (lower.startsWith('with')) return true;
  const verbs = ['select', 'insert', 'update', 'delete'];
  return verbs.some((v) => lower.startsWith(v));
}

const SQL_KEYWORDS = new Set([
  'set', 'only', 'lateral', 'distinct', 'all', 'where', 'as', 'when',
  'not', 'exists', 'select', 'with', 'on', 'cascade', 'restrict',
  'no', 'action', 'default', 'null', 'values', 'returning', 'using',
]);

function tablesReferenced(sql) {
  const re = /(?:\bfrom|\bjoin|\binto|\bupdate|\btable)\s+([a-zA-Z_][a-zA-Z0-9_]*)/gi;
  const out = new Set();
  let m;
  while ((m = re.exec(sql)) !== null) {
    const name = m[1].toLowerCase();
    if (SQL_KEYWORDS.has(name)) continue;
    out.add(name);
  }
  return out;
}

// Extract CTE alias names from a `WITH name AS (...), name2 AS (...)` clause.
// These should be allowed in addition to real tables for that one statement.
// Heuristic: any `<ident> AS (` is a CTE definition. Column aliases use
// `AS <ident>` (no paren) and table subquery aliases use `) AS <ident>` (paren
// before), so this match is unambiguous.
function cteNames(sql) {
  const out = new Set();
  const re = /\b([a-zA-Z_][a-zA-Z0-9_]*)\s+as\s+\(/gi;
  let m;
  while ((m = re.exec(sql)) !== null) {
    out.add(m[1].toLowerCase());
  }
  return out;
}

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'POST only' });
  }

  const auth = req.headers.authorization || '';
  const token = auth.replace(/^Bearer\s+/i, '');
  const expected = process.env.API_TOKEN;
  if (!expected) {
    return res.status(500).json({ error: 'Server missing API_TOKEN' });
  }
  if (token !== expected) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  let body = req.body;
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch {
      return res.status(400).json({ error: 'Bad JSON' });
    }
  }
  const { sql, params } = body || {};
  if (typeof sql !== 'string') {
    return res.status(400).json({ error: 'Missing sql' });
  }
  if (!isSafeStatement(sql)) {
    return res.status(400).json({ error: 'Statement not allowed' });
  }
  const ctes = cteNames(sql);
  for (const t of tablesReferenced(sql)) {
    if (ctes.has(t)) continue;
    if (!ALLOWED_TABLES.has(t)) {
      return res.status(403).json({ error: `Table not allowed: ${t}` });
    }
  }

  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    return res.status(500).json({ error: 'Server missing DATABASE_URL' });
  }
  const sqlClient = neon(dbUrl);

  try {
    const named = sql.match(/@([a-zA-Z_][a-zA-Z0-9_]*)/g) || [];
    let positional = sql;
    const args = [];
    const seen = {};
    named.forEach((tag) => {
      const key = tag.slice(1);
      if (!(key in seen)) {
        args.push(params?.[key] ?? null);
        seen[key] = args.length;
      }
      positional = positional.replace(tag, `$${seen[key]}`);
    });

    const rows = await sqlClient(positional, args);
    return res.status(200).json({ rows });
  } catch (err) {
    return res.status(500).json({ error: String(err?.message || err) });
  }
}
