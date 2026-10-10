# UI Redesign Prompt — MCKRU CGPA Calculator (Flutter)

Use this prompt with an AI designer/tool. It fully describes the current app so the UI can be redesigned **without changing any functionality, data, or navigation**.

---

## PROMPT START

You are redesigning the UI of an existing Flutter app. **Restyle only — do not change features, logic, data models, or navigation flow.**

### App Overview
- **Name:** MCKRU CGPA Calculator (v1.2.0) — a local-only (no backend) GPA/CGPA tracker for students.
- **Stack:** Flutter ^3.8.1, `provider` (state), `shared_preferences` (persistence), `flutter_svg`. Portrait only, light + dark mode.
- **Style today:** playful education app — orange/purple gradients, rounded cards (radius 20–28), emoji icons, staggered entrance animations, floating bottom nav.

### Navigation Structure (must not change)
```
SplashScreen (2.5s animated logo)
  ├─ first run → OnboardingScreen (4 steps: 3 feature slides + name/avatar step)
  └─ returning → MainShell
MainShell = TopBar (avatar + "Welcome back, {name}" + dark-mode toggle)
          + AnimatedSwitcher body
          + BottomNavBar (5 tabs)
Tabs: 0=Home · 1=GPA · 2=CGPA · 3=Storage · 4=Settings
Settings pushes: Grade Reference page, About page
Dialogs/bottom sheets: rename dialog, avatar picker, Clear All confirm, Reset All confirm
```

### Screens & Current Layout

**1. Splash** — full-screen orange gradient (F5844A→F9A05C→FBB87A), clouds, sparkles, sine-wave painter, centered logo (assets/logo2.png, elastic scale-in), title "CGPA Calculator", footer "Developed by Jibran Khan Dehpal".

**2. Onboarding** — 4 steps, white bg, floating illustration (280px, sine float anim), title (26/w900) + description, 4-dot pager (active = 32×10 gradient pill), gradient Next button. Step 4: name TextField (max 20 chars) + 4-column grid of 8 avatars (selected = purple border + glow) + "Let's Go 🚀".

**3. Home (dashboard)** — scrollable column of 6 staggered blocks:
   - Hero card (140px, gradient FFD9A0→FFC178, character.png, "YOUR CGPA" eyebrow, tagline, pill button "Add grades →" → switches to GPA tab)
   - Section header "Your record"
   - 2×2 stats grid: Avg GPA / Semesters / Subjects / Credits — each a colored card (statBlue, statPurple, statCoral, statGreen) with a white wave-pattern painter background
   - Motivation strip (message from GpaService.getMotivationMessage)
   - Section header "Quick actions"
   - 4 full-width quick-action cards (80px gradient + SVG icon + arrow): GPA calculator, CGPA tracker, Saved data, Settings — each jumps to its tab

**4. GPA Calculator** — gradient page header (orange→yellow, "GPA Calculator"), "+ Add Subject" pill, list of subject cards:
   - editable subject name, index badge, delete (min 1 subject)
   - marks TextField (0–100, or 0–50 if Lab), live inline validation error text, regex formatter
   - credit-hour selector 1–5 (tap targets) OR "Credit Hours: 1 (Lab)" when lab
   - Lab toggle (switch, sets credits=1)
   - live Grade & GPA chip (letter + GPA from grade table)
   - bottom result card: "✨ Semester GPA" big value + message (shown only when computable)
   - GPA = credit-weighted mean; lab marks are doubled before grade lookup

**5. CGPA Tracker** — same skeleton, purple theme: gradient header (purple→pink), "+ Add Semester", semester cards with editable name + GPA field (0.00–4.00, auto-inserts decimal point, live validation), status chip when valid (≥3.5 🌟 Excellent / ≥3.0 👍 Good / ≥2.0 📈 Average / else 💪 Keep Trying), result card "🏆 Cumulative CGPA" (mean of valid semester GPAs).

**6. Storage (Saved Data)** — gradient header (blue→cyan), red "🗑 Clear All" button (with confirm dialog). Read-only lists: GPA Records (grade-letter icon, subject name 🔬 if lab, "Marks: 85/100 · 3 cr", GPA value) and CGPA Records (S1 icon, semester name, GPA). Empty state: 📂 illustration + "No saved data yet…".

**7. Settings** — profile card (80px avatar in gradient ring → tap opens avatar-picker bottom sheet; name pill → rename dialog, max 20 chars), then settings rows: Dark Mode (animated ☀️/🌙 pill toggle), Grade Reference →, Reset All Data (confirm dialog), About →.
   - **Grade Reference page:** marks→letter→GPA table (colored letter pills) + lab note card.
   - **About page:** logo, "MCKRU CGPA Calculator", v1.2 badge, developer card (Jibran Khan Dehpal), app info rows, feature list.

### Data / State Contract (DO NOT MODIFY)
- **Provider `AppData`** (single ChangeNotifier):
  - Models: `GpaSubject {id, name, marks(String), credits(int 1–5), isLab}`, `SemesterGpa {id, name, gpa(String)}`
  - Getters: `gpaSubjects`, `semesters`, `isDark`, `hasSeenOnboarding`, `userName`, `userAvatar`, `avatars` (8 assets), `cgpa`, `semesterCount`, `subjectCount`, `totalCredits`
  - Methods: `load()`, `toggleDark()`, `finishOnboarding(name, avatar)`, `setUserName()`, `setUserAvatar()`, `addGpaSubject()`, `removeGpaSubject(i)`, `updateGpaSubject(i, s)`, `addSemester()`, `removeSemester(i)` (min 1, re-numbers names), `updateSemester(i, s)`, `clearAll()`, `resetAll()`
- **Persistence keys (never rename):** `mckru_gpa2`, `mckru_cgpa2`, `mckru_dark2`, `mckru_onboarded2`, `mckru_name`, `mckru_avatar` — JSON, 500ms debounced auto-save.
- **Service `GpaService`** (pure static): `gradeMap` (85+→A/4.0 … 0+→F/0.0 with fixed colors), `getGradeFromMarks()`, `getMotivationMessage()`, `getGpaMessage()`, `getSemesterStatus()`, `validateMarks(input, isLab)`, `validateGpaInput()`. All validation strings and messages shown in UI verbatim.
- **Rules:** lab = marks×2 and credits=1; subject credits 1–5; GPA = credit-weighted mean; CGPA = mean of semesters with GPA 0–4; empty input → no result card.

### Theme Tokens (current)
- Base: bg `#F5F5F5`, surface `#FFFFFF`, fg `#2D1B69`, muted `#8B7FAD`; accents orange `#FF8C42`, purple `#A855F7`, blue `#3B82F6`, green `#22C55E`, pink `#EC4899`, yellow `#F59E0B`, red `#EF4444`, cyan `#06B6D4`.
- Dark: bg `#12101E`, surface `#1E1A30`, surface2 `#261F3A`, fg `#E8E0FF`, muted `#7B6FA0`.
- Home pastel set: homeBg `#F4F5FA`, homeInk `#2B2E4A`, stat card pairs (blue/purple/coral/green).
- Fonts referenced: Nunito/Quicksand (not bundled — currently fallback).

### Reusable Components (keep or restyle, keep behavior)
`StaggeredAnimation` (entrance cascade), `BottomNavBar` (5 custom SVG icons, active = orange + pill + lift), dark-mode pill toggle, wave-pattern painter, avatar picker grid, rename dialog, `_PageHeader`, `_StatCard`, `_QuickCard`, `_SubjectCard`, `_SemesterCard`, `_StorageItem`, `_SettingsItem`, result cards, empty state.

### Hard Constraints for the Redesign
1. **Every user action must survive:** add/remove/edit subjects (name, marks + live validation, credits 1–5, lab toggle, grade chip, GPA result); add/remove/edit semesters (name, GPA + auto-decimal + validation, status chip, CGPA result); Clear All, Reset All, rename, avatar picker, dark toggle, Grade Reference, About, motivational message, onboarding flow, quick-action tab jumps.
2. Keep input formatters: marks `^\d{0,3}\.?\d{0,1}$`, GPA `^\d{0,2}\.?\d{0,2}$` + auto "." insertion after 2 digits.
3. Keep tab index mapping 0–4 and `onSwitchTab` behavior; every tab is a scroll view with ~95px bottom padding for the floating nav.
4. Keep dark mode working end-to-end (light + dark variants for every screen).
5. Stay within existing packages (`provider`, `shared_preferences`, `flutter_svg`) unless a new dep is explicitly justified.
6. Assets available: `assets/logo2.png`, `character.png`, `developer_avatar.png`, SVGs (graph, hat, star, book, graduation, folder, setting), 8 avatar PNGs, 3 onboarding PNGs.
7. Do not change `AppData`, `GpaService`, SharedPreferences keys, models, or calculation semantics.

### Your Task
Propose a complete visual redesign (color system, typography, spacing, component styles, per-screen layouts) that keeps 100% of the functionality and structure above. Deliver: (a) design token sheet (light + dark), (b) per-screen layout descriptions/mockups, (c) component specs (cards, buttons, inputs, chips, nav bar, dialogs).

## PROMPT END
