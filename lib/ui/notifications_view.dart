import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../models/notification.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/analytics.dart';
import '../services/db.dart';
import '../utils/route_args.dart';
import '../utils/screenSizes.dart';
import '../utils/styles.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  const NotificationCard({
    Key? key,
    required this.notification,
    required this.db,
  }) : super(key: key);
  final DB db;
  @override
  Widget build(BuildContext context) {
    Future<dynamic> getUserAndPost() async {
      return {
        'user': await db.getUser(notification.subjectId),
        'post': await db.getPost(notification.postId),
      };
    }

    return FutureBuilder(
      future: getUserAndPost(),
      builder: (BuildContext buildContext, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          Post post = snapshot.data['post'];
          AppUser subjectUser = snapshot.data['user'];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/singlePostView',
                arguments: SinglePostViewArguments(
                  post: post,
                ),
              );
            },
            child: Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/standaloneProfileView',
                          arguments: StandaloneProfileViewArguments(
                            user: subjectUser,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              subjectUser.profilePictureUrl ??
                                  'https://upload.wikimedia.org/wikipedia/commons/8/89/Portrait_Placeholder.png',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subjectUser.name + ' @' + subjectUser.username,
                            style: kLabelStyle,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      notification.type == 'reshare'
                          ? 'reshared your tweet: '
                          : 'liked your tweet: ',
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      post.text,
                    )
                  ],
                ),
              ),
            ),
          );
        }
        return const Text('x');
      },
    );
  }
}

class NotificationView extends StatefulWidget {
  const NotificationView({Key? key}) : super(key: key);

  @override
  State<NotificationView> createState() => NotificationViewState();
}

class NotificationViewState extends State<NotificationView> {
  @override
  Widget build(BuildContext context) {
    AppAnalytics.setCurrentName('Notifications Screen');
    final DB db = DB();
    AppUser user = Provider.of<UserProvider>(context, listen: false).user!;
    Future<List<AppNotification>?> notifications = db.getNotifications(user);
    return FutureBuilder<List<AppNotification>?>(
      future: notifications,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<AppNotification>?> snapshot,
      ) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unexpected Error'),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: screenHeight(context),
            width: screenWidth(context),
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

        if (snapshot.data == null ||
            (snapshot.data != null && snapshot.data!.isEmpty)) {
          return const Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'You do not have any notifications yet!',
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            itemBuilder: ((context, index) => NotificationCard(
                  notification: snapshot.data![index],
                  db: db,
                )),
            itemCount: snapshot.data!.length,
          ),
        );
      },
    );
  }
}
