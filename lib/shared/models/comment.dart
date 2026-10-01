import '../../core/utils/html_stripper.dart';

/// A user comment on a post. Mirrors `shared/models/comment.dart`.
class Comment {
  const Comment({
    required this.id,
    required this.author,
    required this.text,
    this.avatar,
    this.date,
    this.rating = 0,
  });

  final int id;
  final String author;
  final String text;
  final String? avatar;
  final String? date;
  final int rating;

  factory Comment.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    return Comment(
      id: asInt(json['id'] ?? json['comment_id']),
      author: '${json['author'] ?? json['name'] ?? json['user'] ?? 'Гость'}',
      text: HtmlStripper.strip(
        '${json['text'] ?? json['comment'] ?? json['content'] ?? ''}',
      ),
      avatar: (json['avatar'] ?? json['photo'])?.toString(),
      date: (json['date'] ?? json['created_at'])?.toString(),
      rating: asInt(json['rating'] ?? json['rate']),
    );
  }
}
