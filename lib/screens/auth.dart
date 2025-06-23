import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:section14_chatapp/widgets/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredpassword = '';
  File? _selectedImage;
  var _isAuthenticating = false;
  var _enteredUsername = '';

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || !_isLogin && _selectedImage == null) {
      // show error message ...
      return;
    }

    _form.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredpassword,
        );
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredpassword,
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
              'username': _enteredUsername,
              'email': _enteredEmail,
              'image_url': imageUrl,
            });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //   ...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Authentication failed.')),
      );
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบว่าอุปกรณ์อยู่ในแนวนอนหรือแนวตั้ง
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: isLandscape
              ? _buildLandscapeLayout(screenWidth, screenHeight)
              : _buildPortraitLayout(screenWidth, screenHeight),
        ),
      ),
    );
  }

  // Layout สำหรับแนวตั้ง (เดิม)
  Widget _buildPortraitLayout(double screenWidth, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(
            top: 30,
            bottom: 20,
            left: 20,
            right: 20,
          ),
          width: 200,
          child: Image.asset('assets/images/chat.png'),
        ),
        Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildForm(),
            ),
          ),
        ),
      ],
    );
  }

  // Layout สำหรับแนวนอน
  Widget _buildLandscapeLayout(double screenWidth, double screenHeight) {
    return Row(
      children: [
        // ส่วนซ้าย - รูปภาพ
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150, // ลดขนาดรูปในแนวนอน
                  child: Image.asset('assets/images/chat.png'),
                ),
              ],
            ),
          ),
        ),
        // ส่วนขวา - ฟอร์ม
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ส่วนของฟอร์มที่ใช้ร่วมกัน
  Widget _buildForm() {
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isLogin)
            UserImagePicker(
              onPickImage: (pickedImage) {
                _selectedImage = pickedImage;
              },
            ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email Address'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty ||
                  !value.contains('@')) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
            onSaved: (value) {
              _enteredEmail = value!;
            },
          ),
          if (!_isLogin)
            TextFormField(
              decoration: const InputDecoration(labelText: 'Username'),
              enableSuggestions: false,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().length < 4) {
                  return 'Please enter at least 4 characters.';
                }
                return null;
              },
              onSaved: (value) {
                _enteredUsername = value!;
              },
            ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.trim().length < 6) {
                return 'Password must be at least 6 characters long.';
              }
              return null;
            },
            onSaved: (value) {
              _enteredpassword = value!;
            },
          ),
          const SizedBox(height: 12),
          if (_isAuthenticating) const CircularProgressIndicator(),
          if (!_isAuthenticating)
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Text(_isLogin ? 'Login' : 'Sign Up'),
            ),
          if (!_isAuthenticating)
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(
                _isLogin
                    ? 'Create an account'
                    : 'I already have an account. Login.',
              ),
            ),
        ],
      ),
    );
  }
}
