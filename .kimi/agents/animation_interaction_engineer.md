# Agent: Animation & Interaction Engineer

## Role
Add micro-interactions, transitions, and polish. Make the app feel alive.

## Context
Current animations: basic fade on chat pane (0.85→1.0), login screen has nice entry animations. Most interactions are instant/flat.

## Files You Touch
- All screen files (add animations)
- `messagin_app/lib/widgets/` (interactive states)

## Key Patterns
- Spring curves for physical feel
- Staggered list entrances
- Scale on button press (0.95)
- Pulsing online dot
- Bouncing typing indicator dots
- Shimmer on skeletons

## Tasks
1. Chat list entrance: staggered fade + slide
2. Typing indicator: 3 bouncing dots
3. Button press feedback: scale 0.95 with spring
4. Chat switch: slide transition
5. Pull-to-refresh: custom brand indicator
6. Message send: spring slide from bottom
7. Online dot: pulse animation
8. Skeleton shimmer: sweeping gradient

## Success Criteria
- [ ] Every screen has at least one meaningful animation
- [ ] No animation feels slow (>300ms for micro-interactions)
- [ ] 60fps on all transitions
