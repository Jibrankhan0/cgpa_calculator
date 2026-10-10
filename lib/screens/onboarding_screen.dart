import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String? _selectedAvatar;
  final _nameController = TextEditingController();

  static const List<_OnboardPage> _pages = [
    _OnboardPage(
      imagePath: 'assets/7df6461641d24e299654ce46c35f443a-removebg-preview.png',
      title: 'Track Your Grades',
      desc: 'Enter your marks for each subject and let us calculate your GPA automatically.',
    ),
    _OnboardPage(
      imagePath: 'assets/15735366125-removebg-preview.png',
      title: 'Calculate CGPA',
      desc: 'Add multiple semesters and track your cumulative GPA across all of them.',
    ),
    _OnboardPage(
      imagePath: 'assets/10873761682-removebg-preview.png',
      title: 'Save Everything',
      desc: 'Your data is saved locally. Come back anytime to check your progress!',
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  bool get _canFinish =>
      _selectedAvatar != null && _nameController.text.trim().isNotEmpty;

  void _finish() {
    final name = _nameController.text.trim();
    final avatar = _selectedAvatar;
    if (name.isEmpty || avatar == null) return;
    context.read<AppData>().finishOnboarding(name, avatar);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 3) return _buildNameStep();
    return _buildOnboardStep();
  }

  Widget _buildOnboardStep() {
    final p = Palette.of(context);
    final page = _pages[_step];
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                _AnimatedFloat(
                  child: UiCard(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Image.asset(
                        page.imagePath,
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.fg),
                ),
                const SizedBox(height: 10),
                Text(
                  page.desc,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: p.muted, height: 1.6),
                ),
                const SizedBox(height: 24),
                _buildDots(),
                const SizedBox(height: 32),
                PrimaryButton(label: 'Next →', expanded: true, onTap: _next),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    final p = Palette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              _AnimatedFloat(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.border),
                  ),
                  child: _selectedAvatar == null
                      ? const Center(child: Text('👋', style: TextStyle(fontSize: 72)))
                      : Padding(
                          padding: const EdgeInsets.all(18),
                          child: Image.asset(_selectedAvatar!, fit: BoxFit.contain),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "What's Your Name?",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.fg),
              ),
              const SizedBox(height: 10),
              Text(
                'Tell us who you are so we can personalize your experience.',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: p.muted, height: 1.6),
              ),
              const SizedBox(height: 32),
              _buildNameInput(),
              const SizedBox(height: 24),
              const FieldLabel(text: 'Pick an avatar'),
              const SizedBox(height: 10),
              _buildAvatarGrid(),
              const SizedBox(height: 28),
              _buildDots(),
              const SizedBox(height: 32),
              PrimaryButton(label: "Let's Go 🚀", expanded: true, onTap: _canFinish ? _finish : null),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(text: 'Your name'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          maxLength: 20,
          onChanged: (_) => setState(() {}),
          decoration: fieldInput(context, hint: 'Enter your name...'),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: p.fg),
        ),
      ],
    );
  }

  Widget _buildAvatarGrid() {
    final p = Palette.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: AppData.avatars.length,
      itemBuilder: (context, index) {
        final avatar = AppData.avatars[index];
        final isSelected = avatar == _selectedAvatar;
        return GestureDetector(
          onTap: () => setState(() => _selectedAvatar = avatar),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isSelected ? p.accentSoft : p.surface,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(
                color: isSelected ? p.accent : p.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(avatar, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDots() {
    final p = Palette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isActive = i == _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive ? p.accent : p.border,
          ),
        );
      }),
    );
  }
}

class _OnboardPage {
  final String imagePath;
  final String title;
  final String desc;

  const _OnboardPage({
    required this.imagePath,
    required this.title,
    required this.desc,
  });
}

class _AnimatedFloat extends StatefulWidget {
  final Widget child;
  const _AnimatedFloat({required this.child});

  @override
  State<_AnimatedFloat> createState() => _AnimatedFloatState();
}

class _AnimatedFloatState extends State<_AnimatedFloat> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = sin(_controller.value * 3.14159) * 12;
        return Transform.translate(offset: Offset(0, dy), child: widget.child);
      },
    );
  }
}
