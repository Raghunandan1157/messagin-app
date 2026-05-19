import { neon } from '@neondatabase/serverless';

// Idempotent schema migration. POST with Authorization: Bearer ${API_TOKEN}.
// Safe to run repeatedly — every statement uses IF NOT EXISTS.
export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

  const auth = req.headers.authorization || '';
  const token = auth.replace(/^Bearer\s+/i, '');
  const expected = process.env.API_TOKEN;
  if (!expected) return res.status(500).json({ error: 'Server missing API_TOKEN' });
  if (token !== expected) return res.status(401).json({ error: 'Unauthorized' });

  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) return res.status(500).json({ error: 'Server missing DATABASE_URL' });
  const sql = neon(dbUrl);

  const steps = [
    `ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen timestamptz`,
    `ALTER TABLE messages ADD COLUMN IF NOT EXISTS reply_to uuid REFERENCES messages(id) ON DELETE SET NULL`,
    `ALTER TABLE messages ADD COLUMN IF NOT EXISTS attachment_id uuid`,
    `CREATE TABLE IF NOT EXISTS message_reads (
       message_id uuid NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
       user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       read_at timestamptz NOT NULL DEFAULT now(),
       PRIMARY KEY (message_id, user_id)
     )`,
    `CREATE INDEX IF NOT EXISTS idx_message_reads_user ON message_reads(user_id)`,
    `CREATE TABLE IF NOT EXISTS attachments (
       id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
       chat_id uuid REFERENCES chats(id) ON DELETE CASCADE,
       uploader_id uuid REFERENCES users(id) ON DELETE SET NULL,
       kind text NOT NULL,
       storage text NOT NULL,
       remote_id text,
       url text,
       mime text,
       size_bytes bigint,
       width int,
       height int,
       duration_ms int,
       created_at timestamptz NOT NULL DEFAULT now()
     )`,
    `CREATE INDEX IF NOT EXISTS idx_attachments_chat ON attachments(chat_id)`,
  ];

  const results = [];
  for (const stmt of steps) {
    try {
      await sql(stmt);
      results.push({ stmt: stmt.split('\n')[0].trim(), ok: true });
    } catch (err) {
      results.push({ stmt: stmt.split('\n')[0].trim(), ok: false, error: String(err?.message || err) });
    }
  }
  return res.status(200).json({ results });
}
