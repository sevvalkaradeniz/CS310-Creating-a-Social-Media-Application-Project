import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../models/user.dart';
import '../services/db.dart';
import '../utils/route_args.dart';

class ConnectedToMePage extends StatefulWidget {
  const ConnectedToMePage({
    Key? key,
    required this.user,
  }) : super(key: key);
  final AppUser user;
  @override
  State<ConnectedToMePage> createState() => _ConnectedToMePageState();
}

class _ConnectedToMePageState extends State<ConnectedToMePage> {
  @override
  Widget build(BuildContext context) {
    AppUser user = Provider.of<UserProvider>(context).user!;
    DB db = DB();
    Future<dynamic> getconnecteds() async {
      final connecteds = await db.getUsersConnectedToMeList(widget.user);
      final owningUsersConnecteds = await db.getUsersConnectedList(
        user,
      );
      return {
        'connectedToMes': connecteds,
        'owningUsersConnecteds': owningUsersConnecteds,
      };
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Connected To Me'),
        centerTitle: true,
      ),
      body: FutureBuilder<dynamic>(
        future: getconnecteds(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No one is connected to this user'),
            );
          }
          if (snapshot.data!['connectedToMes'] != null &&
              snapshot.data!['connectedToMes'].isEmpty) {
            return const Center(
              child: Text('No one is connected to this user'),
            );
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              itemCount: snapshot.data!['connectedToMes'].length,
              itemBuilder: (context, index) {
                return userComponent(
                  context,
                  setState,
                  user: snapshot.data!['connectedToMes'][index],
                  owningUsersConnecteds:
                      snapshot.data!['owningUsersConnecteds'],
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
    required List<AppUser> owningUsersConnecteds,
    required AppUser owningUser,
  }) {
    DB db = DB();
    bool isConnected =
        owningUsersConnecteds.any((element) => element.id == user.id);
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
            Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(50),
              ),
              child: MaterialButton(
                elevation: 0,
                color: isConnected ? const Color(0xFF6366F1) : Colors.white,
                onPressed: () async {
                  if (isConnected) {
                    await db.removeConnectionOfFrom(user, owningUser);
                  } else {
                    await db.addConnectionOfTo(user, owningUser);
                  }
                  stateSetter(() {});
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  isConnected ? 'Unconnect' : 'connect',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
