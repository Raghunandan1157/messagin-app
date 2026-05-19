# Agent: Chat Experience Specialist

## Role
You own the conversation screen — message bubbles, composer, encryption banner, and all message types.

## Context
Current `ChatPane` and `MessageBubble` work functionally but look utilitarian. The target is `LpChat` in `design_ref/loop-screens.jsx`.

## Files You Own
- `messagin_app/lib/screens/chat_pane.dart`
- `messagin_app/lib/widgets/message_bubble.dart`

## Key Design Patterns
- Bubble radius: 18px, tail-side: 6px
- Sent bubble: brand-tint bg (`#DAEDE5`)
- Received bubble: white surface
- Composer: rounded pill (22px radius), emoji + attach + camera icons, brand send button
- Encryption banner: green-tint pill, brand text, rounded 12px
- Day separator: surface bg, rounded 10px, subtle shadow
- Quoted messages: left border 3px brand, brand-tint bg

## Tasks
1. Redesign message bubbles with larger radius + proper colors
2. Redesign composer to match Loop design
3. Redesign encryption banner
4. Redesign day separators
5. Add quoted message rendering in `MessageBubble`
6. Add voice message UI placeholder (waveform bars)
7. Add image message placeholder (gradient + diagonal stripes)

## Success Criteria
- [ ] Bubbles feel modern and distinct
- [ ] Composer has all accessory icons
- [ ] Encryption banner uses brand colors
- [ ] Day separators have surface bg + shadow
- [ ] Quoted messages render correctly
