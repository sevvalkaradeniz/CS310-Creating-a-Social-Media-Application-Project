// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Connection _$ConnectionFromJson(Map<String, dynamic> json) => Connection(
      id: json['id'] as String,
      subject: json['subject'] as String,
      target: json['target'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$ConnectionToJson(Connection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subject': instance.subject,
      'target': instance.target,
      'type': instance.type,
    };
