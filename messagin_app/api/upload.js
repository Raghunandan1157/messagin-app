import { put } from '@vercel/blob';
import { neon } from '@neondatabase/serverless';

export const config = {
  api: {
    bodyParser: false,
  },
};

// Reads raw body bytes from an incoming request stream.
async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

// POST /api/upload?chatId=...&uploaderId=...&kind=image|audio|file&name=foo.jpg
// Body: raw file bytes (Content-Type set to the file's mime).
// Response: { id, url, kind, mime, size }
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

  const blobToken = process.env.BLOB_READ_WRITE_TOKEN;
  if (!blobToken) {
    return res.status(500).json({
      error: 'Server missing BLOB_READ_WRITE_TOKEN — provision Vercel Blob store and add the token in Project Settings → Environment Variables.',
    });
  }

  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) return res.status(500).json({ error: 'Server missing DATABASE_URL' });

  const url = new URL(req.url, `http://${req.headers.host}`);
  const chatId = url.searchParams.get('chatId');
  const uploaderId = url.searchParams.get('uploaderId');
  const kind = url.searchParams.get('kind') || 'file';
  const name = url.searchParams.get('name') || `upload-${Date.now()}`;
  const mime = req.headers['content-type'] || 'application/octet-stream';

  if (!chatId || !uploaderId) {
    return res.status(400).json({ error: 'chatId and uploaderId required' });
  }

  let buf;
  try {
    buf = await readBody(req);
  } catch (e) {
    return res.status(400).json({ error: `body read failed: ${e?.message || e}` });
  }
  if (!buf || buf.length === 0) {
    return res.status(400).json({ error: 'Empty body' });
  }

  // Path inside the Blob store: chats/<chatId>/<timestamp>-<filename>.
  const safeName = name.replace(/[^a-zA-Z0-9._-]+/g, '_');
  const path = `chats/${chatId}/${Date.now()}-${safeName}`;

  let blobUrl;
  try {
    const blob = await put(path, buf, {
      access: 'public',
      contentType: mime,
      token: blobToken,
    });
    blobUrl = blob.url;
  } catch (e) {
    return res.status(500).json({ error: `blob put failed: ${e?.message || e}` });
  }

  const sql = neon(dbUrl);
  let row;
  try {
    const rows = await sql(
      `INSERT INTO attachments (chat_id, uploader_id, kind, storage, url, mime, size_bytes)
       VALUES ($1, $2, $3, 'blob', $4, $5, $6) RETURNING *`,
      [chatId, uploaderId, kind, blobUrl, mime, buf.length],
    );
    row = rows[0];
  } catch (e) {
    return res.status(500).json({ error: `attachment insert failed: ${e?.message || e}` });
  }

  return res.status(200).json({
    id: row.id,
    url: row.url,
    kind: row.kind,
    mime: row.mime,
    size: row.size_bytes,
  });
}
