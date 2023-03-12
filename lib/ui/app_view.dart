import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../logic/user_provider.dart';

import 'feed.dart';
import 'notifications_view.dart';
import 'profile_view.dart';
import 'search.dart';

class AppView extends StatefulWidget {
  const AppView({Key? key}) : super(key: key);
  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  int _selectedIndex = 0;

  static late List<Widget> _pages;

  @override
  void initState() {
    _pages = <Widget>[
      const FeedView(),
      const SearchView(),
      const NotificationView(),
      const ProfileView(),
    ];
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SUConnect'),
        actions: [
          if (_selectedIndex == 2)
            TextButton(
              child: const Text(
                'See Follower Requests',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/followerRequests',
                );
              },
            ),
          if (_selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () async {
                await Provider.of<UserProvider>(context, listen: false)
                    .logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                );
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor:
            Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor:
            Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
      ),
    );
  }
}
