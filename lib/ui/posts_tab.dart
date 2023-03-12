import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/user.dart';
import 'post_card.dart';

typedef PostAndUserToVoid = Future<void> Function(Post, AppUser);

class PostsTab extends StatelessWidget {
  const PostsTab({
    Key? key,
    required this.posts,
    required this.incrementLikes,
    required this.stateSetter,
  }) : super(key: key);
  final List<Post> posts;
  final PostAndUserToVoid incrementLikes;
  final void Function(void Function() fn) stateSetter;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        stateSetter(() {});
      },
      child: ListView(
        children: posts
            .map(
              (post) => PostCard(
                post: post,
                incrementLike: incrementLikes,
              ),
            )
            .toList(),
      ),
    );
  }
}
