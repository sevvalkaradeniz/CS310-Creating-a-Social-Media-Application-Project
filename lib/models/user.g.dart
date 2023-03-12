// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Geo _$GeoFromJson(Map<String, dynamic> json) => Geo(
      lat: json['lat'] as String,
      lng: json['lng'] as String,
    );

Map<String, dynamic> _$GeoToJson(Geo instance) => <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
    };

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
      street: json['street'] as String,
      city: json['city'] as String,
      suite: json['suite'] as String,
      zipcode: json['zipcode'] as String,
      geo: Geo.fromJson(json['geo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
      'street': instance.street,
      'city': instance.city,
      'suite': instance.suite,
      'zipcode': instance.zipcode,
      'geo': instance.geo,
    };

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
      topicName: json['topicName'] as String,
      id: json['id'] as String,
    );

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
      'topicName': instance.topicName,
      'id': instance.id,
    };

AppUser _$AppUserFromJson(Map<String, dynamic> json) => AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      deactivated: json['deactivated'] as bool? ?? false,
      publicAccount: json['publicAccount'] as bool,
      subscribedLocations: (json['subscribedLocations'] as List<dynamic>)
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscribedTopics: (json['subscribedTopics'] as List<dynamic>)
          .map((e) => Topic.fromJson(e as Map<String, dynamic>))
          .toList(),
      bio: json['bio'] as String?,
    )
      ..posts =
          (json['posts'] as List<dynamic>).map((e) => e as String).toList()
      ..sharedPosts = (json['sharedPosts'] as List<dynamic>)
          .map((e) => e as String)
          .toList()
      ..bookmarkedPosts = (json['bookmarkedPosts'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'email': instance.email,
      'profilePictureUrl': instance.profilePictureUrl,
      'bio': instance.bio,
      'deactivated': instance.deactivated,
      'publicAccount': instance.publicAccount,
      'subscribedLocations': instance.subscribedLocations,
      'subscribedTopics': instance.subscribedTopics,
      'posts': instance.posts,
      'sharedPosts': instance.sharedPosts,
      'bookmarkedPosts': instance.bookmarkedPosts,
    };
