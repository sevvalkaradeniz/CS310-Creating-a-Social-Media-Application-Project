import 'package:json_annotation/json_annotation.dart';
import './user.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  String id;
  String text;
  String userId; //uid of of the user
  String? imageUrl;
  String? videoUrl;

  Address? location;
  List<Topic>? topics;

  List<String> likedBy; //list of uids that liked this post
  List<String>
      comments; //list of commentids that is a comment to this post (comment are also posts!!!!)
  //initially, both likedBy and comments are emptyl lists

  int shareCount = 0;
  int commentCount = 0;
  int likeCount = 0;

  String?
      commentToId; //if this post is a comment to another post, this id will be the id of the post that is commented with this post.

  DateTime createdAt = DateTime.now();
  AppUser? sharedBy;
  Post({
    required this.id,
    required this.text,
    required this.likedBy,
    required this.comments,
    required this.userId,
    this.imageUrl,
    this.videoUrl,
    this.location,
    this.topics,
    this.shareCount = 0,
    this.commentCount = 0,
    this.likeCount = 0,
    this.commentToId,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}
