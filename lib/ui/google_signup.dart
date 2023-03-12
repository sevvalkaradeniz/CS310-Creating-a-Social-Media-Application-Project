import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../services/analytics.dart';
import '../utils/screenSizes.dart';

class GoogleSignup extends StatelessWidget {
  const GoogleSignup({Key? key}) : super(key: key);

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
                  Text(message, style: Theme.of(context).textTheme.labelMedium),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    AppAnalytics.setCurrentName('Signup Screen');
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
                  var signupResult =
                      await Provider.of<UserProvider>(context, listen: false)
                          .signup();
                  if (signupResult != 1) {
                    if (signupResult is String) {
                      _showDialog(
                        'Account already exists!',
                        signupResult,
                        context,
                      );
                    } else {
                      _showDialog(
                        'Signup Error',
                        'Could not signup!',
                        context,
                      );
                    }
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/addDetailsAfterSignup',
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
                  'Signup with Google',
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
                  size: 24,
                ),
                label: const Text('Signup with email and password'),
                onPressed: () {
                  Navigator.popAndPushNamed(context, '/signup');
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.popAndPushNamed(context, '/googleLogin');
                },
                child: const Text('Already have an account? Log in!'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
