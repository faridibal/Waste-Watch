import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waste_watch/resources/storage_methods.dart';
import 'package:waste_watch/models/user.dart' as model;

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // obtener detalles del usuario
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return model.User.fromSnap(documentSnapshot);
  }

  // Registrarse usuaria
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
    required Uint8List? file,
  }) async {
    String res = "Ha ocurrido un error";
    try {
      if (email.isNotEmpty ||
          password.isNotEmpty ||
          username.isNotEmpty ||
          bio.isNotEmpty ||
          file != null) {
        String photoUrl; // Declarar la variable photoUrl aquí

        // Registrando usuario en autenticación con correo electrónico y contraseña
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (file == null) {
          photoUrl = 'https://i.stack.imgur.com/l60Hf.png';
        } else {
          photoUrl = await StorageMethods()
              .uploadImageToStorage('profilePics', file, false);
        }

        model.User user = model.User(
          username: username,
          uid: cred.user!.uid,
          photoUrl: photoUrl,
          email: email,
          bio: bio,
          followers: [],
          following: [],
        );

        // Agregar usuario en nuestra base de datos
        await _firestore
            .collection("users")
            .doc(cred.user!.uid)
            .set(user.toJson());

        res = "success";
      } else {
        res = "Por favor introduzca todos los campos";
      }
    } catch (error) {
      // Manejo de errores específicos de Firebase Authentication
      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'weak-password':
            res = 'La contraseña debe tener al menos 6 caracteres';
            break;
          case 'email-already-in-use':
            res = 'El correo electrónico ya está en uso';
            break;
          // Agrega más casos para otros códigos de error
          default:
            res = 'Error al registrar el usuario';
            break;
        }
      } else {
        res = 'Error al registrar el usuario';
      }
    }
    return res;
  }

  // Iniciando sesión de usuario
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Ha ocurrido un error";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        // Iniciar sesión usuario con correo electrónico y contraseña
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Por favor introduzca todos los campos";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
