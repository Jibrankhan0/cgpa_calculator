# CGPA Calculator - Premium UI/UX Redesign Spec

**Date:** 2026-07-06
**Version:** 2.0
**Target:** MCKRU University Students
**Approach:** Focused UX Overhaul (Approach 3)

---

## 1. Design System

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `bgPrimary` | `#0A0E1A` | Main background |
| `bgGradientStart` | `#0F172A` | Background gradient top |
| `bgGradientEnd` | `#0A0E1A` | Background gradient bottom |
| `surfaceGlass` | `Colors.white@0.06` | Glassmorphism card fill |
| `borderGlass` | `Colors.white@0.1` | Glassmorphism card border |
| `accentPrimary` | `#6366F1` | Primary actions, highlights |
| `accentSecondary` | `#A855F7` | Secondary accents, gradients |
| `accentGradient` | Indigo → Purple | Gradient fills |
| `success` | `#10B981` | GPA >= 3.5 |
| `warning` | `#F59E0B` | GPA 2.5 - 3.49 |
| `danger` | `#EF4444` | GPA < 2.5, delete |
| `textPrimary` | `#F8FAFC` | Main text |
| `textSecondary` | `#94A3B8` | Labels, hints |
| `textMuted` | `#475569` | Disabled, placeholder |

### Typography

| Element | Font | Weight | Size | Letter Spacing |
|---------|------|--------|------|----------------|
| Hero CGPA Number | Lexend | Bold | 48-56px | -1 |
| Section Headings | Lexend | SemiBold | 18-20px | 0.5 |
| Card Titles | Inter | Bold | 12px | 1.5 (uppercase) |
| Body Text | Inter | Regular | 14-16px | 0 |
| Labels/Captions | Inter | Medium | 10-12px | 1.0 (uppercase) |
| Button Text | Inter | Bold | 13-14px | 1.0 (uppercase) |

### Spacing & Radius

- Base unit: 4px
- Card padding: 20-24px
- Card border-radius: 20px (large), 16px (medium), 12px (small), 8px (input fields)
- Section gap: 28-32px
- Element gap: 12-16px

### Glassmorphism Card Recipe

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.06),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
    boxShadow: [
      BoxShadow(
        color: accentColor.withOpacity(0.08),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  ),
)
```

---

## 2. Home Screen

### Layout (top to bottom)

#### 2.1 AppBar
- Logo (44px circle) + "GPA" (bold) + "CALCULATOR" (muted) title
- Marks Sheet icon button (right)
- Transparent background, no elevation

#### 2.2 Mode Selector
- Pill-shaped container with subtle border
- Two tabs: "GPA (Single)" and "CGPA (Multi)"
- Animated sliding indicator (indigo gradient) moves between tabs
- Active tab: white text, indigo gradient background
- Inactive tab: muted text, transparent

#### 2.3 Hero CGPA Card
- **Full-width** glassmorphism card
- Subtle indigo-purple gradient glow on border
- **Layout**: Row with 3 sections
  - **Left (flex 2)**: Circular progress ring
    - 100px diameter, 8px stroke width
    - Background track: white@0.1
    - Progress fill: gradient (green → amber → red based on GPA)
    - Animated on data change (600ms ease-out)
  - **Center (flex 3)**: Big CGPA number
    - "OVERALL CGPA" / "SEMESTER GPA" label above
    - 48-56px Lexend Bold number
    - Color matches progress ring
  - **Right (flex 2)**: 2 mini stat cards stacked
    - "Total Credits" with value
    - "Courses" count with value
    - Both in smaller glassmorphism containers

#### 2.4 Semester/Course Section
- Section header: "SEMESTERS" / "COURSES" label (uppercase, muted, letter-spaced)
- Gap: 16px

**CGPA Mode - Semester Cards:**
- Glassmorphism card for each semester
- Row layout: Icon | Name (editable) | GPA input | Delete
- GPA input in a pill-shaped container with colored background
- Delete: red icon, subtle animation on press

**GPA Mode - Course Cards:**
- Glassmorphism card for each course
- Row layout: Lab toggle | Name input | Credit dropdown | Marks input | Grade badge | Delete
- Grade badge: colored pill (green/amber/red based on grade)
- Lab toggle: icon button with indigo highlight when active

#### 2.5 Add Button
- Full-width or centered gradient button
- Indigo → Purple gradient
- "+" icon + "ADD SEMESTER" / "ADD COURSE" text
- Shadow: colored glow matching gradient
- Haptic: medium impact on press

#### 2.6 Footer
- "Developed by" (small, muted)
- "JIBRAN KHAN DEHPAL" (slightly larger, medium weight)
- Centered, minimal

---

## 3. Marks Sheet Screen

### Layout

#### 3.1 AppBar
- Back arrow + "Marks Sheet" title (bold)
- Save button (text + check icon) + Add Semester button (icon)
- Transparent background

#### 3.2 Semester Tabs
- Horizontal scrolling tab bar
- Each tab: pill-shaped, "SEMESTER X" text
- Active: indigo text + underline indicator (3px, indigo, rounded)
- Inactive: muted text
- Smooth animated indicator transition

#### 3.3 Semester Header
- Semester name (24px, bold, white)
- Stats row: course count + GPA (colored)
- Overall CGPA badge (right-aligned, large number)

#### 3.4 Info Banner
- Refined, compact
- Indigo tinted background with icon
- Brief description of marks sheet purpose

#### 3.5 Course Cards (replacing DataTable)

**Each course = full-width glassmorphism card:**

```
┌─────────────────────────────────────────────┐
│  [Lab Toggle]  Course Name (editable)       │
│                                              │
│  Mid Marks    Final Marks    Sessional       │
│  ┌────────┐  ┌────────┐    ┌────────┐       │
│  │  ____  │  │  ____  │    │  ____  │       │
│  └────────┘  └────────┘    └────────┘       │
│                                              │
│  Credits: [3 ▾]  Total: [85]  Grade: [A]   │
│                                      [🗑️]  │
└─────────────────────────────────────────────┘
```

- **Top Row**: Lab toggle icon + Course name (full-width TextField)
- **Middle Row**: 3 equal columns - Mid | Final | Sessional (each: label + number input)
- **Bottom Row**: Credit dropdown | Total (auto-calculated, indigo highlight) | Grade badge | Delete icon
- Proper padding (20px), no squeezing, easy to type on mobile

#### 3.6 FAB
- "ADD COURSE" extended FAB
- Indigo background, white text
- Gradient shadow

#### 3.7 Empty State
- Centered layout
- Icon (large, muted)
- "No courses yet" heading
- "Tap + to add your first course" subtext

---

## 4. Widget Architecture

### New/Modified Widgets

| Widget | Status | Purpose |
|--------|--------|---------|
| `MeshGradientBackground` | Modify | Dark premium gradient with glow orbs |
| `GlassCard` | Modify | Updated glassmorphism recipe |
| `HeroGpaCard` | **New** | Circular progress + big number + stats |
| `CircularProgressRing` | **New** | Animated progress indicator |
| `MiniStatCard` | **New** | Small stat display (credits, count) |
| `ModeSelector` | Modify | Animated sliding indicator |
| `SemesterCard` | **New** | Semester row with GPA input |
| `CourseInputCard` | **New** | Card-based marks entry (replaces CourseRow) |
| `GradeBadge` | **New** | Colored grade pill |
| `EmptyState` | **New** | Empty state with illustration |
| `GradientButton` | Modify | Renamed from NeomorphicButton |

### Files to Modify

| File | Changes |
|------|---------|
| `lib/theme/app_theme.dart` | Complete rewrite - dark premium theme |
| `lib/widgets/mesh_gradient_background.dart` | Dark gradient + glow orbs |
| `lib/widgets/glass_card.dart` | Updated glassmorphism |
| `lib/widgets/bento_card.dart` | Remove or refactor to HeroGpaCard |
| `lib/widgets/semester_row.dart` | Refactor to SemesterCard |
| `lib/widgets/course_row.dart` | Refactor to CourseInputCard |
| `lib/widgets/neomorphic_button.dart` | Refactor to GradientButton |
| `lib/screens/home_screen.dart` | Complete rewrite |
| `lib/screens/marks_sheet_screen.dart` | Complete rewrite |
| `lib/screens/splash_screen.dart` | **New** - Animated splash screen |
| `lib/main.dart` | Minor - theme update, initial route to SplashScreen |

### New Files to Create

| File | Purpose |
|------|---------|
| `lib/widgets/hero_gpa_card.dart` | Hero CGPA display with progress ring |
| `lib/widgets/circular_progress_ring.dart` | Animated circular progress |
| `lib/widgets/mini_stat_card.dart` | Small stat card |
| `lib/widgets/mode_selector.dart` | Animated mode toggle |
| `lib/widgets/semester_card.dart` | CGPA semester row |
| `lib/widgets/course_input_card.dart` | Card-based marks entry |
| `lib/widgets/grade_badge.dart` | Colored grade indicator |
| `lib/widgets/empty_state.dart` | Empty state widget |
| `lib/widgets/gradient_button.dart` | Gradient action button |
| `lib/widgets/app_bar_widget.dart` | Reusable styled AppBar |

---

## 5. Animations & Micro-Interactions

| Interaction | Animation | Duration |
|-------------|-----------|----------|
| CGPA value change | Number counter animation | 400ms ease-out |
| Progress ring fill | Animated circular progress | 600ms ease-out |
| Mode switch | Sliding indicator | 250ms ease-in-out |
| Card appear | Fade in + slide up | 300ms |
| Card delete | Fade out + slide left | 200ms |
| Button press | Scale down to 0.95 | 100ms |
| Tab switch | Underline slide | 250ms |
| Semester add | Card slide in from bottom | 300ms |

### Haptic Feedback
- **Light impact**: Button taps, tab switches
- **Medium impact**: Adding courses/semesters
- **Heavy impact**: Deleting items
- **Selection click**: Dropdown selections

---

## 6. Empty States

### Home Screen (no data)
- Large icon (school/graduation cap)
- "No semesters yet" heading
- "Add your first semester to start calculating" subtext
- Prominent "ADD SEMESTER" button

### Marks Sheet (no courses)
- Large icon (notebook/pencil)
- "No courses yet" heading
- "Tap + to add your first course" subtext

---

## 7. Accessibility

- Minimum touch target: 48x48px
- Sufficient contrast ratios (white on dark background > 7:1)
- Semantic labels on interactive elements
- Haptic feedback for all interactions

---

## 8. Performance Considerations

- `RepaintBoundary` on expensive widgets (background, cards)
- `const` constructors where possible
- Minimal `setState` calls
- Lazy loading for long course lists
- `BackdropFilter` only on visible cards (use `useBlur` flag)

---

## 9. Splash Screen

### Design
- **Full-screen dark background** with animated gradient
- **Logo**: Centered, fades in with scale animation (0.8 → 1.0)
- **App Name**: "GPA CALCULATOR" fades in below logo with 200ms delay
- **Tagline**: "MCKRU University" fades in with 400ms delay
- **Loading indicator**: Subtle pulsing dot or shimmer line at bottom

### Animation Sequence (total ~2.5s)
1. **0-300ms**: Background gradient animates in
2. **300-700ms**: Logo scales up + fades in (spring animation)
3. **700-900ms**: App name fades in + slides up 10px
4. **900-1100ms**: Tagline fades in
5. **1100-2500ms**: Hold for branding
6. **2500ms**: Navigate to HomeScreen with fade transition

### Implementation
- New file: `lib/screens/splash_screen.dart`
- Use `AnimationController` with `TickerProviderStateMixin`
- `Navigator.pushReplacement` to HomeScreen after animation
- Skip splash if app was in background (optional enhancement)

### Assets Needed
- Use existing `assets/logo2.png`
- No new assets required

---

## 10. Enhanced Animations & Micro-Interactions

### Screen Transitions
| Transition | Animation | Duration |
|------------|-----------|----------|
| Splash → Home | Fade + slide up | 400ms |
| Home → Marks Sheet | Slide from right | 300ms |
| Marks Sheet → Home | Slide to right (pop) | 300ms |

### Element Animations
| Element | Animation | Timing |
|---------|-----------|--------|
| CGPA number | Count-up from 0 to value | 600ms ease-out |
| Progress ring | Stroke animation 0→value | 800ms ease-out with bounce |
| Cards appear | Fade in + slide up 20px | 350ms staggered (50ms delay each) |
| Cards delete | Fade out + scale down to 0.9 | 200ms |
| Mode switch | Sliding pill indicator | 250ms cubic-bezier(0.4, 0, 0.2, 1) |
| Tab indicator | Horizontal slide | 250ms ease-in-out |
| Button press | Scale to 0.95 → 1.0 | 150ms spring |
| Add course | New card slides in from bottom | 300ms spring |
| Grade change | Color transition + subtle pulse | 200ms |
| GPA value change | Number morphs (old → new) | 400ms |

### Staggered List Animations
- When screen loads, cards appear one by one with 50ms delay
- Uses `Interval` in `CurvedAnimation` for each card
- Creates a "waterfall" effect

### Hero Animations
- CGPA card number: `AnimatedSwitcher` with `FadeTransition` + `ScaleTransition`
- Grade badges: `AnimatedContainer` for color changes

### Shimmer Loading (Optional)
- While data loads from SharedPreferences
- Cards show shimmer placeholder effect
- Duration: until `loadFromLocal()` completes

---

## 11. Out of Scope (Phase 2)

- Data visualization charts (fl_chart)
- Export to PDF/image
- Dark/Light theme toggle
- Multi-language support
- Cloud sync
- Onboarding flow
