import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';

import '../logic/user_provider.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/db.dart';
import '../utils/route_args.dart';
import '../utils/screenSizes.dart';
import 'add_post_modal_sheeet_view.dart';
import 'post_video_player.dart';

typedef PostAndUserToVoid = Future<void> Function(Post, AppUser);

class PostCard extends StatefulWidget {
  final Post post;
  final PostAndUserToVoid incrementLike;
  final String? sharedBy;
  const PostCard({
    Key? key,
    required this.post,
    required this.incrementLike,
    this.sharedBy,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    DB db = DB();
    AppUser currentUser =
        Provider.of<UserProvider>(context, listen: false).user!;
    Future<AppUser?> postsUser = db.getUser(widget.post.userId);
    Duration differenceFromNow =
        DateTime.now().difference(widget.post.createdAt);
    return FutureBuilder<AppUser?>(
      future: postsUser,
      builder: (BuildContext context, AsyncSnapshot<AppUser?> snap) {
        if (snap.hasError) {
          return const Center(
            child: Text('Error occured while loading post!'),
          );
        }
        if (snap.hasData) {
          AppUser postUser = snap.data!;
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/singlePostView',
                arguments: SinglePostViewArguments(
                  post: widget.post,
                ),
              );
            },
            child: Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.fromLTRB(5, 3, 5, 3),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.post.sharedBy != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Text(
                            'reshared by @${widget.post.sharedBy!.username}'),
                      ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/standaloneProfileView',
                          arguments: StandaloneProfileViewArguments(
                            user: postUser,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              postUser.profilePictureUrl ??
                                  'https://image.winudf.com/v2/image1/Y29tLmZpcmV3aGVlbC5ibGFja3NjcmVlbl9zY3JlZW5fMF8xNTgyNjgwMjgzXzA2MQ/screen-0.jpg?fakeurl=1&type=.jpg',
                            ),
                            radius: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                postUser.name,
                                style: Theme.of(context).textTheme.bodyText1,
                              ),
                              Text(
                                '@${postUser.username}',
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Text(
                            differenceFromNow.inSeconds > 60
                                ? differenceFromNow.inMinutes > 60
                                    ? differenceFromNow.inHours > 24
                                        ? '· ${differenceFromNow.inDays} d'
                                        : '· ${differenceFromNow.inHours} h'
                                    : '· ${differenceFromNow.inMinutes} m'
                                : '· ${differenceFromNow.inSeconds} s',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.post.text,
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    if (widget.post.imageUrl != null)
                      _postImageView(context, widget.post),
                    if (widget.post.videoUrl != null)
                      PostVideoPlayer(
                        videoUrl: widget.post.videoUrl!,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => AddPostModalSheetView(
                                  user: currentUser,
                                  commentToPost: widget.post,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.black,
                              size: 20,
                            ),
                            label: Text(
                              widget.post.commentCount.toString(),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            label: Text(
                              widget.post.shareCount.toString(),
                            ),
                            onPressed: () async {
                              if (currentUser.sharedPosts
                                  .contains(widget.post.id)) {
                                await db.removeShare(widget.post, currentUser);
                              } else {
                                await db.resharePost(widget.post, currentUser);
                              }
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.repeat,
                              color: currentUser.sharedPosts
                                      .contains(widget.post.id)
                                  ? Colors.green
                                  : Colors.black,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async => await widget.incrementLike(
                                widget.post, currentUser),
                            icon: Icon(
                              widget.post.likedBy.contains(currentUser.id)
                                  ? Icons.star_rate_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.yellow.shade800,
                              size: 20,
                            ),
                            label: Text(
                              widget.post.likeCount.toString(),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.share,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _postImageView(BuildContext context, Post post) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, _, __) => Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: PhotoView(
                imageProvider: NetworkImage(post.imageUrl!),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 1.1,
              ),
            ),
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Image.network(
          post.imageUrl!,
          height: screenHeight(context, dividedBy: 4),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
