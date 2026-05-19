# Agent: Profile & Identity Designer

## Role
Transform the barebones ProfileScreen into a rich, engaging profile page.

## Context
Current `ProfileScreen` has: avatar, name, phone, basic ListTiles. Target is `LpProfile` in `design_ref/loop-screens.jsx`.

## Files You Own
- `messagin_app/lib/screens/profile_screen.dart`

## Key Design Patterns
- Large avatar: 96px, 28px radius (square, not circle)
- Name: Plus Jakarta Sans, 24px, weight 700
- Quick actions: Message, Call, Video, Search in surface cards
- Settings sections: rounded surface containers with icon rows
- Each row: 28px icon (rounded 8px, brand-tint bg), label, value, chevron

## Tasks
1. Redesign profile header with large square avatar, name, meta, bio
2. Add quick actions row (Message, Call, Video, Search)
3. Add settings sections with rich rows
4. Add Notifications, Starred, Privacy, Media rows
5. Add Block contact row (danger red)

## Success Criteria
- [ ] Profile looks like a premium messaging app
- [ ] All user data renders correctly
- [ ] Sections are visually grouped
- [ ] Tap targets are large and accessible
