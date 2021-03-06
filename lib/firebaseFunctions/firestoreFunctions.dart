import 'dart:io';
import 'package:MyntraHackathon/Provider/googleMapMarkers.dart';
import 'package:MyntraHackathon/firebaseFunctions/firebaseAuth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreFunction {
  //The reference to access the Firebase Storage
  static StorageReference ref = FirebaseStorage.instance.ref();

  //The reference to access Firestore data
  static FirebaseFirestore fire = FirebaseFirestore.instance;

//Adding a post to the database
  static postImage(Position userPosition, File image, int cnt, String bio,
      User user, int postType, GoogleMapMarker marker, BuildContext context) async {
    User _currUser = FirebaseAuthentication.auth.currentUser;
    try {
      //Getting the link after uploading the image
      String url = await uploadImage(
          ref
              .child('userProfile')
              .child(_currUser.uid.toString())
              .child('currentUser$cnt'),
          image);
      //Fetching the user address
      List<Address> address = await Geocoder.local.findAddressesFromCoordinates(
          Coordinates(userPosition.latitude, userPosition.longitude));
      Address place = address[0];
      //Adding the post to the database
      DocumentReference coll = await fire.collection('Posts').add({
        'latitude': userPosition.latitude,
        'longitude': userPosition.longitude,
        'imageUrl': url,
        'timestamp': DateTime.now(),
        'bio': bio,
        'userId': user.uid,
        'userName': user.displayName,
        'userImage': user.photoURL,
        'address':
            "${place.locality}, ${place.postalCode}, ${place.countryName}",
        'postType': postType,
        'likes': 0,
      });
//Adding the post id to the user details
      DocumentSnapshot snap = await coll.get();
      fire.collection('Users').doc(user.uid).update({
        "posts": FieldValue.arrayUnion([snap.id]),
      });
      //Manually update the marker in the map
      marker.addMarker(snap, context);
      Fluttertoast.showToast(msg: 'Post Uploaded');
      print('db complete..');
    } catch (e) {
      print(e);
    }
  }
//Uploading the image into the Firebase storage and returning the link to that image
  static uploadImage(StorageReference imgRef, File image) async {
    print('uploading image');
//      Firestore.instance.collection('Posts').get();

    StorageUploadTask task = imgRef.putFile(image);
    StorageTaskSnapshot details = await task.onComplete;
    print('upload complete..');
    return await imgRef.getDownloadURL();
  }

  //Uploading the user details into the database
  static updateUserProfile(
      {String name, String description, String username, File image}) async {
    User _currUser = FirebaseAuthentication.auth.currentUser;
    String url;
    if (image != null)
      //Uploading user profile picture
      url = await uploadImage(
          ref
              .child('userProfile')
              .child(_currUser.uid.toString())
              .child('profilePicture'),
          image);
    //Updating user database
    fire.collection('Users').doc(_currUser.uid).set({
      'name': name,
      'description': description,
      'username': username,
      'photoUrl': url,
      'timeStamp': DateTime.now().toString(),
      'posts': [],
      'likes': 0,
      'likedPosts': [],
    },
    );
    FirebaseAuthentication.updateCurrentUserData(name, url);
  }

  //Searching for the user details for the given user Id
  static Future<Map<String, dynamic>> getUserDetails(String uid) async {
    DocumentReference ref =
        FirebaseFirestore.instance.collection('Users').doc(uid);
    DocumentSnapshot snap = await ref.get();
    print('lalallaa ${snap.data()['posts']}');
    return snap.data();
  }
  //Searching for the user posts for the given user Id
  static getUserPosts(List<dynamic> posts) async {
    print('getting posts... $posts');
    List<DocumentSnapshot> ll = [];
    for (String post in posts) {
      DocumentSnapshot snap =
          await FirebaseFirestore.instance.collection('Posts').doc(post).get();
      ll.add(snap);
    }
    return ll;
  }
  static likeAPost(String postId, String userId){
    fire.collection('Posts').doc('$postId').update({
      'likes': FieldValue.increment(1),
    });
    fire.collection('Users').doc('$userId').update({
      'likes': FieldValue.increment(1),
    });
    fire.collection('Users').doc('${FirebaseAuthentication.auth.currentUser.uid}').update({
      'likedPosts': FieldValue.arrayUnion([postId])
    });
  }
  static getCurrentUserDetails() async{
    if(FirebaseAuthentication.auth.currentUser == null)
      return {};
    DocumentSnapshot doc = await fire.collection('Users').doc('${FirebaseAuthentication.auth.currentUser.uid}').get();
    return doc.data();
  }
  static getLeaderboardValues() async{
    QuerySnapshot snap = await fire.collection('Users').orderBy('likes', descending: true).get();
    return snap.docs;
  }
  static followUser(String followerId, String followeeId) async{
    fire.collection('Users').doc(followerId).update({
      'follower': FieldValue.arrayUnion([followeeId]),
    });
    fire.collection('Users').doc(followeeId).update({
      'following': FieldValue.arrayUnion([followerId]),
    });
  }
}
