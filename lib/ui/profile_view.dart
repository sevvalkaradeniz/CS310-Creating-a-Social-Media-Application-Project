import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:project310/ui/posts_tab.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/analytics.dart';
import '../services/db.dart';
import '../utils/screenSizes.dart';
import 'connected_to.dart';
import 'connected_to_me.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    Key? key,
    this.user,
  }) : super(key: key);

  final AppUser? user;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with TickerProviderStateMixin {
  Future<void> incrementLikes(Post post, AppUser user) async {
    final DB db = DB();
    if (post.likedBy.any((element) => element == user.id)) {
      db.decrementLike(post, user);
      setState(() {
        post.likeCount--;
        post.likedBy.remove(user.id);
      });
    } else {
      db.incrementLike(post, user);
      setState(() {
        post.likeCount++;
        post.likedBy.add(user.id);
      });
    }
  }

  late TabController _controller;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    AppAnalytics.setCurrentName('Profile Screen');
    return Consumer<UserProvider>(
      builder: (consumerContext, userProvider, child) {
        final bool ownUser = widget.user == null ||
            (widget.user != null && widget.user!.id == userProvider.user!.id);
        final AppUser user = ownUser ? userProvider.user! : widget.user!;
        final DB db = DB();
        Future<dynamic> getUserPosts =
            db.getUserPosts(user, userProvider.user!);
        return FutureBuilder(
          future: getUserPosts,
          builder: (BuildContext buildContext, AsyncSnapshot snapshot) {
            if (snapshot.hasError) {
              print(snapshot.error);
              return const Center(
                child: Text('Unexpected Error'),
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: screenHeight(buildContext),
                width: screenWidth(buildContext),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    ),
                    Text('Loading..'),
                  ],
                ),
              );
            }

            List<dynamic> tempAll = snapshot.data!['all'];
            bool isFollowing = snapshot.data!['following'];

            bool private = false;
            bool requested = false;
            List<Post> all = [];
            if (tempAll.isNotEmpty &&
                tempAll[0] is String &&
                tempAll[0] == 'requested') {
              //means this is a private account that we cannot see
              requested = true;
              private = true;
            } else if (tempAll.isNotEmpty &&
                tempAll[0] is String &&
                tempAll[0] == 'uCantCMe') {
              private = true;
            } else {
              all = tempAll as List<Post>;
            }

            List<Post> liked = private ? [] : snapshot.data!['liked'];
            List<Post> media = private ? [] : snapshot.data!['media'];
            List<Post> location = private ? [] : snapshot.data!['location'];
            return _profileView(
              user,
              ownUser,
              all,
              media,
              location,
              liked,
              private,
              requested,
              isFollowing,
              setState,
            );
          },
        );
      },
    );
  }

  SafeArea _profileView(
    AppUser user,
    bool ownUser,
    List<Post> userPosts,
    List<Post> mediaPosts,
    List<Post> locationPosts,
    List<Post> likedPosts,
    bool private,
    bool requested,
    bool isFollowing,
    void Function(void Function() fn) stateSetter,
  ) {
    print('private ' + private.toString());
    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: false,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    userDetailsColumnWidget(
                      user,
                      ownUser,
                      private,
                      requested,
                      isFollowing,
                      stateSetter,
                    ),
                  ],
                ),
              ),
              expandedHeight: 310.0,
              bottom: TabBar(
                controller: _controller,
                labelColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(
                    text: 'Posts',
                  ),
                  Tab(
                    text: 'Locations',
                  ),
                  Tab(
                    text: 'Media',
                  ),
                  Tab(
                    text: 'Likes',
                  ),
                ],
              ),
            )
          ];
        },
        body: TabBarView(
          controller: _controller,
          children: private
              ? const [
                  Center(
                    child: Text('This user\'s account is private.'),
                  ),
                  Center(
                    child: Text('This user\'s account is private.'),
                  ),
                  Center(
                    child: Text('This user\'s account is private.'),
                  ),
                  Center(
                    child: Text('This user\'s account is private.'),
                  ),
                ]
              : [
                  PostsTab(
                    posts: userPosts,
                    incrementLikes: incrementLikes,
                    stateSetter: setState,
                  ),
                  PostsTab(
                    posts: locationPosts,
                    incrementLikes: incrementLikes,
                    stateSetter: setState,
                  ),
                  PostsTab(
                    posts: mediaPosts,
                    incrementLikes: incrementLikes,
                    stateSetter: setState,
                  ),
                  PostsTab(
                    posts: likedPosts,
                    incrementLikes: incrementLikes,
                    stateSetter: setState,
                  ),
                ],
        ),
      ),
    );
  }

  Widget userDetailsColumnWidget(
    AppUser user,
    bool ownUser,
    bool private,
    bool requested,
    bool isFollowing,
    void Function(void Function() fn) stateSetter,
  ) {
    DB db = DB();
    Future<List<int>> connectedCounts = db.getConnectedCounts(user);
    return FutureBuilder<List<int>>(
      future: connectedCounts,
      initialData: const [0, 0],
      builder: (BuildContext context, AsyncSnapshot<List<int>> snap) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (user.profilePictureUrl != null) {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 250),
                            pageBuilder: (context, _, __) => Scaffold(
                              extendBodyBehindAppBar: true,
                              appBar: AppBar(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                              ),
                              body: Center(
                                child: PhotoView(
                                  imageProvider:
                                      NetworkImage(user.profilePictureUrl!),
                                  minScale: PhotoViewComputedScale.contained,
                                  maxScale:
                                      PhotoViewComputedScale.covered * 1.1,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(
                          user.profilePictureUrl ??
                              'https://upload.wikimedia.org/wikipedia/commons/8/89/Portrait_Placeholder.png',
                        ),
                        radius: 45,
                      ),
                    ),
                  ),
                  ownUser
                      ? OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/editProfile');
                          },
                          child: const Text('Edit Profile'),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            AppUser viewingUser = Provider.of<UserProvider>(
                              context,
                              listen: false,
                            ).user!;
                            if (isFollowing) {
                              await db.removeConnectionOfFrom(
                                user,
                                viewingUser,
                              );
                            } else {
                              await db.addConnectionOfTo(
                                user,
                                viewingUser,
                              );
                            }

                            stateSetter(() {});
                          },
                          child: Text(
                            isFollowing
                                ? 'Unconnect'
                                : requested
                                    ? 'requested'
                                    : 'Connect',
                          ),
                        ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text('@${user.username}'),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(user.bio == null ? '' : '${user.bio}'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      snap.data![0].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConnectedToMePage(
                              user: user,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Connected To Me',
                        style: Theme.of(context).textTheme.bodyText2!.copyWith(
                              fontSize: 15,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      snap.data![1].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConnectedToPage(
                              user: user,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Connected To',
                        style: Theme.of(context).textTheme.bodyText2!.copyWith(
                              fontSize: 15,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


/*

NestedScrollView(
            // controller: _scrollController,
            headerSliverBuilder: (BuildContext context, bool boxIsScrolled) {
              return <Widget>[
                getAppbar(),
                authstate.isbusy
                    ? _emptyBox()
                    : SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          child: authstate.isbusy
                              ? const SizedBox.shrink()
                              : UserNameRowWidget(
                                  user: authstate.profileUserModel,
                                  isMyProfile: isMyProfile,
                                ),
                        ),
                      ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Container(
                        color: TwitterColor.white,
                        child: TabBar(
                          indicator: TabIndicator(),
                          controller: _tabController,
                          tabs: const <Widget>[
                            Text("Tweets"),
                            Text("Tweets & replies"),
                            Text("Media")
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                /// Display all independent tweers list
                _tweetList(context, authstate, list, false, false),

                /// Display all reply tweet list
                _tweetList(context, authstate, list, true, false),

                /// Display all reply and comments tweet list
                _tweetList(context, authstate, list, false, true)
              ],
            ),
          ),

*/
/** 
 SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircleAvatar(
                          backgroundColor: Colors.black,
                          child: ClipOval(
                            child: Image.network(
                              user.profilePictureUrl ?? 'empty',
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          radius: 45,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/editProfile');
                        },
                        child: const Text('Edit Profile'),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 0, 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text('@${user.username}'),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(user.bio == null ? '' : '${user.bio}\n'),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Text(
                                  '0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Following',
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Followers',
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Posts'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Posts&Replies'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Media'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Likes'),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Colors.black12,
                    thickness: 4.0,
                    height: 15,
                  ),
                  Column(
                    children: [
                      TabBar(
                        controller: _controller,
                        tabs: const [
                          Tab(
                            text: 'Posts',
                          ),
                          Tab(
                            text: 'Posts & Replies',
                          ),
                          Tab(
                            text: 'Media',
                          ),
                          Tab(
                            text: 'Likess',
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            PostsTab(
                              posts: posts,
                              incrementLikes: incrementLikes,
                              deletePost: deletePost,
                              user: user,
                            ),
                            PostsTab(
                              posts: posts,
                              incrementLikes: incrementLikes,
                              deletePost: deletePost,
                              user: user,
                            ),
                            PostsTab(
                              posts: posts,
                              incrementLikes: incrementLikes,
                              deletePost: deletePost,
                              user: user,
                            ),
                            PostsTab(
                              posts: posts,
                              incrementLikes: incrementLikes,
                              deletePost: deletePost,
                              user: user,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
*/