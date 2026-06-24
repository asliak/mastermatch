class Program {
  final String university;
  final String program;
  final String country;
  final String city;
  final double tuition;
  final double minGpa;
  final double duration;
  final String fieldTags;
  final bool scholarship;
  final String deadline;
  final String url;
  final double score;
  final String explanation;
  bool isFavorited;

  Program({
    required this.university,
    required this.program,
    required this.country,
    required this.city,
    required this.tuition,
    required this.minGpa,
    required this.duration,
    required this.fieldTags,
    required this.scholarship,
    required this.deadline,
    required this.url,
    required this.score,
    required this.explanation,
    this.isFavorited = false,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      university: json['university'] as String,
      program: json['program'] as String,
      country: json['country'] as String,
      city: json['city'] as String,
      tuition: (json['tuition'] as num).toDouble(),
      minGpa: (json['min_gpa'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      fieldTags: json['field_tags'] as String,
      scholarship: json['scholarship'] as bool,
      deadline: json['deadline'] as String,
      url: json['url'] as String,
      score: (json['score'] as num? ?? 0.0).toDouble(),
      explanation: (json['explanation'] ?? json['description'] ?? '') as String,
      isFavorited: json['is_favorited'] as bool? ?? false,
    );
  }
}
