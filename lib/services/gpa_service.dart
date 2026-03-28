class GpaService {
  static const Map<String, double> gradePoints = {
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'C-': 1.7,
    'D': 1.0,
    'F': 0.0,
  };

  static List<String> get grades => gradePoints.keys.toList();

  static double getPoints(String grade) => gradePoints[grade] ?? 0.0;

  static String getGradeFromMarks(double marks, {bool isPractical = false}) {
    final effectiveMarks = isPractical ? marks * 2 : marks;
    if (effectiveMarks >= 85) return 'A';
    if (effectiveMarks >= 80) return 'A-';
    if (effectiveMarks >= 75) return 'B+';
    if (effectiveMarks >= 70) return 'B';
    if (effectiveMarks >= 65) return 'B-';
    if (effectiveMarks >= 61) return 'C+';
    if (effectiveMarks >= 58) return 'C';
    if (effectiveMarks >= 55) return 'C-';
    if (effectiveMarks >= 50) return 'D';
    return 'F';
  }

  static double getRepresentativeMarks(
    String grade, {
    bool isPractical = false,
  }) {
    double marks = 0.0;
    switch (grade) {
      case 'A':
        marks = 85.0;
        break;
      case 'A-':
        marks = 80.0;
        break;
      case 'B+':
        marks = 75.0;
        break;
      case 'B':
        marks = 70.0;
        break;
      case 'B-':
        marks = 65.0;
        break;
      case 'C+':
        marks = 61.0;
        break;
      case 'C':
        marks = 58.0;
        break;
      case 'C-':
        marks = 55.0;
        break;
      case 'D':
        marks = 50.0;
        break;
      case 'F':
        marks = 0.0;
        break;
      default:
        marks = 0.0;
    }
    return isPractical ? marks / 2 : marks;
  }
}
