import 'dart:io' show Platform;
import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../utils/dimensions.dart';
import '../utils/screenSizes.dart';
import '../utils/styles.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();

  static const String routeName = '/login';
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String pass = '';

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: Dimen.regularParentPadding,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  width: screenWidth(context, dividedBy: 1.1),
                  child: TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      label: SizedBox(
                        width: 100,
                        child: Row(
                          children: const [
                            Icon(Icons.email),
                            SizedBox(width: 4),
                            Text('Email'),
                          ],
                        ),
                      ),
                      fillColor:
                          Theme.of(context).textSelectionTheme.selectionColor,
                      filled: true,
                      labelStyle: kBoldLabelStyle,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    validator: (value) {
                      if (value != null) {
                        if (value.isEmpty) {
                          return 'Cannot leave e-mail empty';
                        }
                        if (!EmailValidator.validate(value)) {
                          return 'Please enter a valid e-mail address';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) {
                      email = value ?? '';
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  width: screenWidth(context, dividedBy: 1.1),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      label: SizedBox(
                        width: 150,
                        child: Row(
                          children: const [
                            Icon(Icons.password),
                            SizedBox(width: 4),
                            Text('Password'),
                          ],
                        ),
                      ),
                      fillColor:
                          Theme.of(context).textSelectionTheme.selectionColor,
                      filled: true,
                      labelStyle: kBoldLabelStyle,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    validator: (value) {
                      if (value != null) {
                        if (value.isEmpty) {
                          return 'Cannot leave password empty';
                        }
                        if (value.length < 6) {
                          return 'Password too short';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) {
                      pass = value ?? '';
                    },
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      dynamic loginResult;
                      try {
                        loginResult = await Provider.of<UserProvider>(context,
                                listen: false)
                            .loginWithoutGoogle(email, pass);
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
                    } else {
                      _showDialog(
                        'Form Error',
                        'Your form is invalid',
                        context,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Login',
                      style: kButtonLightTextStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
