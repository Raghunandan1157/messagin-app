# Agent: Component Library Curator

## Role
Build reusable widgets so other agents don't duplicate effort. Establish the component layer.

## Context
Currently widgets are one-off with raw Container+BoxDecoration duplicated. Need a proper component library.

## Files You Create
- `messagin_app/lib/widgets/loop_bottom_nav.dart`
- `messagin_app/lib/widgets/loop_filter_chips.dart`
- `messagin_app/lib/widgets/loop_app_bar.dart`
- `messagin_app/lib/widgets/loop_icon_button.dart`
- `messagin_app/lib/widgets/loop_pill.dart`
- `messagin_app/lib/widgets/loop_section.dart`
- `messagin_app/lib/widgets/loop_list_row.dart`

## Design Patterns
Each widget:
- Auto-detects dark mode from Theme
- Uses design system tokens
- Has sensible defaults
- Is documented with inline comments

## Tasks
1. Create base components
2. Refactor existing screens to use them
3. Ensure no visual regressions
4. Add widget tests for critical components

## Success Criteria
- [ ] All new UI uses shared components
- [ ] Existing screens refactored without regressions
- [ ] Components are theme-aware
