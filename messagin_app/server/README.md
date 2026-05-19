# messagin-signal

Local WebRTC signaling server for the Messagin app. Tiny — one file, one dep
(`ws`). Listens on `0.0.0.0:8787` (WebSocket + HTTP on the same port).

The wire format matches the NAVA_DHARSHANA reference (Meet-clone style), so
WebRTC client code written against that protocol works here unchanged.

## What it does

Room-per-call signaling. Peers `join` a room keyed by the chat ID. The server
assigns each connection a `peerId`. After joining, peers exchange `offer` /
`answer` / `ice-candidate` messages targeted at a specific `peerId`. The server
just relays — it does not interpret WebRTC payloads.

## Wire format

All WS messages are JSON.

### Server → client (on connect)

```jsonc
{ "type": "welcome", "peerId": "<server-assigned>" }
```

### Client → server

```jsonc
{ "type": "join",          "roomId": "<chatId>", "userId": "<app-uid?>" }
{ "type": "leave" }
{ "type": "offer",         "targetPeerId": "<peerId>", "offer": <RTCSessionDescriptionInit> }
{ "type": "answer",        "targetPeerId": "<peerId>", "answer": <RTCSessionDescriptionInit> }
{ "type": "ice-candidate", "targetPeerId": "<peerId>", "candidate": <RTCIceCandidateInit> }
```

`userId` on `join` is an optional app-level tag — the canonical identity used
for routing is the server-assigned `peerId`. `userId` is echoed back to other
peers in `peer-joined` and listed in `room-joined.peers` so the app can map
peerId ↔ logged-in user.

### Server → joining peer

```jsonc
{
  "type":   "room-joined",
  "roomId": "<chatId>",
  "peerId": "<this peer>",
  "peers":  [ { "peerId": "...", "userId": "..." }, ... ]
}
```

### Server → existing peers when someone joins

```jsonc
{ "type": "peer-joined", "peerId": "<new>", "userId": "<app-uid?>" }
```

### Server → all peers when someone leaves / disconnects

```jsonc
{ "type": "peer-left", "peerId": "<gone>" }
```

Confirms `leave` to the leaver:

```jsonc
{ "type": "left", "roomId": "<chatId>" }
```

### Forwarded signaling (stamped with originator's peerId)

```jsonc
{ "type": "offer",         "offer":     <...>, "peerId": "<from>" }
{ "type": "answer",        "answer":    <...>, "peerId": "<from>" }
{ "type": "ice-candidate", "candidate": <...>, "peerId": "<from>" }
```

### Errors

```jsonc
{ "type": "error", "message": "<reason>" }
```

Reasons: `invalid_json`, `roomId_required`, `not_in_room`,
`targetPeerId_required`, `unknown_type:<x>`.

## HTTP endpoints (same port 8787)

| route     | purpose                                                      |
|-----------|--------------------------------------------------------------|
| `/health` | `{status, rooms, peers, uptime}` for liveness probes         |
| `/url`    | `{wss}` — public ngrok URL when `SIGNAL_PUBLIC_URL` is set   |
| `/`       | plaintext banner                                              |

## Run locally

```bash
cd messagin_app/server
npm install
npm start
```

Or via the zsh shortcut (boots node + ngrok, surfaces the public URL):

```bash
messagin-server          # starts node + ngrok, prints WSS URL, tails log
messagin-server-stop     # kills both
```

The functions live in `~/.zshrc` and read from `$MESSAGIN_SERVER_DIR`.

## Smoke test

```bash
curl -s http://127.0.0.1:8787/health
# {"status":"up","rooms":0,"peers":0,"uptime":1}

curl -s http://127.0.0.1:8787/url
# {"wss":null}                                  # ngrok off
# {"wss":"wss://abcd-1-2-3-4.ngrok.app"}        # ngrok on
```

Two-peer WS round-trip (A sends offer to B):

```bash
node -e '
const WS = require("ws");
const room = "smoke";
const a = new WS("ws://127.0.0.1:8787");
const b = new WS("ws://127.0.0.1:8787");
let aPid, bPid;

a.on("message", m => {
  const x = JSON.parse(m);
  console.log("A got:", x.type);
  if (x.type === "welcome") aPid = x.peerId;
});
b.on("message", m => {
  const x = JSON.parse(m);
  console.log("B got:", x.type, x.peerId || "");
  if (x.type === "welcome") bPid = x.peerId;
});

a.on("open", () => a.send(JSON.stringify({type:"join", roomId:room, userId:"alice"})));
b.on("open", () => b.send(JSON.stringify({type:"join", roomId:room, userId:"bob"})));

setTimeout(() => {
  a.send(JSON.stringify({type:"offer", targetPeerId:bPid, offer:{sdp:"fake"}}));
}, 400);
setTimeout(() => process.exit(0), 1500);
'
```

Expected: B sees `offer` with `peerId` matching A's.

## Env

| var                  | meaning                                                |
|----------------------|--------------------------------------------------------|
| `PORT`               | listen port (default 8787)                             |
| `SIGNAL_PUBLIC_URL`  | public `wss://...` URL; surfaced via GET `/url`        |

## Notes

* Stateless — no persistence, no auth. Restart and in-flight calls keep their
  ICE connections; new joins to the same room start with an empty peer list.
* 30s ping/pong heartbeat evicts zombie sockets.
* Graceful shutdown on SIGINT/SIGTERM.
* Why not unified `signal` envelope? Aligned with NAVA_DHARSHANA's discrete
  types so existing WebRTC client code works unchanged.
