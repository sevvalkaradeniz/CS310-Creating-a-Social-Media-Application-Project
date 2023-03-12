import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './utils/colors.dart';
import 'logic/user_provider.dart';
import 'models/user.dart';
import 'services/db.dart';
import 'ui/add_details_after_signup.dart';
import 'ui/app_view.dart';
import 'ui/edit_profile.dart';
import 'ui/google_login.dart';
import 'ui/google_signup.dart';
import 'ui/login.dart';
import 'ui/notifications_view.dart';
import 'ui/profile_view.dart';
import 'ui/profile_with_scaffold.dart';
import 'ui/signup.dart';
import 'ui/single_post_view.dart';
import 'ui/walkthrough.dart';
import 'ui/welcome.dart';
import 'ui/follower_requests.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  bool welcomeShownBefore = prefs.getBool('walkthroughShown') ?? false;
  String? storedUserStr = prefs.getString('user');
  AppUser? storedUser = storedUserStr != null
      ? AppUser.fromJson(jsonDecode(storedUserStr))
      : null;
  await Firebase.initializeApp();
  AppUser? updatedStoredUser;
  if (storedUser != null) {
    //if there is a stored user get the latest data of the user
    DB db = DB();
    updatedStoredUser = await db.getUser(storedUser.id);
    await prefs.setString('user', jsonEncode(updatedStoredUser!.toJson()));
  }

  runApp(
    MyApp(
      welcomeShownBefore: welcomeShownBefore,
      storedUser: updatedStoredUser,
    ),
  );
}

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({Key? key}) : super(key: key);

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Duration _duration;
  late Tween<double> _tween;

  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _tween = Tween(begin: 0.25, end: 1.0);
    _duration = const Duration(milliseconds: 1500);
    _animationController = AnimationController(
      vsync: this,
      duration: _duration,
    );
    final CurvedAnimation curve = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    _animation = _tween.animate(curve);
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: const Image(
            image: AssetImage('assets/SUConnect-logos_transparent.png'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({Key? key, required this.message}) : super(key: key);
  final String message;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(message),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp(
      {required this.storedUser, required this.welcomeShownBefore, Key? key})
      : super(key: key);
  final bool welcomeShownBefore;
  final AppUser? storedUser;

  @override
  Widget build(BuildContext context) {
    return errorlessApp(storedUser);
  }

  Widget errorlessApp(AppUser? storedUser) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(storedUser),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SUConnect',
        theme: AppThemes.lightTheme,
        routes: {
          '/appView': (context) => const AppView(),
          '/welcome': (context) => const Welcome(),
          '/signup': (context) => const SignUp(),
          '/login': (context) => const Login(),
          '/profile': (context) => const ProfileView(),
          '/editProfile': (context) => const EditProfile(),
          '/notificationView': (context) => const NotificationView(),
          '/singlePostView': (context) => const SinglePostView(),
          '/standaloneProfileView': (context) => const StandaloneProfileView(),
          '/googleLogin': (context) => const GoogleLogin(),
          '/googleSignup': (context) => const GoogleSignup(),
          '/addDetailsAfterSignup': (context) => const AddDetailsAfterSignUp(),
          '/followerRequests': (context) => const FollowerRequestsView(),
        },
        home: welcomeShownBefore == false
            ? const WalkThrough()
            : const AuthenticationStatus(),
      ),
    );
  }
}

class AuthenticationStatus extends StatefulWidget {
  const AuthenticationStatus({Key? key}) : super(key: key);
  @override
  State<AuthenticationStatus> createState() => _AuthenticationStatusState();
}

class _AuthenticationStatusState extends State<AuthenticationStatus> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.user == null) {
          return const Welcome();
        } else {
          return const AppView();
        }
      },
    );
  }
}
