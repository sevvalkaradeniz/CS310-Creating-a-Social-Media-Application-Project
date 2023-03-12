import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class AppNotification {
  String id;
  String subjectId;
  String postId;
  String type; //"share" or "like" or "comment" or "followed"
  String targetId;

  AppNotification({
    required this.id,
    required this.subjectId,
    required this.type,
    required this.postId,
    required this.targetId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}
