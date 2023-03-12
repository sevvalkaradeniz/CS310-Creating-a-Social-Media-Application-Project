import 'dart:io' show Platform;
import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../utils/dimensions.dart';
import '../utils/screenSizes.dart';
import '../utils/styles.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();

  static const String routeName = '/signup';
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String pass = '';
  String fullname = '';

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
    return Scaffold(
      body: Padding(
        padding: Dimen.regularParentPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
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
              Container(
                padding: const EdgeInsets.all(8),
                width: screenWidth(context, dividedBy: 1.1),
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    label: SizedBox(
                      width: 150,
                      child: Row(
                        children: const [
                          Icon(Icons.person_outline),
                          SizedBox(width: 4),
                          Text('Full Name'),
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
                        return 'Cannot leave Name empty';
                      }
                    }
                    return null;
                  },
                  onSaved: (value) {
                    fullname = value ?? '';
                  },
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final signUpResut = await Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).signUpWithoutGoogle(email, pass, fullname);
                    if (signUpResut != 1) {
                      if (signUpResut is String) {
                        _showDialog(
                          'Account already exists!',
                          signUpResut,
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
                  } else {
                    _showDialog('Form Error', 'Your form is invalid', context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Sign Up',
                    style: kButtonLightTextStyle,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
