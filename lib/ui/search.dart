import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/analytics.dart';
import '../services/db.dart';
import '../utils/route_args.dart';
import 'post_card.dart';

class SearchView extends StatefulWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late String searchTerm;
  late List<Post>? filteredPosts;
  late List<AppUser>? filteredUsers;
  bool loading = false;

  @override
  initState() {
    super.initState();
    searchTerm = '';
    filteredPosts = [];
    filteredUsers = [];
  }

  void onSearchChange(String value) {
    setState(() {
      searchTerm = value;
    });
  }

  Future<void> onSearch() async {
    setState(() {
      loading = true;
    });
    final DB db = DB();
    dynamic searchedResults = await db.searchPostsAndUsers(searchTerm);
    setState(() {
      filteredUsers = searchedResults['users'];
      filteredPosts = searchedResults['posts'];
      loading = false;
    });
  }

  Widget _searchIcon() {
    return IconButton(
        onPressed: onSearch,
        icon: const Padding(
          padding: EdgeInsets.all(14.0),
          child: Icon(Icons.search),
        ));
  }

  Widget _searchInput() {
    return Form(
      child: Column(
        children: [
          TextFormField(
            initialValue: searchTerm,
            onChanged: onSearchChange,
          ),
        ],
      ),
    );
  }

  Future<void> incrementLike(Post post, AppUser user) async {
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

  @override
  Widget build(BuildContext context) {
    AppAnalytics.setCurrentName('Search Screen');
    return loading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _searchInput(),
                      ),
                      _searchIcon()
                    ],
                  ),
                ),
                if (filteredUsers != null && filteredUsers!.isNotEmpty)
                  ...usersView(context),
                if (filteredPosts != null && filteredPosts!.isNotEmpty)
                  ...postsView(context),
              ],
            ),
          );
  }

  List<Widget> postsView(BuildContext context) {
    return [
      const Divider(
        thickness: 2,
      ),
      const Text('Found posts'),
      const Divider(
        thickness: 2,
      ),
      ...filteredPosts!.map((post) {
        return PostCard(
          post: post,
          incrementLike: incrementLike,
        );
      }).toList(),
    ];
  }

  List<Widget> usersView(BuildContext context) {
    return [
      const Divider(
        thickness: 2,
      ),
      const Text('Found users'),
      const Divider(
        thickness: 2,
      ),
      ...filteredUsers!.map((AppUser user) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/standaloneProfileView',
              arguments: StandaloneProfileViewArguments(
                user: user,
              ),
            );
          },
          child: Card(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      user.profilePictureUrl ??
                          'https://image.winudf.com/v2/image1/Y29tLmZpcmV3aGVlbC5ibGFja3NjcmVlbl9zY3JlZW5fMF8xNTgyNjgwMjgzXzA2MQ/screen-0.jpg?fakeurl=1&type=.jpg',
                    ),
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '@${user.username}',
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ];
  }
}
