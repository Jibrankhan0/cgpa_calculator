# Onboarding Screen Redesign Plan

## Current Issues
- Static, flat design with no depth or visual interest
- Simple icon cards (Icons.calculate_rounded, etc.) — not engaging
- Basic fade animation between pages — boring
- ClayCard + ClayButton are heavy for onboarding context
- No illustrations, no visual storytelling
- Page transitions feel generic

## Design Direction: Fresh & Premium

**Palette:** Ice Cool (#0891B2 teal) + Healthcare Clean — matches app's existing light theme
**Philosophy:** Canvas design — visual communication first, minimal text as accent
**Reference:** colors.csv #19 "Ice Cool" — Fresh, clean, professional

## Redesign Approach

### 1. Visual Identity
- **Background:** Subtle gradient mesh with animated floating orbs (teal/cyan tones)
- **Pages:** Full-bleed visual storytelling, not centered cards
- **Typography:** Lexend for headings (bold, tight), Inter for body (light, airy)
- **Colors per page:**
  - Page 1 (Calculate): Teal (#0891B2) → Cyan gradient
  - Page 2 (Track): Indigo (#6366F1) → Purple gradient
  - Page 3 (Export): Emerald (#10B981) → Green gradient

### 2. Page Layout (Each Page)
```
┌─────────────────────────┐
│  [Skip]          [Skip] │  ← top-right, subtle
│                         │
│    ╭───────────────╮    │
│    │   Animated    │    │  ← large illustration/icon area
│    │   Visual      │    │     with gradient background
│    │   (200x200)   │    │     and floating particles
│    ╰───────────────╯    │
│                         │
│     Title Text          │  ← Lexend 32px, bold, tight
│     Subtitle Text       │  ← Inter 16px, muted
│                         │
│  ○ ● ○   ← dots        │  ← animated pill indicators
│                         │
│  [  Get Started  ]      │  ← teal gradient button
└─────────────────────────┘
```

### 3. Animations
- **Page transition:** Slide + fade with slight scale (parallax feel)
- **Icon/visual area:** Pulse animation + floating particles
- **Title:** Slide up + fade in (staggered after page settles)
- **Subtitle:** Slide up + fade in (staggered after title)
- **Dots:** Animated width change with shadow
- **Background orbs:** Slow floating animation (loop)

### 4. Component Changes
- **Remove:** ClayCard, ClayButton (too heavy for onboarding)
- **Add:** Custom gradient containers, animated particles
- **Keep:** SharedPrefs logic for first-time check

### 5. Files to Modify
- `lib/screens/onboarding_screen.dart` — full rewrite
- `lib/screens/splash_screen.dart` — no changes needed (already works)

### 6. Visual Elements
Each page gets a unique animated visual:
- **Page 1:** Calculator icon with floating math symbols (+, -, ×, ÷)
- **Page 2:** Trending up icon with animated chart lines
- **Page 3:** PDF icon with floating document sheets

All visuals use gradient backgrounds matching their page color.

## Implementation Steps

1. **Rewrite `onboarding_screen.dart`:**
   - New page data model with gradient colors
   - Animated background with floating orbs
   - Custom visual widgets per page (gradient circles + icons)
   - Staggered entrance animations (title → subtitle → button)
   - Smooth page transitions with scale effect
   - Modern pill-shaped dots
   - Teal gradient "Get Started" button

2. **Keep existing logic:**
   - SharedPreferences `hasSeenOnboarding` flag
   - Navigation to HomeScreen
   - Skip functionality

3. **Verify:** `dart analyze` passes
