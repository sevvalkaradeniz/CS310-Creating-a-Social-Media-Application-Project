import 'package:flutter/material.dart';

import '../models/user.dart';
import '../utils/route_args.dart';
import 'profile_view.dart';

class StandaloneProfileView extends StatefulWidget {
  const StandaloneProfileView({
    Key? key,
  }) : super(key: key);
  @override
  State<StandaloneProfileView> createState() => _StandaloneProfileViewState();
}

class _StandaloneProfileViewState extends State<StandaloneProfileView> {
  @override
  Widget build(BuildContext context) {
    final AppUser user = (ModalRoute.of(context)!.settings.arguments
            as StandaloneProfileViewArguments)
        .user!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ProfileView(
        user: user,
      ),
    );
  }
}
