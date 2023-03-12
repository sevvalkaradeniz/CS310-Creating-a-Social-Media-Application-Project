import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../logic/user_provider.dart';
import '../models/user.dart';
import '../services/analytics.dart';
import '../services/db.dart';
import '../utils/screenSizes.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  static const routeName = '/editPage';

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();

  void showChangePicture(AppUser user, DB db, UserProvider userProvider) {
    bool loading = false;
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (loading)
                const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text(
                    'Please while profile picture is updating!',
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Select new profile picture'),
                onTap: () async {
                  ImagePicker picker = ImagePicker();
                  XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    loading = true;
                    await userProvider.updateUserProfilePicture(image);
                  }
                  loading = false;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Remove Profile Picture'),
                onTap: () async {
                  await userProvider.removeProfilePicture();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  Future<void> _showDialog(
    String title,
    String message,
    BuildContext context, {
    bool? deactivate,
    bool? delete,
  }) async {
    bool isAndroid = Platform.isAndroid;
    Future<void> deactivateAccount() async {
      await Provider.of<UserProvider>(context).deactivate();
    }

    Future<void> deleteAccount() async {
      await Provider.of<UserProvider>(context).delete();
    }

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
                  onPressed: () async {
                    if (deactivate != null) {
                      await deactivateAccount();
                    } else if (delete != null) {
                      await deleteAccount();
                    }

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome',
                      (route) => false,
                    );
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
                    Text(
                      message,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/welcome', (route) => false);
                  },
                ),
              ],
            );
          }
        });
  }

  String name = '';
  String bio = '';
  String email = '';
  late bool publicAccount;

  @override
  Widget build(BuildContext context) {
    AppAnalytics.setCurrentName('Edit Profile Screen');
    final DB db = DB();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final AppUser user = userProvider.user!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      showChangePicture(user, db, userProvider);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                      child: Center(
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            user.profilePictureUrl ??
                                'https://upload.wikimedia.org/wikipedia/commons/8/89/Portrait_Placeholder.png',
                          ),
                          radius: 45,
                        ),
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                          width: screenWidth(context, dividedBy: 1.2),
                          child: TextFormField(
                              initialValue: user.name,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                label: Row(
                                  children: const [
                                    Text('Name'),
                                  ],
                                ),
                                labelStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white12,
                                  ),
                                ),
                              ),
                              onSaved: (value) {
                                name = value ?? user.name;
                              }),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                          width: screenWidth(context, dividedBy: 1.2),
                          child: TextFormField(
                            initialValue: user.bio,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              label: Row(
                                children: const [
                                  Text('Bio'),
                                ],
                              ),
                              labelStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white12,
                                ),
                              ),
                            ),
                            onSaved: (value) {
                              bio = value ?? user.bio ?? '';
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                          width: screenWidth(context, dividedBy: 1.2),
                          child: TextFormField(
                            initialValue: user.email,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              label: Row(
                                children: const [
                                  Text('E-Mail'),
                                ],
                              ),
                              labelStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white12,
                                ),
                              ),
                            ),
                            onSaved: (value) {
                              email = value ?? user.email;
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                          width: screenWidth(context, dividedBy: 1.2),
                          child: FormField(
                            initialValue: user.publicAccount,
                            onSaved: (value) {
                              publicAccount = value as bool;
                            },
                            builder: (FormFieldState<bool> field) {
                              return SwitchListTile(
                                title: const Text('Public Account'),
                                value: field.value!,
                                onChanged: (val) {
                                  field.didChange(val);
                                },
                              );
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                              child: OutlinedButton(
                                onPressed: () {
                                  _showDialog(
                                    'Delete Account',
                                    'All the user related data and everything will be deleted! THIS CANNOT BE UNDONE! Are you sure?',
                                    context,
                                    delete: true,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  child: Text(
                                    'Delete Account',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                              child: OutlinedButton(
                                onPressed: () {
                                  _showDialog(
                                    'Deactivate Account',
                                    'People will not be able to see any content related to this account when you deactivate. The account will be reactivated next time you log in.',
                                    context,
                                    deactivate: true,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  child: Text(
                                    'Deactivate Account',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                    'Cancel',
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white70,
                                )),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () async {
                                _formKey.currentState!.save();
                                await userProvider.updateUser(
                                  user.copyWith(
                                    name: name,
                                    bio: bio,
                                    email: email,
                                    publicAccount: publicAccount,
                                  ),
                                );
                                Navigator.pop(context);
                                //Navigator.push(context, MaterialPageRoute(builder:(context)=>ProfileView( )));
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  'Save',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
