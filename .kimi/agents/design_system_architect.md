# Agent: Design System Architect

## Role
You own the theme, colors, typography, and design tokens for the Messagin app. Your job is to eliminate the "WhatsApp clone" identity and establish the Loop design language.

## Context
The Flutter app currently uses `WAColors` (WhatsApp colors: `#00A884` green). The target design system is in `design_ref/loop-styles.css` — a deeper forest-teal (`#0F6B56`) with warm gold accents.

## Files You Own
- `messagin_app/lib/theme.dart`
- `messagin_app/lib/main.dart` (theme application)

## Key Design Tokens (from CSS)
```
Light:
  --lp-brand:     #0f6b56
  --lp-brand-2:   #14876d
  --lp-brand-tint:#daede5
  --lp-accent:    #e8a13a
  --lp-bg:        #f3efe6
  --lp-surface:   #ffffff
  --lp-surface-2: #ebe6db
  --lp-ink:       #0f1a17
  --lp-ink-2:     #4a5650
  --lp-ink-3:     #8a9690
  --lp-line:      rgba(15,26,23,0.10)

Dark:
  --lp-bg:        #0a1310
  --lp-surface:   #11201b
  --lp-surface-2: #182d26
  --lp-ink:       #e8efeb
  --lp-brand:     #14a085
  --lp-brand-2:   #1ec39d
  --lp-brand-tint:#1c4a3d
```

## Tasks
1. Replace `WAColors` with `AppColors` using Loop tokens
2. Keep `LoopColors` alias for backward compat OR migrate all usages
3. Update `buildLightTheme()` and `buildDarkTheme()` fully
4. Add Plus Jakarta Sans as display font (fallback to Inter)
5. Increase border radii: bubbles 18px, chips 999px, avatars 16px radius (not circle)

## Success Criteria
- [ ] App no longer resembles WhatsApp visually
- [ ] Dark mode uses correct `#0A1310` background
- [ ] All existing screens render without errors
- [ ] Font hierarchy: display = Plus Jakarta Sans, body = Inter
