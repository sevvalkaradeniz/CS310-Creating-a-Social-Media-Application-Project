import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../logic/user_provider.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/db.dart';
import '../utils/screenSizes.dart';

class AddPostModalSheetView extends StatefulWidget {
  const AddPostModalSheetView({
    Key? key,
    required this.user,
    this.commentToPost,
  }) : super(key: key);
  final AppUser user;
  final Post? commentToPost;

  @override
  State<AddPostModalSheetView> createState() => _AddPostModalSheetViewState();
}

class _AddPostModalSheetViewState extends State<AddPostModalSheetView> {
  File? image;
  File? video;
  String postText = '';
  late VideoPlayerController _controller;
  final DB db = DB();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a new post'),
        centerTitle: false,
      ),
      body: SizedBox(
        width: screenWidth(context),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                width: screenWidth(context),
                child: TextFormField(
                  autofocus: true,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  maxLength: 255,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onChanged: (value) {
                    postText = value;
                  },
                ),
              ),
              if (image != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  width: screenWidth(context),
                  child: Image.file(
                    image!,
                  ),
                ),
              if (video != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  width: screenWidth(context),
                  child: _controller.value.isInitialized
                      ? Column(
                          children: [
                            AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: GestureDetector(
                                onDoubleTap: () {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                },
                                child: VideoPlayer(_controller),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text('Double tap the video to preview!')
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              const SizedBox(
                height: 12,
              ),
              Row(
                children: [
                  ClipOval(
                    child: Material(
                      color: Theme.of(context).primaryColor, // Button color
                      child: InkWell(
                        splashColor: Theme.of(context)
                            .bottomNavigationBarTheme
                            .unselectedItemColor, // Splash color
                        onTap: () async {
                          ImagePicker picker = ImagePicker();
                          XFile? pickedImage = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedImage != null) {
                            setState(() {
                              video = null;
                              image = File(pickedImage.path);
                            });
                          }
                        },
                        child: const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ClipOval(
                    child: Material(
                      color: Theme.of(context).primaryColor, // Button color
                      child: InkWell(
                        splashColor: Theme.of(context)
                            .bottomNavigationBarTheme
                            .unselectedItemColor, // Splash color
                        onTap: () async {
                          try {
                            ImagePicker picker = ImagePicker();
                            XFile? pickedVideo = await picker.pickVideo(
                                source: ImageSource.gallery,
                                maxDuration: const Duration(seconds: 120));
                            if (pickedVideo != null) {
                              VideoPlayerController testLengthController =
                                  VideoPlayerController.file(
                                File(pickedVideo.path),
                              );
                              await testLengthController.initialize();
                              if (testLengthController
                                      .value.duration.inSeconds >
                                  120) {
                                pickedVideo = null;
                                testLengthController.dispose();
                                throw ('We only allow videos that are shorter than 2 minutes!');
                              } else {
                                setState(() {
                                  image = null;
                                  video = File(pickedVideo!.path);
                                  _controller =
                                      VideoPlayerController.file(video!);
                                  _controller.initialize().then((_) {
                                    setState(() {});
                                  });
                                });
                              }
                            }
                          } catch (e) {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Center(
                                      child: Text(e.toString()),
                                    ),
                                  );
                                });
                            return;
                          }
                        },
                        child: const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.video_call_outlined,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Post toSend = Post(
            id: 'dummyid',
            text: postText,
            likedBy: [],
            comments: [],
            userId: widget.user.id,
            commentCount: 0,
            likeCount: 0,
            shareCount: 0,
          );
          if (widget.commentToPost != null) {
            toSend.commentToId = widget.commentToPost!.id;
            widget.commentToPost!.commentCount++;
          }
          Post sentPost = await db.addPost(toSend, widget.user, image, video);
          if (widget.commentToPost != null) {
            await db.increaseCommentCount(widget.commentToPost!);
          }
          Provider.of<UserProvider>(context, listen: false).addPost(sentPost);
          Navigator.pop(context);
        },
        child: const Text('post'),
      ),
    );
  }
}
