import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../services/analytics.dart';
import '../utils/dimensions.dart';
import '../utils/screenSizes.dart';
import '../utils/styles.dart';

class AddDetailsAfterSignUp extends StatefulWidget {
  const AddDetailsAfterSignUp({Key? key}) : super(key: key);

  @override
  State<AddDetailsAfterSignUp> createState() => _AddDetailsAfterSignUpState();
}

class _AddDetailsAfterSignUpState extends State<AddDetailsAfterSignUp> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String bio = '';

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
    AppAnalytics.setCurrentName('Add Details After Signup Screen');
    return Scaffold(
      body: Padding(
        padding: Dimen.regularParentPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Add more details about yourself',
                style: Theme.of(context).textTheme.headline4,
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
                          Icon(Icons.alternate_email),
                          SizedBox(width: 4),
                          Text('username'),
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
                        return 'Cannot leave username empty';
                      }
                    }
                    return null;
                  },
                  onSaved: (value) {
                    username = value ?? '';
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                width: screenWidth(context, dividedBy: 1.1),
                child: TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  maxLength: 255,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    label: SizedBox(
                      width: 150,
                      child: Row(
                        children: const [
                          Icon(Icons.account_box_outlined),
                          SizedBox(width: 4),
                          Text('bio'),
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
                  onSaved: (value) {
                    bio = value ?? '';
                  },
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    UserProvider provide = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    );
                    await provide.addBioAndUsername(
                      provide.user!.id,
                      bio,
                      username,
                    );
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/appView',
                      (route) => false,
                    ); //remove this line in the next step

                  } else {
                    _showDialog('Form Error', 'Your form is invalid', context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Continue',
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
