#!/usr/bin/env node
/**
 * Messagin app — WebRTC signaling server.
 *
 * Protocol matches the NAVA_DHARSHANA reference (Google-Meet-clone style) so
 * the same wire format can be reused. Discrete offer/answer/ice-candidate
 * message types, server-assigned peerId per connection.
 *
 * --- Wire format (JSON over WS) ------------------------------------------
 *
 * On connect, server pushes:
 *   { type:'welcome', peerId }
 *
 * Client → server:
 *   { type:'join',          roomId, userId? }        // userId is app-level tag
 *   { type:'leave' }                                  // leaves currentRoom
 *   { type:'offer',         targetPeerId, offer }
 *   { type:'answer',        targetPeerId, answer }
 *   { type:'ice-candidate', targetPeerId, candidate }
 *
 * Server → joining peer:
 *   { type:'room-joined', roomId, peerId, peers: [ {peerId, userId?}, ... ] }
 *
 * Server → existing peers when someone joins:
 *   { type:'peer-joined', peerId, userId? }
 *
 * Server → all peers when someone leaves / disconnects:
 *   { type:'peer-left',   peerId }
 *
 * Server → confirms leave to the leaver:
 *   { type:'left', roomId }
 *
 * Server → forwards 1-to-1 signaling msgs, stamping the originator's peerId:
 *   { type:'offer',         offer,     peerId }
 *   { type:'answer',        answer,    peerId }
 *   { type:'ice-candidate', candidate, peerId }
 *
 * Server → on bad input:
 *   { type:'error', message }
 *
 * --- HTTP (same port 8787) ------------------------------------------------
 *   GET /health   →  { status:'up', rooms, peers, uptime }
 *   GET /url      →  { wss: $SIGNAL_PUBLIC_URL || null }
 *
 * Listens on 0.0.0.0:8787.
 */

const http = require('http');
const crypto = require('crypto');
const { WebSocketServer } = require('ws');

const PORT = parseInt(process.env.PORT || '8787', 10);
const HOST = '0.0.0.0';
const BOOT_TS = Date.now();

// rooms: Map<roomId, Map<peerId, ws>>
const rooms = new Map();

function newPeerId() {
  return crypto.randomBytes(8).toString('hex');
}

function getRoom(roomId) {
  let r = rooms.get(roomId);
  if (!r) { r = new Map(); rooms.set(roomId, r); }
  return r;
}

function totalPeers() {
  let n = 0;
  for (const r of rooms.values()) n += r.size;
  return n;
}

function publicUrl() {
  return process.env.SIGNAL_PUBLIC_URL || null;
}

function sendJson(ws, obj) {
  if (!ws || ws.readyState !== ws.OPEN) return;
  try { ws.send(JSON.stringify(obj)); } catch {}
}

function peerListFor(roomId) {
  const r = rooms.get(roomId);
  if (!r) return [];
  const out = [];
  for (const [pid, w] of r) out.push({ peerId: pid, userId: w.ctx?.userId ?? null });
  return out;
}

function removeFromRoom(ws) {
  const ctx = ws.ctx;
  if (!ctx || !ctx.roomId) return;
  const { roomId, peerId } = ctx;
  const r = rooms.get(roomId);
  if (!r) { ws.ctx = null; return; }
  if (r.get(peerId) === ws) r.delete(peerId);
  // Notify the rest.
  for (const [, other] of r) sendJson(other, { type: 'peer-left', peerId });
  if (r.size === 0) rooms.delete(roomId);
  ws.ctx = { peerId, roomId: null, userId: ctx.userId ?? null };
}

// --- HTTP --------------------------------------------------------------

const httpServer = http.createServer((req, res) => {
  const url = req.url || '/';
  if (req.method === 'GET' && url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'up',
      rooms: rooms.size,
      peers: totalPeers(),
      uptime: Math.floor((Date.now() - BOOT_TS) / 1000),
    }));
    return;
  }
  if (req.method === 'GET' && url === '/url') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ wss: publicUrl() }));
    return;
  }
  if (req.method === 'GET' && url === '/') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('messagin-signal up — GET /health or /url, or connect via WebSocket\n');
    return;
  }
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'not_found', url }));
});

// --- WebSocket ---------------------------------------------------------

const wss = new WebSocketServer({ server: httpServer });

wss.on('connection', (ws) => {
  const peerId = newPeerId();
  ws.ctx = { peerId, roomId: null, userId: null };
  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });

  // Tell the new peer their server-assigned id.
  sendJson(ws, { type: 'welcome', peerId });

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); }
    catch { return sendJson(ws, { type: 'error', message: 'invalid_json' }); }

    const { type } = msg;

    switch (type) {
      case 'join': {
        const { roomId, userId } = msg;
        if (!roomId || typeof roomId !== 'string') {
          return sendJson(ws, { type: 'error', message: 'roomId_required' });
        }
        // If already in a different room, leave it first.
        if (ws.ctx.roomId && ws.ctx.roomId !== roomId) removeFromRoom(ws);

        ws.ctx.userId = (typeof userId === 'string' ? userId : null);
        const room = getRoom(roomId);
        // Existing peers BEFORE we add this one.
        const existing = peerListFor(roomId);
        room.set(peerId, ws);
        ws.ctx.roomId = roomId;

        // Tell the joiner about everyone already in.
        sendJson(ws, {
          type: 'room-joined',
          roomId,
          peerId,
          peers: existing,
        });
        // Tell the others a new peer joined.
        for (const [pid, other] of room) {
          if (pid === peerId) continue;
          sendJson(other, { type: 'peer-joined', peerId, userId: ws.ctx.userId });
        }
        return;
      }

      case 'leave': {
        const roomId = ws.ctx.roomId;
        if (roomId) {
          removeFromRoom(ws);
          sendJson(ws, { type: 'left', roomId });
        }
        return;
      }

      case 'offer':
      case 'answer':
      case 'ice-candidate': {
        const { targetPeerId } = msg;
        if (!ws.ctx.roomId) {
          return sendJson(ws, { type: 'error', message: 'not_in_room' });
        }
        if (!targetPeerId) {
          return sendJson(ws, { type: 'error', message: 'targetPeerId_required' });
        }
        const r = rooms.get(ws.ctx.roomId);
        if (!r) return;
        const target = r.get(targetPeerId);
        if (!target) return; // silently drop — peer gone
        const out = { type, peerId };
        if (type === 'offer') out.offer = msg.offer;
        if (type === 'answer') out.answer = msg.answer;
        if (type === 'ice-candidate') out.candidate = msg.candidate;
        sendJson(target, out);
        return;
      }

      default:
        sendJson(ws, { type: 'error', message: `unknown_type:${type}` });
    }
  });

  ws.on('close', () => { removeFromRoom(ws); });
  ws.on('error', () => { removeFromRoom(ws); });
});

// Heartbeat — evict zombies every 30s.
const HEARTBEAT_MS = 30_000;
const heartbeat = setInterval(() => {
  for (const ws of wss.clients) {
    if (ws.isAlive === false) { try { ws.terminate(); } catch {}; continue; }
    ws.isAlive = false;
    try { ws.ping(); } catch {}
  }
}, HEARTBEAT_MS);
wss.on('close', () => clearInterval(heartbeat));

// Boot.
httpServer.listen(PORT, HOST, () => {
  const wssUrl = publicUrl();
  console.log(`[messagin-signal] listening on ws://${HOST}:${PORT} (http on same port)`);
  if (wssUrl) console.log(`[messagin-signal] public WSS URL: ${wssUrl}`);
});

// Graceful shutdown.
function shutdown(sig) {
  console.log(`[messagin-signal] ${sig}, shutting down`);
  clearInterval(heartbeat);
  for (const ws of wss.clients) { try { ws.close(1001, 'server_shutdown'); } catch {} }
  httpServer.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 5000).unref();
}
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
