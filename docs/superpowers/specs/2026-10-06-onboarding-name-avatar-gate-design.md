# Design: First-time Name/Avatar Gate + Live Avatar Preview

**Date:** 2026-10-06
**Status:** Approved (approach A, user-confirmed)
**Scope:** Onboarding enforcement only — no routing or storage changes.

## Problem

Onboarding already ends with a name + avatar step, but entry is not enforced:

- Empty name silently falls back to `'Student'` in `_finish()`.
- Avatar is pre-selected (`_selectedAvatar = 'assets/B1-removebg-preview.png'`), so the user can enter the app without actively choosing either.

## Requirement

The first-time user must **explicitly provide a name and pick an avatar** before the app lets them in. The chosen avatar must be previewed live in the large circle at the top of the name step (currently the 👋 emoji).

## Design

### 1. `lib/screens/onboarding_screen.dart`

- `_selectedAvatar` becomes `String?` and starts as `null` (no default avatar).
- Name-step preview circle (160×160, accentSoft, border):
  - avatar selected → `Image.asset(_selectedAvatar!, fit: BoxFit.contain, padding: EdgeInsets.all(18))` inside the circle;
  - no selection → keep the current 👋 placeholder.
  - Tapping a grid tile updates the circle immediately (existing `setState` already rebuilds).
- Name `TextField` gets `onChanged: (_) => setState(() {})` so the button state reacts while typing.
- "Let's Go 🚀" button: `onTap` is non-null only when `name.trim().isNotEmpty && _selectedAvatar != null`, otherwise `null` (disabled).
- `_finish()`:
  - guard: `if (name.isEmpty || avatar == null) return;`
  - remove the `'Student'` fallback; call `finishOnboarding(name.trim(), avatar!)`.

### 2. `lib/widgets/ui.dart` — `PrimaryButton`

- When `onTap == null`, wrap the button in `Opacity(opacity: 0.45)`.
- `InkWell(onTap: null)` is already non-tappable; no other behavior changes.
- All existing `PrimaryButton` call sites pass `onTap`, so no visual regressions expected (verify by grep during implementation).

### 3. Untouched (hard constraints)

- `lib/providers/app_data.dart` (do-not-modify) — `finishOnboarding`, prefs keys (`mckru_name`, `mckru_avatar`, `mckru_onboarded2`) unchanged.
- Splash routing (`hasSeenOnboarding`), flow order (3 feature pages → name step), Settings profile editing.

### 4. Test (`test/widget_test.dart`)

New widget test:

1. Fresh prefs → pump `MyApp` → advance splash → tap "Next →" ×3.
2. On name step: tap "Let's Go 🚀" → expect still on name step (no MainShell).
3. Type a name, tap an avatar tile, tap "Let's Go 🚀" → expect MainShell entered (e.g. `find.textContaining('Welcome back')`).

Existing 2 tests remain valid (they never reach the name step / pre-seed onboarded prefs).

## Error handling

No error UI: the disabled button is the affordance. The `_finish()` guard is defense-in-depth only.

## Out of scope

- Routing-level enforcement for old installs where the onboarded flag is set without a name (approach C — explicitly not chosen).
- Settings avatar/name editing flows.
