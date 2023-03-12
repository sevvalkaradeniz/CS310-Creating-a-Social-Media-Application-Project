import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/connection.dart';
import '../models/notification.dart';
import '../models/post.dart';
import '../models/user.dart';
import 'cloud_storage.dart';

class DB {
  Future<void> saveUser(AppUser user) async {
    CollectionReference ref = FirebaseFirestore.instance.collection('users');
    await ref.doc(user.id).set(user.toJson());
  }

  Future<AppUser?> getUser(String id) async {
    final ref = FirebaseFirestore.instance.collection('users');
    final snapshot = await ref.doc(id).get();
    if (snapshot.exists) {
      return AppUser.fromJson(snapshot.data() as Map<String, dynamic>);
    } else {
      return null;
    }
  }

  Future<void> updateUserBioAndUserName(
      String id, String? bio, String username) async {
    final ref = FirebaseFirestore.instance.collection('users');
    await ref.doc(id).update({
      'username': username,
      'bio': bio,
    });
  }

  Future<List<Post>?> getFeed(AppUser user) async {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    final usersRef = FirebaseFirestore.instance.collection('users');
    final connectionRef = FirebaseFirestore.instance.collection('connections');
    late QuerySnapshot<Map<String, dynamic>> followedUsersResult;
    try {
      followedUsersResult = await connectionRef
          .where('subject', isEqualTo: user.id)
          .where('type', isEqualTo: 'connected')
          .get();
    } catch (e) {
      return null;
    }
    List<String> followedUserIds = followedUsersResult.docs
        .map((document) => document.data()['target'] as String)
        .toList();
    late QuerySnapshot<Map<String, dynamic>> getPostsUsersResult;
    List<List<String>?> arrayChunks = [];
    for (var i = 0; i < followedUserIds.length; i += 10) {
      arrayChunks.add(
        followedUserIds.sublist(
          i,
          i + 10 < followedUserIds.length ? i + 10 : followedUserIds.length,
        ),
      );
    }
    List<Post> feedPosts = [];
    try {
      for (var i = 0; i < arrayChunks.length; i++) {
        getPostsUsersResult =
            await postsRef.where('userId', whereIn: arrayChunks[i]).get();
        feedPosts.addAll(getPostsUsersResult.docs
            .map((document) => Post.fromJson(document.data()))
            .toList());
      }
    } catch (e) {
      return null;
    }
    List<Post> sharedPosts = [];
    for (var i = 0; i < followedUserIds.length; i++) {
      try {
        AppUser sharingUser = AppUser.fromJson(
            (await usersRef.doc(followedUserIds[i]).get()).data()!);
        List<String> sharedPostIds = sharingUser.sharedPosts;
        if (sharedPostIds.isNotEmpty) {
          for (final id in sharedPostIds) {
            Post temp = Post.fromJson(
              (await postsRef.doc(id).get()).data()!,
            );
            temp.sharedBy = sharingUser;
            sharedPosts.add(temp);
          }
        }
      } catch (e) {
        return null;
      }
    }

    late QuerySnapshot<Map<String, dynamic>> getUsersPostsResult;
    AppUser fromDb = AppUser.fromJson(
      (await usersRef.doc(user.id).get()).data()!,
    );
    List<List<String>?> userPostsArrayChunk = [];
    for (var i = 0; i < fromDb.posts.length; i += 10) {
      userPostsArrayChunk.add(
        fromDb.posts.sublist(
          i,
          i + 10 < fromDb.posts.length ? i + 10 : fromDb.posts.length,
        ),
      );
    }
    List<Post> userPosts = [];
    try {
      for (var i = 0; i < userPostsArrayChunk.length; i++) {
        getUsersPostsResult =
            await postsRef.where('id', whereIn: userPostsArrayChunk[i]).get();
        userPosts.addAll(getUsersPostsResult.docs
            .map((document) => Post.fromJson(document.data()))
            .toList());
      }
    } catch (e) {
      return null;
    }

    List<Post> returnList = [...feedPosts, ...sharedPosts, ...userPosts];
    returnList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return returnList;
  }

  Future<Post> addPost(
      Post post, AppUser user, File? image, File? video) async {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    final usersRef = FirebaseFirestore.instance.collection('users');
    post.id = postsRef.doc().id;

    String? url;
    if (image != null) {
      CloudStorage store = CloudStorage();
      url = await store.addMediaOfPost(post.id, image);
      post.imageUrl = url;
    }
    if (video != null) {
      CloudStorage store = CloudStorage();
      url = await store.addMediaOfPost(post.id, video);
      post.videoUrl = url;
    }
    await usersRef.doc(user.id).update({
      'posts': FieldValue.arrayUnion([post.id])
    });
    await postsRef.doc(post.id).set(post.toJson());

    return post;
  }

  Future<void> incrementLike(Post post, AppUser user) async {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    await postsRef.doc(post.id).update({
      'likedBy': FieldValue.arrayUnion([user.id]),
      'likeCount': FieldValue.increment(1),
    });
    final notificationsRef =
        FirebaseFirestore.instance.collection('notifications');
    DocumentReference<Map<String, dynamic>> tempDoc = notificationsRef.doc();
    AppNotification temp = AppNotification(
      id: tempDoc.id,
      subjectId: user.id,
      targetId: post.userId,
      postId: post.id,
      type: 'like',
    );
    await notificationsRef.doc(temp.id).set(temp.toJson());
  }

  Future<void> decrementLike(Post post, AppUser user) async {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    await postsRef.doc(post.id).update({
      'likedBy': FieldValue.arrayRemove([user.id]),
      'likeCount': FieldValue.increment(-1),
    });
    final notificationsRef =
        FirebaseFirestore.instance.collection('notifications');
    String docIdToRemove = (await notificationsRef
            .where('subjectId', isEqualTo: user.id)
            .where(
              'postId',
              isEqualTo: post.id,
            )
            .get())
        .docs[0]
        .data()['id'];
    await notificationsRef.doc(docIdToRemove).delete();
  }

  Future<dynamic> searchPostsAndUsers(String searchTerm) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final postsRef = FirebaseFirestore.instance.collection('posts');
    QuerySnapshot<Map<String, dynamic>> usernameresults = await usersRef
        .where('username', isGreaterThanOrEqualTo: searchTerm)
        .where('username', isLessThan: searchTerm + 'z')
        .get();
    List<AppUser> userReturner = [];
    userReturner.addAll(
      usernameresults.docs.map(
        (e) => AppUser.fromJson(e.data()),
      ),
    );
    QuerySnapshot<Map<String, dynamic>> userfullnameresults = await usersRef
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThan: searchTerm + 'z')
        .get();
    userReturner.addAll(
      userfullnameresults.docs.map(
        (e) => AppUser.fromJson(e.data()),
      ),
    );
    List<AppUser> userReturnerWithoutDuplicate = [];
    for (final user in userReturner) {
      if (!userReturnerWithoutDuplicate
          .any((element) => element.id == user.id)) {
        userReturnerWithoutDuplicate.add(user);
      }
    }
    List<Post> postReturner = [];
    QuerySnapshot<Map<String, dynamic>> postresults = await postsRef.get();
    postReturner.addAll(
      postresults.docs.map(
        (e) => Post.fromJson(e.data()),
      ),
    );
    postReturner = postReturner
        .where(
          (e) => e.text.contains(searchTerm),
        )
        .toList();
    postReturner.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return {
      'users': userReturnerWithoutDuplicate,
      'posts': postReturner,
    };
  }

  Future<List<AppNotification>?> getNotifications(AppUser user) async {
    final notificationsRef =
        FirebaseFirestore.instance.collection('notifications');
    QuerySnapshot<Map<String, dynamic>> snap =
        await notificationsRef.where('targetId', isEqualTo: user.id).get();
    return snap.docs
        .map(
          (doc) => AppNotification.fromJson(doc.data()),
        )
        .toList();
  }

  Future<Post> getPost(String id) async {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    return Post.fromJson(
      (await postsRef.doc(id).get()).data()!,
    );
  }

  Future<dynamic> getUserPosts(AppUser user, AppUser viewingUser) async {
    final isPrivateAccount = (await getUser(user.id))!.publicAccount == false;
    bool following = false;
    bool isOwnProfile = user.id == viewingUser.id;

    final connectionRef = FirebaseFirestore.instance.collection('connections');
    final connectionBetween = await connectionRef
        .where('subject', isEqualTo: viewingUser.id)
        .where('target', isEqualTo: user.id)
        .get();

    if (!isOwnProfile) {
      if (connectionBetween.docs.isEmpty) {
        //means that the viewing user is not connnected to the user that is being shown

        if (isPrivateAccount) {
          return {
            'liked': [],
            'media': [],
            'location': [],
            'all': ['uCantCMe'],
            'following': false,
          };
        }
      } else if (connectionBetween.docs[0].data()['type'] == 'requested') {
        if (isPrivateAccount) {
          return {
            'liked': [],
            'media': [],
            'location': [],
            'all': ['requested'],
            'following': false,
          };
        }
      } else {
        following = true;
      }
    }

    final postsRef = FirebaseFirestore.instance.collection('posts');
    QuerySnapshot<Map<String, dynamic>> allPostsSnap =
        await postsRef.where('userId', isEqualTo: user.id).get();
    List<Post> allPosts = allPostsSnap.docs
        .map(
          (e) => Post.fromJson(e.data()),
        )
        .toList();
    late QuerySnapshot<Map<String, dynamic>> sharedPostsResult;
    final listOfSharedPostsByUser = user.sharedPosts;
    List<List<String>?> arrayChunks = [];
    for (var i = 0; i < listOfSharedPostsByUser.length; i += 10) {
      arrayChunks.add(
        listOfSharedPostsByUser.sublist(
          i,
          i + 10 < listOfSharedPostsByUser.length
              ? i + 10
              : listOfSharedPostsByUser.length,
        ),
      );
    }
    List<Post> sharedPosts = [];
    for (var i = 0; i < arrayChunks.length; i++) {
      sharedPostsResult =
          await postsRef.where('id', whereIn: arrayChunks[i]).get();
      sharedPosts.addAll(sharedPostsResult.docs
          .map((document) => Post.fromJson(document.data()))
          .toList());
    }
    sharedPosts.removeWhere((element) => element.userId == user.id);
    allPosts.addAll(sharedPosts.map((Post sharedPost) {
      sharedPost.sharedBy = user;
      return sharedPost;
    }));

    allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    QuerySnapshot<Map<String, dynamic>> locationPostsSnap = await postsRef
        .where('userId', isEqualTo: user.id)
        .where('location', isNull: false)
        .get();
    List<Post> locationPosts = locationPostsSnap.docs
        .map(
          (e) => Post.fromJson(e.data()),
        )
        .toList();
    locationPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    QuerySnapshot<Map<String, dynamic>> mediaPostsResult1 = await postsRef
        .where('imageUrl', isNull: false)
        .where(
          'userId',
          isEqualTo: user.id,
        )
        .get();
    QuerySnapshot<Map<String, dynamic>> mediaPostsResult2 = await postsRef
        .where('videoUrl', isNull: false)
        .where(
          'userId',
          isEqualTo: user.id,
        )
        .get();
    List<Post> mediaPosts = [
      ...mediaPostsResult1.docs
          .map(
            (e) => Post.fromJson(e.data()),
          )
          .toList(),
      ...mediaPostsResult2.docs
          .map(
            (e) => Post.fromJson(e.data()),
          )
          .toList()
    ];
    mediaPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    QuerySnapshot<Map<String, dynamic>> likesResult =
        await postsRef.where('likedBy', arrayContains: user.id).get();
    List<Post> likedPosts = likesResult.docs
        .map(
          (e) => Post.fromJson(e.data()),
        )
        .toList();
    return {
      'liked': likedPosts,
      'media': mediaPosts,
      'location': locationPosts,
      'all': allPosts,
      'following': following,
    };
  }

  Future<void> removeProfilePicture(AppUser user) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    usersRef.doc(user.id).update({
      'profilePictureUrl': null,
    });
  }

  Future<void> changeProfilePicture(AppUser user, String newUrl) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    usersRef.doc(user.id).update({
      'profilePictureUrl': newUrl,
    });
  }

  Future<void> reactivateUser(AppUser user) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    usersRef.doc(user.id).update({
      'deactivated': false,
    });
  }

  Future<void> deactivateUser(AppUser user) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    usersRef.doc(user.id).update({
      'deactivated': true,
    });
  }

  Future<void> deleteUser(AppUser user) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final postsRef = FirebaseFirestore.instance.collection('posts');
    final notifRef = FirebaseFirestore.instance.collection('notifications');
    final connectRef = FirebaseFirestore.instance.collection('connections');
    await usersRef.doc(user.id).delete();
    final batch = FirebaseFirestore.instance.batch();
    final usersPosts = await postsRef.where('userId', isEqualTo: user.id).get();
    List<String> postIds = usersPosts.docs
        .map(
          (doc) => doc.id,
        )
        .toList();
    List<String> idsOfPostsWithMedia = [];
    for (final doc in usersPosts.docs) {
      if (doc.data()['imageUrl'] != null || doc.data()['videoUrl'] != null) {
        idsOfPostsWithMedia.add(doc.id);
      }
    }
    for (final id in postIds) {
      batch.delete(postsRef.doc(id));
    }
    await batch.commit();
    CloudStorage store = CloudStorage();
    for (final id in idsOfPostsWithMedia) {
      await store.removePostMedia(id);
    }

    final subjectNotifications =
        await notifRef.where('subjectId', isEqualTo: user.id).get();
    List<String> notifIdsToDelete = [];
    for (final doc in subjectNotifications.docs) {
      notifIdsToDelete.add(doc.id);
    }
    final targetNotifications =
        await notifRef.where('targetId', isEqualTo: user.id).get();
    for (final doc in targetNotifications.docs) {
      notifIdsToDelete.add(doc.id);
    }

    final batch2 = FirebaseFirestore.instance.batch();
    for (final id in notifIdsToDelete) {
      batch2.delete(notifRef.doc(id));
    }
    await batch2.commit();

    final subjectConnections =
        await connectRef.where('subject', isEqualTo: user.id).get();
    List<String> connectIdsToDelete = [];
    for (final doc in subjectConnections.docs) {
      connectIdsToDelete.add(doc.id);
    }
    final targetConnections =
        await connectRef.where('target', isEqualTo: user.id).get();
    for (final doc in targetConnections.docs) {
      connectIdsToDelete.add(doc.id);
    }

    final batch3 = FirebaseFirestore.instance.batch();
    for (final id in connectIdsToDelete) {
      batch3.delete(connectRef.doc(id));
    }
    await batch3.commit();
  }

  Future<List<int>> getConnectedCounts(AppUser user) async {
    final connectRef = FirebaseFirestore.instance.collection('connections');
    //return list at index 0 number of connected to me at index 1 connected to
    int connectedTo = (await connectRef
            .where('subject', isEqualTo: user.id)
            .where('type', isEqualTo: 'connected')
            .get())
        .size;
    int connectedToMe = (await connectRef
            .where('target', isEqualTo: user.id)
            .where('type', isEqualTo: 'connected')
            .get())
        .size;
    return [connectedToMe, connectedTo];
  }

  Future<List<Post>> getComments(Post post) async {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    final dbRes = await postsRef.where('commentToId', isEqualTo: post.id).get();
    return dbRes.docs
        .map(
          (doc) => Post.fromJson(
            doc.data(),
          ),
        )
        .toList();
  }

  Future<List<AppUser>?> getUsersConnectedList(AppUser user) async {
    final connectRef = FirebaseFirestore.instance.collection('connections');
    final usersConnectedUsersId = (await connectRef
            .where('subject', isEqualTo: user.id)
            .where('type', isEqualTo: 'connected')
            .get())
        .docs
        .map((doc) => doc.data()['target'] as String)
        .toList();
    late QuerySnapshot<Map<String, dynamic>> getConnectedUsersResult;
    List<List<String>?> arrayChunks = [];
    for (var i = 0; i < usersConnectedUsersId.length; i += 10) {
      arrayChunks.add(
        usersConnectedUsersId.sublist(
          i,
          i + 10 < usersConnectedUsersId.length
              ? i + 10
              : usersConnectedUsersId.length,
        ),
      );
    }
    final usersRef = FirebaseFirestore.instance.collection('users');
    List<AppUser> connectedUsers = [];
    try {
      for (var i = 0; i < arrayChunks.length; i++) {
        getConnectedUsersResult =
            await usersRef.where('id', whereIn: arrayChunks[i]).get();
        connectedUsers.addAll(getConnectedUsersResult.docs
            .map((document) => AppUser.fromJson(document.data()))
            .toList());
      }
      return connectedUsers;
    } catch (e) {
      return null;
    }
  }

  Future<void> removeConnectionOfFrom(AppUser of, AppUser from) async {
    final connectRef = FirebaseFirestore.instance.collection('connections');
    final result = await connectRef
        .where('subject', isEqualTo: from.id)
        .where('target', isEqualTo: of.id)
        .get();
    final id = result.docs[0].data()['id'];
    await connectRef.doc(id).delete();
  }

  Future<void> addConnectionOfTo(AppUser of, AppUser to) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    bool isPrivate =
        (await usersRef.doc(of.id).get()).data()!['publicAccount'] == false;
    final connectRef = FirebaseFirestore.instance.collection('connections');
    Connection connectionToSend = Connection(
      id: 'dummyId',
      subject: to.id,
      target: of.id,
      type: isPrivate ? 'requested' : 'connected',
    );
    connectionToSend.id = connectRef.doc().id;
    await connectRef.doc(connectionToSend.id).set(connectionToSend.toJson());
  }

  Future<List<AppUser>?> getUsersConnectedToMeList(AppUser user) async {
    final connectRef = FirebaseFirestore.instance.collection('connections');
    final usersConnectedUsersId = (await connectRef
            .where('target', isEqualTo: user.id)
            .where('type', isEqualTo: 'connected')
            .get())
        .docs
        .map((doc) => doc.data()['subject'] as String)
        .toList();
    late QuerySnapshot<Map<String, dynamic>> getConnectedUsersResult;
    List<List<String>?> arrayChunks = [];
    for (var i = 0; i < usersConnectedUsersId.length; i += 10) {
      arrayChunks.add(
        usersConnectedUsersId.sublist(
          i,
          i + 10 < usersConnectedUsersId.length
              ? i + 10
              : usersConnectedUsersId.length,
        ),
      );
    }
    final usersRef = FirebaseFirestore.instance.collection('users');
    List<AppUser> connectedUsers = [];
    try {
      for (var i = 0; i < arrayChunks.length; i++) {
        getConnectedUsersResult =
            await usersRef.where('id', whereIn: arrayChunks[i]).get();
        connectedUsers.addAll(getConnectedUsersResult.docs
            .map((document) => AppUser.fromJson(document.data()))
            .toList());
      }
      return connectedUsers;
    } catch (e) {
      return null;
    }
  }

  Future<void> resharePost(Post post, AppUser user) async {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    final usersRef = FirebaseFirestore.instance.collection('users');
    user.sharedPosts.add(post.id);
    await usersRef.doc(user.id).update({
      'sharedPosts': FieldValue.arrayUnion([post.id]),
    });
    post.shareCount += 1;
    postsRef.doc(post.id).update(
      {'shareCount': FieldValue.increment(1)},
    );
    final notificationsRef =
        FirebaseFirestore.instance.collection('notifications');
    DocumentReference<Map<String, dynamic>> tempDoc = notificationsRef.doc();
    AppNotification temp = AppNotification(
      id: tempDoc.id,
      subjectId: user.id,
      targetId: post.userId,
      postId: post.id,
      type: 'reshare',
    );
    await notificationsRef.doc(temp.id).set(temp.toJson());
  }

  Future<void> removeShare(Post post, AppUser user) async {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    final usersRef = FirebaseFirestore.instance.collection('users');
    user.sharedPosts.remove(post.id);
    await usersRef.doc(user.id).update({
      'sharedPosts': FieldValue.arrayRemove([post.id]),
    });
    post.shareCount -= 1;
    postsRef.doc(post.id).update(
      {'shareCount': FieldValue.increment(-1)},
    );
    final notificationsRef =
        FirebaseFirestore.instance.collection('notifications');
    String docIdToRemove = (await notificationsRef
            .where('subjectId', isEqualTo: user.id)
            .where(
              'postId',
              isEqualTo: post.id,
            )
            .where(
              'type',
              isEqualTo: 'reshare',
            )
            .get())
        .docs[0]
        .data()['id'];
    await notificationsRef.doc(docIdToRemove).delete();
  }

  Future<void> increaseCommentCount(Post post) async {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    await postsRef.doc(post.id).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Future<void> updateNameBioEmailPublicAccount(AppUser user) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    await usersRef.doc(user.id).update({
      'name': user.name,
      'bio': user.bio,
      'publicAccount': user.publicAccount,
    });
  }

  Future<List<AppUser>> getFollowerRequests(AppUser user) async {
    final connectRef = FirebaseFirestore.instance.collection('connections');
    final usersRef = FirebaseFirestore.instance.collection('users');
    final result = await connectRef
        .where('target', isEqualTo: user.id)
        .where('type', isEqualTo: 'requested')
        .get();
    final listOfRequestedUsers = result.docs
        .map(
          (doc) => doc.data()['subject'] as String,
        )
        .toList();
    late QuerySnapshot<Map<String, dynamic>> getRequestedUsersResults;
    List<List<String>?> arrayChunks = [];
    for (var i = 0; i < listOfRequestedUsers.length; i += 10) {
      arrayChunks.add(
        listOfRequestedUsers.sublist(
          i,
          i + 10 < listOfRequestedUsers.length
              ? i + 10
              : listOfRequestedUsers.length,
        ),
      );
    }
    List<AppUser> returner = [];
    try {
      for (var i = 0; i < arrayChunks.length; i++) {
        getRequestedUsersResults =
            await usersRef.where('id', whereIn: arrayChunks[i]).get();
        returner.addAll(
          getRequestedUsersResults.docs
              .map(
                (document) => AppUser.fromJson(
                  document.data(),
                ),
              )
              .toList(),
        );
      }
      return returner;
    } catch (e) {
      return [];
    }
  }

  Future<void> approveRequest(
      {required AppUser requestingUser, required AppUser owningUser}) async {
    final connectRef = FirebaseFirestore.instance.collection('connections');
    final result = await connectRef
        .where('target', isEqualTo: owningUser.id)
        .where('subject', isEqualTo: requestingUser.id)
        .get();
    await connectRef.doc(result.docs[0].data()['id']).update({
      'type': 'connected',
    });
  }

  Future<void> declineRequest(
      {required AppUser requestingUser, required AppUser owningUser}) async {
    final connectRef = FirebaseFirestore.instance.collection('connections');
    final result = await connectRef
        .where('target', isEqualTo: owningUser.id)
        .where('subject', isEqualTo: requestingUser.id)
        .get();
    await connectRef.doc(result.docs[0].data()['id']).delete();
  }
}
