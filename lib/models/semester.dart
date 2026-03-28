import 'course.dart';

class Semester {
  final String id;
  final String name;
  final List<Course> courses;

  Semester({required this.id, required this.name, required this.courses});

  Semester copyWith({String? name, List<Course>? courses}) {
    return Semester(
      id: id,
      name: name ?? this.name,
      courses: courses ?? this.courses,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'courses': courses.map((x) => x.toJson()).toList(),
  };

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
    id: json['id'],
    name: json['name'],
    courses: List<Course>.from(json['courses'].map((x) => Course.fromJson(x))),
  );
}
