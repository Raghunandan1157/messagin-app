import { put } from '@vercel/blob';
import { neon } from '@neondatabase/serverless';

// Allowed MIME prefixes.
export const ALLOWED_MIME_PREFIXES = ['image/', 'audio/'];
export const MAX_BYTES = 10 * 1024 * 1024; // 10 MB

export function getBlobToken() {
  const t = process.env.BLOB_READ_WRITE_TOKEN;
  if (!t) {
    throw new Error('BLOB_READ_WRITE_TOKEN missing — provision Vercel Blob.');
  }
  return t;
}

export function getDbClient() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error('DATABASE_URL missing.');
  return neon(url);
}

export function validateMime(mime) {
  if (!mime) return false;
  return ALLOWED_MIME_PREFIXES.some((p) => mime.startsWith(p));
}

let _ensured = false;
// Idempotent attachments table guarantee. First call per cold start does the
// DDL; subsequent calls skip. Safe to spam — uses IF NOT EXISTS everywhere.
export async function ensureAttachmentsTable(sql) {
  if (_ensured) return;
  await sql(`CREATE TABLE IF NOT EXISTS attachments (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id     uuid,
    uploader_id uuid,
    user_id     uuid,
    filename    text,
    kind        text,
    storage     text NOT NULL DEFAULT 'blob',
    remote_id   text,
    url         text NOT NULL,
    mime        text,
    mime_type   text,
    size_bytes  bigint,
    width       int,
    height      int,
    duration_ms int,
    created_at  timestamptz NOT NULL DEFAULT now(),
    uploaded_at timestamptz NOT NULL DEFAULT now()
  )`);
  // Bring in any missing columns (older deploys may have a narrower schema).
  const additive = [
    `ALTER TABLE attachments ADD COLUMN IF NOT EXISTS user_id uuid`,
    `ALTER TABLE attachments ADD COLUMN IF NOT EXISTS filename text`,
    `ALTER TABLE attachments ADD COLUMN IF NOT EXISTS mime_type text`,
    `ALTER TABLE attachments ADD COLUMN IF NOT EXISTS uploaded_at timestamptz NOT NULL DEFAULT now()`,
  ];
  for (const stmt of additive) {
    try { await sql(stmt); } catch { /* old PG without IF NOT EXISTS on ADD COLUMN — ignore */ }
  }
  try {
    await sql(`CREATE INDEX IF NOT EXISTS idx_attachments_user ON attachments(user_id)`);
  } catch { /* ignore */ }
  _ensured = true;
}

// Wraps `put()` so future routes can reuse one place for upload + metadata.
export async function uploadToBlob({ buffer, filename, mime }) {
  const token = getBlobToken();
  const safe = (filename || `upload-${Date.now()}`).replace(/[^a-zA-Z0-9._-]+/g, '_');
  const blob = await put(safe, buffer, {
    access: 'public',
    contentType: mime || 'application/octet-stream',
    addRandomSuffix: true,
    token,
  });
  return blob;
}

// Parse multipart/form-data into { fields, files } for serverless funcs.
// Lightweight, dependency-free. Handles single-file uploads.
export async function parseMultipart(req) {
  const ctype = req.headers['content-type'] || '';
  const m = /boundary=(?:"([^"]+)"|([^;]+))/.exec(ctype);
  if (!m) throw new Error('Missing multipart boundary');
  const boundary = '--' + (m[1] || m[2]).trim();
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const body = Buffer.concat(chunks);

  const parts = [];
  let start = body.indexOf(Buffer.from(boundary));
  if (start < 0) throw new Error('Boundary not found in body');
  start += boundary.length + 2; // skip CRLF after boundary

  while (true) {
    const end = body.indexOf(Buffer.from(boundary), start);
    if (end < 0) break;
    const part = body.slice(start, end - 2); // strip trailing CRLF
    const headerEnd = part.indexOf(Buffer.from('\r\n\r\n'));
    if (headerEnd >= 0) {
      const headers = part.slice(0, headerEnd).toString('utf8');
      const payload = part.slice(headerEnd + 4);
      parts.push({ headers, payload });
    }
    start = end + boundary.length + 2;
    if (body.slice(end + boundary.length, end + boundary.length + 2).toString() === '--') break;
  }

  const fields = {};
  const files = {};
  for (const { headers, payload } of parts) {
    const cd = /Content-Disposition:\s*form-data;([^\r\n]+)/i.exec(headers);
    if (!cd) continue;
    const nameMatch = /name="([^"]+)"/.exec(cd[1]);
    const filenameMatch = /filename="([^"]*)"/.exec(cd[1]);
    if (!nameMatch) continue;
    const name = nameMatch[1];
    if (filenameMatch && filenameMatch[1]) {
      const ctMatch = /Content-Type:\s*([^\r\n]+)/i.exec(headers);
      files[name] = {
        filename: filenameMatch[1],
        mime: ctMatch ? ctMatch[1].trim() : 'application/octet-stream',
        buffer: payload,
      };
    } else {
      fields[name] = payload.toString('utf8');
    }
  }
  return { fields, files };
}

export function corsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}
