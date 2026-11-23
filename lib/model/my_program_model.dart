class MyProgram {
  final int id;
  final String title;
  final String? assignedDate;
  final String status;

  const MyProgram({
    required this.id,
    required this.title,
    required this.assignedDate,
    required this.status,
  });

  factory MyProgram.fromJson(Map<String, dynamic> json) {
    final rawDate = json['assign_date']?.toString();
    return MyProgram(
      id: int.tryParse(json['routine_id']?.toString() ?? '') ??
          int.tryParse(json['id']?.toString() ?? '') ??
          0,
      title: (json['routine_title']?.toString().trim().isNotEmpty ?? false)
          ? json['routine_title'].toString()
          : 'Workout program',
      assignedDate: rawDate?.isEmpty == true ? null : rawDate?.split('T').first,
      status: json['status']?.toString() ?? '',
    );
  }
}
