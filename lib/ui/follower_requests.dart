import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../models/user.dart';
import '../services/db.dart';
import '../utils/route_args.dart';

class FollowerRequestsView extends StatefulWidget {
  const FollowerRequestsView({Key? key}) : super(key: key);

  @override
  State<FollowerRequestsView> createState() => _FollowerRequestsViewState();
}

class _FollowerRequestsViewState extends State<FollowerRequestsView> {
  @override
  Widget build(BuildContext context) {
    AppUser user = Provider.of<UserProvider>(context).user!;
    DB db = DB();
    Future<List<AppUser>> getRequestedUsers = db.getFollowerRequests(user);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Follower Requests'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<AppUser>>(
        future: getRequestedUsers,
        builder: (BuildContext context, AsyncSnapshot<List<AppUser>> snapshot) {
          print(snapshot.data);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('You do not have follower requests'),
            );
          }
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You do not have follower requests'),
            );
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return userComponent(
                  context,
                  setState,
                  user: snapshot.data![index],
                  owningUser: user,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget userComponent(
    BuildContext context,
    void Function(void Function() fn) stateSetter, {
    required AppUser user,
    required AppUser owningUser,
  }) {
    DB db = DB();
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      user.profilePictureUrl ??
                          'https://upload.wikimedia.org/wikipedia/commons/8/89/Portrait_Placeholder.png',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      user.username,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              ],
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await db.approveRequest(
                      requestingUser: user,
                      owningUser: owningUser,
                    );
                    stateSetter(() {});
                  },
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Theme.of(context).errorColor,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await db.declineRequest(
                      requestingUser: user,
                      owningUser: owningUser,
                    );
                    stateSetter(() {});
                  },
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Theme.of(context).errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
