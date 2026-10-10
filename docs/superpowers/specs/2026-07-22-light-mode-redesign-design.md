# Light Mode Redesign — Warm & Creamy Neumorphic

**Date:** 2026-07-22
**Status:** Approved
**Approach:** Full Neumorphic Overhaul

## Goal

Transform the CGPA Calculator's light mode from a flat, washed-out gray theme into a warm, premium, Apple-like creamy neumorphic experience — while keeping dark mode untouched.

## Design Direction

- **Style:** Warm & Creamy
- **Cards:** Neumorphic (soft tactile shadows)
- **Background:** Warm cream gradient
- **Accent:** Indigo (kept from current brand)
- **Dark mode:** Unchanged

---

## Color Palette

### Background Colors

| Token | Old Value | New Value | Description |
|-------|-----------|-----------|-------------|
| `lightBgPrimary` | `#F8FAFC` | `#FBF7F2` | Main scaffold background (warm cream) |
| `lightBgGradientStart` | `#EFF6FF` | `#FFF8F0` | Gradient top-left (warm peach) |
| `lightBgGradientEnd` | `#F1F5F9` | `#F5EDE4` | Gradient bottom-right (warm beige) |

### Surface & Shadow Colors

| Token | Old Value | New Value | Description |
|-------|-----------|-----------|-------------|
| `lightSurfaceGlass` | `#0A000000` | `#FDF8F3` | Card surface (warm ivory) |
| `lightBorderGlass` | `#14000000` | `#E8DDD2` | Card border (warm tan) |
| `lightShadowDark` | — | `#D4C4B0` | Neumorphic dark shadow (warm brown) |
| `lightShadowLight` | — | `#FFFFFA` | Neumorphic light shadow (warm white) |

### Text Colors

| Token | Old Value | New Value | Description |
|-------|-----------|-----------|-------------|
| `lightTextPrimary` | `#0F172A` | `#3D2E22` | Main text (warm brown-black) |
| `lightTextSecondary` | `#475569` | `#6B5B4E` | Secondary text (warm medium brown) |
| `lightTextMuted` | `#94A3B8` | `#A89880` | Muted/hint text (warm gray) |

---

## Neumorphic Card Spec

### Light Mode Card Properties

```
Surface color: #FDF8F3 (warm ivory)
Border: None (depth from shadows only)
Border radius: 20px

Default state:
  Shadow dark: 6px 6px 12px #D4C4B0 (warm brown, 25% opacity)
  Shadow light: -4px -4px 8px #FFFFFA (warm white, 80% opacity)

Pressed state:
  Shadow dark: 2px 2px 4px #D4C4B0 (warm brown, 15% opacity)
  Shadow light: -2px -2px 4px #FFFFFA (warm white, 80% opacity)

Padding: 16px (default), varies per card
```

### Widget Migration: GlassCard

`GlassCard` widget will detect brightness and switch rendering:

- **Dark mode:** Glass morphism (unchanged — blur, semi-transparent white, thin border)
- **Light mode:** Neumorphic (warm surface, dual shadows, no border)

### Specific Card Behaviors

| Card | Light Mode Treatment |
|------|---------------------|
| HeroGpaCard | Neumorphic surface, GPA ring track = `#D4C4B0` at 15% opacity |
| CourseInputCard | Neumorphic, focus state = indigo tint (`#6366F1` at 8%) |
| SemesterCard | Neumorphic, same as CourseInputCard |
| MiniStatCard | Small neumorphic inset, warm surface |
| ModeSelector | Neumorphic inset (pressed-in look for selected tab) |
| EmptyState | Neumorphic circle container, warm indigo tint |
| GradeBadge | No change (already works on any background) |

---

## Background

### MeshGradientBackground

```
Light mode gradient:
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [#FFF8F0, #FBF7F2]
  )
```

Note: This is a warm peach-to-cream gradient, subtle and premium.

---

## Component-Specific Changes

### GradientButton
- Gradient: Same indigo → purple (`#6366F1` → `#A855F7`)
- Shadow: `#6366F1` at 30% opacity (warmer than current cold tone)
- Border radius: 14px (unchanged)

### AppBar
- Background: Transparent (unchanged)
- Title "GPA" color: `lightTextPrimary` (warm brown-black)
- Title "CALCULATOR" color: `lightTextMuted` (warm muted)
- Theme toggle icon: `accentPrimary` (indigo)
- Table icon: `accentPrimary` (indigo)

### Mode Selector
- Container background: `#0D000000` (black 5% — warm enough on cream)
- Border: `#14000000` (black 8%)
- Selected tab: Indigo gradient (unchanged)
- Unselected text: `lightTextMuted` (warm muted)

### Input Fields (CourseInputCard, SemesterCard)
- Field background unfocused: `#08000000` (black 3%)
- Field background focused: `#0D6366F1` (indigo 5%)
- Field border unfocused: `#14000000` (black 8%)
- Field border focused: `#4D6366F1` (indigo 30%)
- Text color: `lightTextPrimary` (warm brown-black)
- Hint color: `lightTextMuted` at 60% opacity

### CircularProgressRing
- Track color (light mode): `#D4C4B0` at 15% opacity (warm brown track)
- Progress color: Dynamic based on GPA value (success/warning/danger)

### Dropdown (Credit Hours)
- Background: `lightBgGradientStart` (#FFF8F0)
- Text color: `lightTextPrimary`
- Icon color: `lightTextMuted`

---

## Files to Modify

| File | Changes |
|------|---------|
| `lib/theme/app_theme.dart` | Update light theme colors, add shadow tokens, update ThemeData |
| `lib/widgets/glass_card.dart` | Add neumorphic rendering for light mode |
| `lib/widgets/mesh_gradient_background.dart` | Update light mode gradient colors |
| `lib/widgets/mini_stat_card.dart` | Use new surface/shadow tokens |
| `lib/widgets/mode_selector.dart` | Update light mode container colors |
| `lib/widgets/semester_card.dart` | Update field colors for warm theme |
| `lib/widgets/course_input_card.dart` | Update field colors for warm theme |
| `lib/widgets/empty_state.dart` | Update circle container colors |
| `lib/widgets/circular_progress_ring.dart` | Update track color for light mode |
| `lib/widgets/gradient_button.dart` | Update shadow color for warm tone |
| `lib/screens/splash_screen.dart` | Update light mode gradient |

---

## What Stays the Same

- Dark mode: Completely untouched
- All animations and transitions
- Google Fonts typography (Lexend + Inter)
- Indigo accent color palette
- App logic and data flow
- All widget layouts and spacing

---

## Success Criteria

1. Light mode feels warm, premium, and tactile (neumorphic)
2. Cards are clearly visible with depth (not invisible like current)
3. Dark mode remains identical to current
4. No performance regression on mid-range devices
5. All existing functionality works unchanged
