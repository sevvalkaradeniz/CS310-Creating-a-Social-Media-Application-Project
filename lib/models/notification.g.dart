// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      type: json['type'] as String,
      postId: json['postId'] as String,
      targetId: json['targetId'] as String,
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'postId': instance.postId,
      'type': instance.type,
      'targetId': instance.targetId,
    };
