class GradeInfo {
  final int minMarks;
  final String letter;
  final double gpa;
  final int colorValue;

  const GradeInfo({
    required this.minMarks,
    required this.letter,
    required this.gpa,
    required this.colorValue,
  });
}

class GpaService {
  static const List<GradeInfo> gradeMap = [
    GradeInfo(minMarks: 85, letter: 'A', gpa: 4.0, colorValue: 0xFF22C55E),
    GradeInfo(minMarks: 80, letter: 'A-', gpa: 3.7, colorValue: 0xFF34C759),
    GradeInfo(minMarks: 75, letter: 'B+', gpa: 3.3, colorValue: 0xFF3B82F6),
    GradeInfo(minMarks: 70, letter: 'B', gpa: 3.0, colorValue: 0xFF06B6D4),
    GradeInfo(minMarks: 65, letter: 'B-', gpa: 2.7, colorValue: 0xFF8B5CF6),
    GradeInfo(minMarks: 61, letter: 'C+', gpa: 2.3, colorValue: 0xFFA855F7),
    GradeInfo(minMarks: 58, letter: 'C', gpa: 2.0, colorValue: 0xFFF59E0B),
    GradeInfo(minMarks: 55, letter: 'C-', gpa: 1.7, colorValue: 0xFFF97316),
    GradeInfo(minMarks: 50, letter: 'D', gpa: 1.0, colorValue: 0xFFEF4444),
    GradeInfo(minMarks: 0, letter: 'F', gpa: 0.0, colorValue: 0xFF6B7280),
  ];

  static GradeInfo? getGradeFromMarks(double marks) {
    if (marks.isNaN || marks < 0) return null;
    for (final g in gradeMap) {
      if (marks >= g.minMarks) return g;
    }
    return gradeMap.last;
  }

  static String getMotivationMessage(double? cgpa) {
    if (cgpa == null) return 'You got this! Start calculating your grades';
    if (cgpa >= 3.5) return "You're a superstar! Keep it up!";
    if (cgpa >= 3.0) return 'Great work! You are doing amazing!';
    if (cgpa >= 2.0) return 'Keep pushing! Every point counts!';
    return "Don't give up! You can improve!";
  }

  static String getGpaMessage(double gpa) {
    if (gpa >= 3.5) return 'Excellent!';
    if (gpa >= 3.0) return 'Good Job!';
    if (gpa >= 2.5) return 'Keep Going!';
    return 'You Can Do It!';
  }

  static String getSemesterStatus(double gpa) {
    if (gpa >= 3.5) return 'Excellent';
    if (gpa >= 3.0) return 'Good';
    if (gpa >= 2.0) return 'Average';
    return 'Keep Trying';
  }

  static String? validateMarks(String input, {bool isLab = false}) {
    if (input.isEmpty) return null;
    final v = double.tryParse(input);
    if (v == null) return 'Invalid number';
    if (v < 0) return 'Marks cannot be negative';
    if (isLab && v > 50) return 'Marks must be 0–50';
    if (!isLab && v > 100) return 'Marks must be 0–100';
    return null;
  }

  static String? validateGpaInput(String input) {
    if (input.isEmpty) return null;
    final v = double.tryParse(input);
    if (v == null) return 'Invalid number';
    if (v < 0) return 'GPA cannot be negative';
    if (v > 4) return 'GPA must be 0.00–4.00';
    return null;
  }
}
