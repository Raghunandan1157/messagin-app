import { neon } from '@neondatabase/serverless';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(204).end();

  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) return res.status(500).json({ error: 'Server missing DATABASE_URL' });
  const sql = neon(dbUrl);

  if (req.method === 'GET') {
    try {
      const rows = await sql(
        "SELECT value, updated_at FROM system_config WHERE key = 'signal_wss_url'"
      );
      if (rows.length === 0) return res.status(200).json({ wss: null, updated_at: null });
      return res.status(200).json({ wss: rows[0].value, updated_at: rows[0].updated_at });
    } catch (err) {
      return res.status(500).json({ error: String(err?.message || err) });
    }
  }

  if (req.method === 'POST') {
    const auth = req.headers.authorization || '';
    const token = auth.replace(/^Bearer\s+/i, '');
    const expected = process.env.API_TOKEN;
    if (!expected) return res.status(500).json({ error: 'Server missing API_TOKEN' });
    if (token !== expected) return res.status(401).json({ error: 'Unauthorized' });

    let body = req.body;
    if (typeof body === 'string') {
      try { body = JSON.parse(body); } catch { return res.status(400).json({ error: 'Bad JSON' }); }
    }
    const wss = body?.wss;
    if (typeof wss !== 'string' || !wss.startsWith('wss://')) {
      return res.status(400).json({ error: 'wss must start with wss://' });
    }

    try {
      await sql(
        `INSERT INTO system_config (key, value, updated_at)
         VALUES ('signal_wss_url', $1, now())
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()`,
        [wss]
      );
      return res.status(200).json({ ok: true, wss });
    } catch (err) {
      return res.status(500).json({ error: String(err?.message || err) });
    }
  }

  return res.status(405).json({ error: 'GET or POST only' });
}
