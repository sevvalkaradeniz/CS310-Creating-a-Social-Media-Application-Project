import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class Geo {
  String lat;
  String lng;

  Geo({required this.lat, required this.lng});

  factory Geo.fromJson(Map<String, dynamic> json) => _$GeoFromJson(json);
  Map<String, dynamic> toJson() => _$GeoToJson(this);
}

@JsonSerializable()
class Address {
  String street;
  String city;
  String suite;
  String zipcode;
  Geo geo;

  Address({
    required this.street,
    required this.city,
    required this.suite,
    required this.zipcode,
    required this.geo,
  });

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable()
class Topic {
  String topicName;
  String id;

  Topic({
    required this.topicName,
    required this.id,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
  Map<String, dynamic> toJson() => _$TopicToJson(this);
}

@JsonSerializable()
class AppUser {
  String id;
  String name;
  String username;
  String email;

  String? profilePictureUrl;
  String? bio;

  @JsonKey(defaultValue: false)
  bool deactivated = false;

  bool publicAccount;

  List<Address> subscribedLocations = [];

  List<Topic> subscribedTopics = [];

  List<String> posts =
      []; //this will be existing in data motel but not in database and will be populated when needed

  List<String> sharedPosts = []; //ids of shared posts

  List<String> bookmarkedPosts =
      []; //this is is a list of post ids that are bookmarked by the user

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.profilePictureUrl,
    required this.deactivated,
    required this.publicAccount,
    required this.subscribedLocations,
    required this.subscribedTopics,
    this.bio,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? profilePictureUrl,
    String? bio,
    bool? deactivated,
    bool? publicAccount,
    List<Address>? subscribedLocations,
    List<Topic>? subscribedTopics,
    List<String>? posts,
    List<String>? sharedPosts,
    List<String>? bookmarkedPosts,
  }) {
    AppUser internalUser = AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      deactivated: deactivated ?? this.deactivated,
      publicAccount: publicAccount ?? this.publicAccount,
      subscribedTopics: subscribedTopics ?? this.subscribedTopics,
      subscribedLocations: subscribedLocations ?? this.subscribedLocations,
    );
    internalUser.posts = posts ?? this.posts;
    internalUser.sharedPosts = sharedPosts ?? this.sharedPosts;
    internalUser.bookmarkedPosts = bookmarkedPosts ?? this.bookmarkedPosts;
    return internalUser;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);
}
