# Messagin app

WhatsApp-style cross-platform chat. Flutter (android/ios/web/macos/windows/linux) + Neon Postgres.

## Layout

```
Messagin app/
├── README.md               ← you are here
├── design_ref/             ← original Loop + wireframe React/HTML mockups
└── messagin_app/           ← Flutter app
    ├── lib/
    │   ├── main.dart
    │   ├── theme.dart
    │   ├── models/         (user, chat, message, reaction)
    │   ├── db/             (Neon Postgres client + repository)
    │   ├── state/          (AppState — auth + session)
    │   ├── screens/        (login, otp, profile setup, chats list, chat, new chat, profile)
    │   └── widgets/        (avatar, chat tile, message bubble, reaction picker)
    └── .env                (Neon credentials)
```

## Run

```bash
cd messagin_app
flutter pub get
flutter run                          # picks default device
flutter run -d chrome                # web (see caveat)
flutter run -d macos                 # macOS
flutter run -d windows
```

## Auth (demo)

Phone-number login with universal OTP **`1234`**. Real SMS verification is disabled.

1. Phone Entry → pick country, enter number
2. OTP screen → type `1234` (auto-verifies)
3. If new phone: Profile Setup → name → home
4. If existing phone: jump straight to chats

Seeded phones (use country code `+1`, country "United States" — strip the `+1` since the field already prepends it; or just pick India `+91` and type `5550001`):

| Phone        | Name  |
|--------------|-------|
| `+15550001`  | You   |
| `+15550002`  | Mira  |
| `+15550003`  | Akira |
| `+15550004`  | Sam   |
| `+15550005`  | Priya |

## Features (current)

- Phone + OTP login (dev OTP = 1234)
- Chat list (direct + group), pull-to-refresh, 5 s polling
- 1:1 chat + group chat, WhatsApp-style bubbles, sender colors
- Send text messages (text-only — media/voice/video disabled per spec)
- Emoji picker (in-input)
- **Long-press a message → reaction picker** (❤️ 😂 😮 😢 🙏 👍 + full set)
- Reactions persist + sync across clients via Neon
- Profile screen + sign out

## Backend

**Neon Postgres** (project: `orange-hall-62749709`, database `neondb`).

Schema:
- `users (id, phone, name, avatar_url, about, last_seen, created_at)`
- `chats (id, is_group, title, avatar_url, created_by, created_at)`
- `chat_members (chat_id, user_id, role, joined_at)`
- `messages (id, chat_id, sender_id, body, kind, reply_to, created_at, edited_at)`
- `message_reads (message_id, user_id, read_at)`
- `message_reactions (message_id, user_id, emoji, created_at)`

Connection string lives in `messagin_app/.env`. The Dart `postgres` package opens a TCP connection with `sslMode: require`.

### Note on Neon vs Supabase

Original brief said **Neon** so the database is on Neon. A later instruction mentioned "Supabase" — kept as Neon to avoid losing the seeded data + provisioned project. If Supabase is strictly required, the swap is small (replace `lib/db/neon_client.dart` with the `supabase_flutter` package and switch repository calls to `client.from(table).select()`).

### Web transport (HTTP proxy)

Browsers can't open raw TCP, so the Flutter web build talks to a tiny Vercel serverless function that wraps the Neon HTTP driver.

Layout:
- `messagin_app/api/sql.js` — POST endpoint. Bearer-auth, table allowlist, named-param translation.
- `messagin_app/package.json` — pulls `@neondatabase/serverless`.
- `messagin_app/vercel.json` — `flutter build web` as build command, `build/web` as output.

Native targets (android/ios/macos/windows/linux) skip the proxy and connect TCP directly via `package:postgres`. Switch happens at runtime via `kIsWeb`.

#### Deploy the web build + proxy

```bash
cd messagin_app
npm install
vercel link                              # one time
vercel env add DATABASE_URL              # paste the Neon connection string
vercel env add API_TOKEN                 # any random string; must match .env
vercel deploy --prod
```

The Vercel build runs `flutter build web --release` and serves the SPA from `build/web`. The proxy lives at `https://<your-deploy>.vercel.app/api/sql`.

For local web dev:
```bash
vercel dev                               # serves Flutter + /api together at :3000
```

Update `messagin_app/.env`:
- `API_ENDPOINT` — proxy URL. Default `/api/sql` works when Flutter web is served from the same Vercel project.
- `API_TOKEN` — must match the Vercel env var.

### Realtime

Neon has no realtime channel. The app polls (`Timer.periodic`) every 3 s in chat view, 5 s in inbox. Switch to LISTEN/NOTIFY or Supabase realtime later if needed.

## Brand

- Forest teal `#0F6B56` (light) / `#14A085` (dark)
- Bubble greens mirror WhatsApp without being identical (`#DCF8C6` light-mine, `#075E54` dark-mine)
- Type: Inter / Plus Jakarta Sans (defined in design ref; theme uses system default for now)

## Disabled (per spec)

- Image / video send buttons
- Voice / video call buttons
- File attachments

The placeholder Calls and Status tabs in the chat list are intentional shells.
