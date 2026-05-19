import { corsHeaders, ensureAttachmentsTable, getDbClient } from './_lib/blob.js';

// GET /api/attachments?userId=...
// Returns: [{ id, filename, url, mime_type, uploaded_at }] DESC.
export default async function handler(req, res) {
  corsHeaders(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'GET only' });

  const auth = req.headers.authorization || '';
  const token = auth.replace(/^Bearer\s+/i, '');
  const expected = process.env.API_TOKEN;
  if (!expected) return res.status(500).json({ error: 'Server missing API_TOKEN' });
  if (token !== expected) return res.status(401).json({ error: 'Unauthorized' });

  const url = new URL(req.url, `http://${req.headers.host}`);
  const userId = url.searchParams.get('userId');
  if (!userId) return res.status(400).json({ error: 'userId query param required' });

  let sql;
  try { sql = getDbClient(); } catch (e) { return res.status(500).json({ error: e.message }); }

  try { await ensureAttachmentsTable(sql); } catch (e) {
    return res.status(500).json({ error: `schema ensure failed: ${e.message}` });
  }

  try {
    const rows = await sql(
      `SELECT id, filename, url,
              COALESCE(mime_type, mime) AS mime_type,
              uploaded_at
       FROM attachments
       WHERE user_id = $1 OR uploader_id = $1
       ORDER BY uploaded_at DESC
       LIMIT 200`,
      [userId],
    );
    return res.status(200).json(rows);
  } catch (e) {
    return res.status(500).json({ error: `query failed: ${e.message}` });
  }
}
