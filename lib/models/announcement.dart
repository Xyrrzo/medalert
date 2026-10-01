class Announcement {
  final int id;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        category: json['category'],
        createdAt: DateTime.parse(json['created_at']),
      );
}