import 'dart:io';

import 'package:MyntraHackathon/Provider/googleMapMarkers.dart';
import 'package:MyntraHackathon/firebaseFunctions/firebaseAuth.dart';
import 'package:MyntraHackathon/firebaseFunctions/firestoreFunctions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreatePost extends StatefulWidget {
  Position currentLocation;
  String currentAddress;
  int totalPostsTillnow;
  int orderIdx;

  CreatePost(
      {this.currentLocation,
      this.currentAddress,
      this.totalPostsTillnow,
      this.orderIdx});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return CreateState();
  }
}
class CreateState extends State<CreatePost> {
  File _imgToUpload;
  ImageSource source;
  TextEditingController _latController;
  TextEditingController _longController;
  TextEditingController _captionController;
  Position _currPosition;
  Future<void> selectImage() async {
    PickedFile img = await ImagePicker.platform.pickImage(source: source);
    if (img != null) {
      setState(() {
        _imgToUpload = File(img.path);
      });
    }
  }
  void getImage() {
    showDialog(
        context: context,
        builder: (ctx) => SimpleDialog(
              children: <Widget>[
                FlatButton.icon(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () {
                    setState(() {
                      source = ImageSource.camera;
                    });
                    selectImage();
                    Navigator.of(ctx).pop();
                  },
                  label: Text('Click From Camera'),
                ),
                FlatButton.icon(
                  icon: Icon(Icons.camera),
                  onPressed: () {
                    setState(() {
                      source = ImageSource.gallery;
                    });
                    selectImage();
                    Navigator.of(ctx).pop();
                  },
                  label: Text('Choose from Gallery'),
                ),
              ],
            ));
  }
  @override
  void initState() {
    _latController =
        TextEditingController(text: widget.currentLocation.latitude.toString());
    _longController = TextEditingController(
        text: widget.currentLocation.longitude.toString());
    _captionController = TextEditingController();
    this._currPosition = widget.currentLocation;
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
//      resizeToAvoidBottomPadding: false,
      bottomNavigationBar: Builder(
        builder: (context) => MaterialButton(
          color: Theme.of(context).accentColor,
          onPressed: () async {
            if (_imgToUpload == null)
              Fluttertoast.showToast(msg: 'Please upload an image');
            else {
//                  Provider.of<GoogleMapM(context)
              Fluttertoast.showToast(
                  msg: 'You will be notified when you post is uploaded');
              FirestoreFunction.postImage(
                this._currPosition,
                _imgToUpload,
                widget.totalPostsTillnow,
                _captionController.text,
                FirebaseAuthentication.auth.currentUser,
                widget.orderIdx,
                Provider.of<GoogleMapMarker>(context, listen: false),
                context,
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(
            'POST',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 79),
        ),
      ),
      appBar: AppBar(
        title: Text('Add a post'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
            ),
            Center(
              child: _imgToUpload == null
                  ? Container(
                      height: MediaQuery.of(context).size.height * 0.8,
                      width: MediaQuery.of(context).size.width * (0.9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFD9D9D9), width: 5),
                        borderRadius: BorderRadius.circular(10),
                      ),
//                    image: _imgToUpload == null
//                        ? null
//                        : DecorationImage(
//                            image: FileImage(_imgToUpload),
//                          )),
                      child: FlatButton.icon(
                        label: Text(
                          'Add Image',
                          style: TextStyle(
                            color: Color(
                              0xFFD9D9D9,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.image,
                          color: Color(
                            0xFFD9D9D9,
                          ),
                        ),
                        onPressed: getImage,
                      )
//                    : Container(),
                      )
                  : Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFD9D9D9), width: 5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.file(_imgToUpload),
                    ),
            ),
            SizedBox(
              height: 10,
            ),
            Text('Current Address: ${widget.currentAddress}'),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _latController,
                    decoration: InputDecoration(labelText: 'Latitude'),
                    onChanged: (val) {
//                        this._latController.;
                      this._currPosition = Position(
                          latitude: double.parse(val),
                          longitude: _currPosition.longitude);
                    },
                    onSubmitted: (val) {
                      this._currPosition = Position(
                          latitude: double.parse(val),
                          longitude: _currPosition.longitude);
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _longController,
                    decoration: InputDecoration(labelText: 'Longitude'),
                    onChanged: (val) {
                      this._currPosition = Position(
                          latitude: _currPosition.latitude,
                          longitude: double.parse(val));
                    },
                    onSubmitted: (val) {
                      this._currPosition = Position(
                          latitude: _currPosition.latitude,
                          longitude: double.parse(val));
                    },
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: TextField(
                controller: _captionController,
                cursorColor: Theme.of(context).accentColor,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                ),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Enter a caption',
                  hoverColor: Theme.of(context).accentColor,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFC4C4C4), width: 1),
                  ),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
            ),
            SizedBox(
              height: 30,
            )
          ],
        ),
      ),
    );
  }
}
