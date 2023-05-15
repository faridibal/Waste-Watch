import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waste_watch/providers/user_provider.dart';
import 'package:waste_watch/resources/firestore_methods.dart';
import 'package:waste_watch/utils/colors.dart';
import 'package:waste_watch/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_launcher/maps_launcher.dart';

import 'feed_screen.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  Uint8List? _file;
  bool isLoading = false;
  final TextEditingController _descriptionController = TextEditingController();
  Position? _position;

  Future<Position> _determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permiso de ubicación denegado');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  void getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      Position position = await _determinePosition();
      setState(() {
        _position = position;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(
        context,
        error.toString(),
      );
    }
  }

  _selectImage(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Crear un Post'),
          children: <Widget>[
            SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Tomar una Foto'),
                onPressed: () async {
                  Navigator.pop(context);
                  Uint8List file = await pickImage(ImageSource.camera);
                  getCurrentLocation();

                  setState(() {
                    _file = file;
                  });
                }),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  void postImage(String uid, String username, String profImage) async {
    setState(() {
      isLoading = true;
    });
    String description = _descriptionController.text;
    // empezar la carga
    try {
      // subir a la base de datos
      String res = await FireStoreMethods().uploadPost(
        description,
        _file!,
        uid,
        username,
        profImage,
        _position?.latitude.toString() ?? "",
        _position?.longitude.toString() ?? "",
      );
      if (res == "success") {
        setState(() {
          isLoading = false;
        });
        showSnackBar(
          context,
          '¡Post Creado!',
        );
        clearImage();
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => FeedScreen()));
      } else {
        showSnackBar(context, res);
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(
        context,
        err.toString(),
      );
    }
  }

  void clearImage() {
    setState(() {
      _file = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);

    return _file == null
        ? Center(
            child: IconButton(
              icon: const Icon(
                Icons.upload,
                size: 60,
              ),
              onPressed: () => _selectImage(context),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: clearImage,
              ),
              title: const Text(
                'Crear Post',
              ),
              centerTitle: false,
              actions: <Widget>[
                TextButton(
                  onPressed: () => postImage(
                    userProvider.getUser.uid,
                    userProvider.getUser.username,
                    userProvider.getUser.photoUrl,
                  ),
                  child: const Text(
                    "Crear",
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  ),
                )
              ],
            ),
            // POST FORM
            body: Column(
              children: <Widget>[
                isLoading
                    ? const LinearProgressIndicator()
                    : const Padding(padding: EdgeInsets.only(top: 0.0)),
                const Divider(),
                Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            alignment: FractionalOffset.topCenter,
                            image: MemoryImage(_file!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => MapsLauncher.launchCoordinates(
                          _position?.latitude ?? 0.0,
                          _position?.longitude ?? 0.0),
                      child: RichText(
                        text: TextSpan(
                          text: 'Ubicación: ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  '${_position?.latitude ?? ""}, ${_position?.longitude ?? ""}',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Descripción del post',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          );
  }
}
