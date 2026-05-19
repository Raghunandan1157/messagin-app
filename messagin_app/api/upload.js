import {
  corsHeaders,
  ensureAttachmentsTable,
  getDbClient,
  parseMultipart,
  uploadToBlob,
  validateMime,
  MAX_BYTES,
} from './_lib/blob.js';

export const config = {
  api: { bodyParser: false },
};

// POST /api/upload
// Two body shapes supported:
//   1. multipart/form-data — fields: file (required), userId (or uploaderId),
//      optional chatId, kind. Spec-compliant path.
//   2. Raw bytes — Content-Type = file mime. Query string supplies metadata:
//      ?chatId=&uploaderId=&kind=&name=. Used by the Flutter web client.
export default async function handler(req, res) {
  corsHeaders(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

  // Bearer token guard.
  const auth = req.headers.authorization || '';
  const token = auth.replace(/^Bearer\s+/i, '');
  const expected = process.env.API_TOKEN;
  if (!expected) return res.status(500).json({ error: 'Server missing API_TOKEN' });
  if (token !== expected) return res.status(401).json({ error: 'Unauthorized' });

  let sql;
  try { sql = getDbClient(); } catch (e) { return res.status(500).json({ error: e.message }); }

  try { await ensureAttachmentsTable(sql); } catch (e) {
    return res.status(500).json({ error: `schema ensure failed: ${e.message}` });
  }

  const ctype = (req.headers['content-type'] || '').toLowerCase();
  let buffer;
  let filename;
  let mime;
  let userId;
  let chatId;
  let kind;

  try {
    if (ctype.startsWith('multipart/form-data')) {
      const { fields, files } = await parseMultipart(req);
      const f = files.file;
      if (!f) return res.status(400).json({ error: 'Missing form field: file' });
      buffer = f.buffer;
      filename = f.filename;
      mime = f.mime;
      userId = fields.userId || fields.uploaderId;
      chatId = fields.chatId || null;
      kind = fields.kind || (mime?.startsWith('image/') ? 'image' : mime?.startsWith('audio/') ? 'audio' : 'file');
      if (!userId) return res.status(400).json({ error: 'Missing form field: userId' });
    } else {
      // Raw-body path: query params + body bytes.
      const url = new URL(req.url, `http://${req.headers.host}`);
      userId = url.searchParams.get('userId') || url.searchParams.get('uploaderId');
      chatId = url.searchParams.get('chatId');
      kind = url.searchParams.get('kind') || 'file';
      filename = url.searchParams.get('name') || `upload-${Date.now()}`;
      mime = req.headers['content-type'] || 'application/octet-stream';
      if (!userId) return res.status(400).json({ error: 'userId query param required' });
      const chunks = [];
      for await (const c of req) chunks.push(c);
      buffer = Buffer.concat(chunks);
    }
  } catch (e) {
    return res.status(400).json({ error: `body parse failed: ${e.message}` });
  }

  if (!buffer || buffer.length === 0) {
    return res.status(400).json({ error: 'Empty file' });
  }
  if (buffer.length > MAX_BYTES) {
    return res.status(400).json({ error: `File too large (${buffer.length} > ${MAX_BYTES} bytes)` });
  }
  if (!validateMime(mime)) {
    return res.status(400).json({ error: `Disallowed MIME: ${mime}. Allowed: image/*, audio/*` });
  }

  let blob;
  try {
    blob = await uploadToBlob({ buffer, filename, mime });
  } catch (e) {
    return res.status(500).json({ error: `blob upload failed: ${e.message}` });
  }

  let row;
  try {
    const rows = await sql(
      `INSERT INTO attachments
         (chat_id, uploader_id, user_id, filename, kind, storage, url, mime, mime_type, size_bytes)
       VALUES ($1, $2, $3, $4, $5, 'blob', $6, $7, $7, $8)
       RETURNING id, filename, url, mime_type, uploaded_at`,
      [chatId, userId, userId, filename, kind, blob.url, mime, buffer.length],
    );
    row = rows[0];
  } catch (e) {
    return res.status(500).json({ error: `attachment insert failed: ${e.message}` });
  }

  return res.status(200).json({
    id: row.id,
    url: row.url,
    filename: row.filename,
    mime: row.mime_type,
    size: buffer.length,
    kind,
    uploaded_at: row.uploaded_at,
  });
}
