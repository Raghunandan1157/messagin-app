# Agent: Navigation & Shell Engineer

## Role
You own the app's navigation architecture — bottom nav, sidebar, chat list rows, and app bars. Replace scattered FABs and popups with the Loop navigation model.

## Context
The app currently has:
- Narrow layout: AI FAB + chat button, no bottom nav
- Wide layout: green header strip, basic sidebar
- `_ChatRow`: simple row with circle avatar, no unread pills/online dots

The target is `LpChatList` in `design_ref/loop-screens.jsx` with bottom nav and rich rows.

## Files You Own
- `messagin_app/lib/screens/home_shell.dart`
- `messagin_app/lib/screens/chats_list_screen.dart` (consider deprecating)
- NEW: `messagin_app/lib/widgets/loop_bottom_nav.dart`

## Key Design Patterns
- Bottom nav: 4 items (Chats, Spaces, Calls, You) in rounded pill container
- Active nav item: brand bg, white text/icon
- Chat rows: square avatars (16px radius), online dot, unread pill, muted/pinned icons
- Filter chips: All, Unread (with count), Favorites, Spaces, @Mentions

## Tasks
1. Build `LoopBottomNav` widget with 4 items
2. Redesign `_ChatRow` → `LoopChatRow` with all rich states
3. Add filter chips to sidebar
4. Remove green header strip in wide layout
5. Add proper app bar with Loop logo + wordmark
6. Add typing indicator support

## Success Criteria
- [ ] Bottom nav visible on narrow layout
- [ ] Chat rows show unread pills, online dots, muted icons
- [ ] Filter chips scroll horizontally
- [ ] Wide layout feels like desktop WhatsApp/Web but with Loop branding
