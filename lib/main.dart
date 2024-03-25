import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'signUp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: 'AIzaSyDuypLNBPtL71NLO0xjWEfyHbiLZJRmlhQ',
          appId: '1:376342953128:android:e7810a41951f235adbd69d',
          messagingSenderId: '376342953128',
          projectId: 'todoapps-13b7f'));

  runApp(const MaterialApp(
    title: 'MyApp',
    home: LoginScreen(), // Оборачиваем LoginScreen в MaterialApp
  ));
}
