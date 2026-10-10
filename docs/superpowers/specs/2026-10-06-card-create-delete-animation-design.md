# Design: Card Create/Delete Animation (Slide & Fade)

**Date:** 2026-10-06
**Status:** Approved (demo option A; approach A — `AnimatedCardFrame` wrapper)
**Scope:** GPA subject cards + CGPA semester cards. All interactive lists in the app (verified: only these two have per-item create/delete).

## Problem

- **Create:** a new card's entrance today comes only from `StaggeredAnimation`, whose per-index delay (50 ms × index) clamps to zero animation for index ≥ 7 — so new cards often pop in with no motion, and when they do animate it's an elastic scale, not the chosen style.
- **Delete:** `🗑` calls the provider directly — the card vanishes instantly, no exit animation.

Chosen look (live demo, option A): **create = height grow + slide down (−14px) + fade in; delete = slide right (+48px) + fade + height collapse**, siblings shifting smoothly.

## Design

### 1. New widget: `AnimatedCardFrame` (`lib/widgets/animated_card_frame.dart`)

Pure Flutter — `AnimationController` + `Align(heightFactor:)`; no new dependencies. (An `AnimationController` is required instead of a `TweenAnimationBuilder` because the exit must support `reverse()`.)

```dart
AnimatedCardFrame({
  required Widget child,
  bool animateEnter = false,   // true only for the just-created card
  bool exiting = false,        // parent flips true to start exit
  VoidCallback? onExitComplete, // called after exit animation finishes
})
```

- **Enter** (~300 ms, `Curves.easeOut`): `heightFactor 0→1` + `translateY −14→0` + `opacity 0→1`. Runs only when `animateEnter` is true at mount; otherwise renders statically.
- **Exit** (~280 ms, `Curves.easeOut`): `heightFactor 1→0` + `translateX 0→+48` + `opacity 1→0`; when the controller finishes → `onExitComplete()`.
- The child stays mounted for the whole exit (its data is still in the provider), so nothing unmounts mid-animation.

### 2. Delete flow (same in both pages)

1. `🗑` tap → set local `_exitId` (by subject/semester **id**, immune to index shifts). Guard: only one exit in flight per list — other `🗑` taps ignored while `_exitId != null`.
2. Card renders `AnimatedCardFrame(exiting: true)` → animates out in place.
3. `onExitComplete` → `provider.remove…(indexOf(id))` → then clear `_exitId`.
4. Provider removal happens when the card's height is already 0 → no layout jump.

`canDelete` (list length > 1) rules stay as-is; the guard applies only when `canDelete`.

### 3. Create flow

- `Add subject` / `Add semester` buttons live in `main_shell.dart` and mutate the provider directly; pages rebuild via `context.watch`.
- `GpaPage` / `CgpaPage` become `StatefulWidget`s. They keep a `_knownIds` set (seeded in `initState` from current data → page-load cards get **no** enter animation). On rebuild, a new id → `_enterId = id`, and a ~400 ms timer clears it (`setState`).
- The card with `_enterId` gets `AnimatedCardFrame(animateEnter: true)`.
- Cards keep their existing uniform wrapper `StaggeredAnimation(index: i, child: AnimatedCardFrame(...))` — page-load entrance (constraint: `StaggeredAnimation` usage unchanged) simply runs concurrently with the new card's enter frame; no conditional re-wrapping, no double-mount.

### 4. Integration map (verified against code)

| List | Create | Delete | Animate |
|---|---|---|---|
| GPA page — subject cards (`gpa_page.dart`) | `main_shell` "Add subject" | `🗑` → `removeGpaSubject` | ✅ enter + exit |
| CGPA page — semester cards (`cgpa_page.dart`) | `main_shell` "Add semester" | `🗑` → `removeSemester` | ✅ enter + exit |
| Storage page rows | derived view, nothing creates rows | no per-row delete (only "Clear All" dialog) | ❌ none |
| Home / Settings / ResultCard | not item lists | — | ❌ none |

Correction vs. early discussion: the CGPA page has **only semester cards** (name + GPA input each) — there are no nested per-semester subject lists; subjects exist solely on the GPA page.

### 5. Constraints (unchanged)

- `app_data.dart`, `gpa_service.dart`, `main.dart`, `staggered_animation.dart` — do not modify.
- Validation messages, formatters, prefs keys, tabs, splash — untouched.
- Dependencies stay: provider, shared_preferences, flutter_svg, google_fonts.
- Existing `_SubjectCard`/`_SemesterCard` controllers unaffected (card remains mounted during exit; `didUpdateWidget` already syncs).

### 6. Tests (`test/widget_test.dart`)

New test (GPA tab):

1. Pre-seeded onboarded prefs → open app → GPA tab.
2. Tap `Add subject` → pump past enter duration → subject card count increased.
3. Tap a `🗑` → pump past exit duration (~400 ms) → subject count back down (guard: ensure ≥ 2 subjects first).

Existing 2 tests unaffected (they never add/delete; `find.text('Add subject')` still matches the shell button).

## Error handling

Exit completion always fires (controller completes deterministically); `_exitId` cleared in the callback. If a provider update rebuilds during exit, the id-based flags still resolve to the same card.

## Out of scope

- Storage page (no per-item operations), ResultCard appearance changes, Home/Settings.
- Redesigning the delete confirmation (there is none today; none added).
- Touching `StaggeredAnimation` internals.
