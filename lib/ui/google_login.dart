import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../services/analytics.dart';
import '../utils/screenSizes.dart';

class GoogleLogin extends StatelessWidget {
  const GoogleLogin({Key? key}) : super(key: key);

  Future<void> _showDialog(
      String title, String message, BuildContext context) async {
    bool isAndroid = Platform.isAndroid;
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if (isAndroid) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text(message),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          } else {
            return CupertinoAlertDialog(
              title: Text(title, style: Theme.of(context).textTheme.labelLarge),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text(message,
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    AppAnalytics.setCurrentName('Login Screen');
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: screenWidth(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                onPressed: () async {
                  dynamic loginResult;
                  try {
                    loginResult =
                        await Provider.of<UserProvider>(context, listen: false)
                            .login();
                  } catch (e) {
                    _showDialog(
                      'Login Error',
                      'Could not login!',
                      context,
                    );
                    return;
                  }

                  if (loginResult == null) {
                    _showDialog(
                      'User not found!',
                      'Please sign-up first!',
                      context,
                    );
                  } else if (loginResult != 1) {
                    _showDialog(
                      'Login Error',
                      'Could not login!',
                      context,
                    );
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/appView',
                      (route) => false,
                    );
                  }
                },
                icon: const Image(
                  width: 24,
                  height: 24,
                  image: AssetImage('assets/google_logo.png'),
                ),
                label: const Text(
                  'Login with Google',
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                icon: const Icon(
                  Icons.email,
                ),
                label: const Text('Login with email and password'),
                onPressed: () {
                  Navigator.popAndPushNamed(context, '/login');
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.popAndPushNamed(context, '/googleSignup');
                },
                child: const Text('Don\'t have an account yet? Sign up!'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
