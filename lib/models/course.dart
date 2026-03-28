class Course {
  final String id;
  final String name;
  final double creditHours;
  final String grade;
  final bool isPractical;
  final double midMarks;
  final double finalMarks;
  final double sessionalMarks;
  final double totalMarks;

  Course({
    required this.id,
    required this.name,
    required this.creditHours,
    required this.grade,
    this.isPractical = false,
    this.midMarks = 0,
    this.finalMarks = 0,
    this.sessionalMarks = 0,
    this.totalMarks = 0,
  });

  Course copyWith({
    String? name,
    double? creditHours,
    String? grade,
    bool? isPractical,
    double? midMarks,
    double? finalMarks,
    double? sessionalMarks,
    double? totalMarks,
  }) {
    return Course(
      id: id,
      name: name ?? this.name,
      creditHours: creditHours ?? this.creditHours,
      grade: grade ?? this.grade,
      isPractical: isPractical ?? this.isPractical,
      midMarks: midMarks ?? this.midMarks,
      finalMarks: finalMarks ?? this.finalMarks,
      sessionalMarks: sessionalMarks ?? this.sessionalMarks,
      totalMarks: totalMarks ?? this.totalMarks,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'creditHours': creditHours,
    'grade': grade,
    'isPractical': isPractical,
    'midMarks': midMarks,
    'finalMarks': finalMarks,
    'sessionalMarks': sessionalMarks,
    'totalMarks': totalMarks,
  };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'],
    name: json['name'],
    creditHours: json['creditHours'].toDouble(),
    grade: json['grade'],
    isPractical: json['isPractical'] ?? false,
    midMarks: (json['midMarks'] ?? 0).toDouble(),
    finalMarks: (json['finalMarks'] ?? 0).toDouble(),
    sessionalMarks: (json['sessionalMarks'] ?? 0).toDouble(),
    totalMarks: (json['totalMarks'] ?? 0).toDouble(),
  );
}
