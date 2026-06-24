class ProfileRequest {
  final String field;
  final double gpa;
  final double budget;
  final String interests;
  final String careerGoals;
  final List<String> countries;

  ProfileRequest({
    required this.field,
    required this.gpa,
    required this.budget,
    required this.interests,
    required this.careerGoals,
    required this.countries,
  });

  factory ProfileRequest.fromJson(Map<String, dynamic> json) {
    return ProfileRequest(
      field: json['field_of_study'] as String? ?? '',
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0.0,
      budget: (json['budget'] as num?)?.toDouble() ?? 999999.0,
      interests: json['interests'] as String? ?? '',
      careerGoals: json['career_goals'] as String? ?? '',
      countries: (json['countries'] as List<dynamic>?)?.map((c) => c as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'gpa': gpa,
      'budget': budget,
      'interests': interests,
      'career_goals': careerGoals,
      'countries': countries,
    };
  }
}

