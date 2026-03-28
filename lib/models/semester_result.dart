class SemesterResult {
  final String id;
  final String name;
  final double creditHours;
  final double gpa;

  SemesterResult({
    required this.id,
    required this.name,
    required this.creditHours,
    required this.gpa,
  });

  SemesterResult copyWith({String? name, double? creditHours, double? gpa}) {
    return SemesterResult(
      id: id,
      name: name ?? this.name,
      creditHours: creditHours ?? this.creditHours,
      gpa: gpa ?? this.gpa,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'creditHours': creditHours,
    'gpa': gpa,
  };

  factory SemesterResult.fromJson(Map<String, dynamic> json) => SemesterResult(
    id: json['id'],
    name: json['name'],
    creditHours: json['creditHours'].toDouble(),
    gpa: json['gpa'].toDouble(),
  );
}
