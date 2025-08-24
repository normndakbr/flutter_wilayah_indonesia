import 'package:flutter/material.dart';
import 'package:flutter_wilayah_indonesia/flutter_wilayah_indonesia.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Wilayah Picker Example')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: WilayahPicker(
            initialProvId: '32', // contoh preselect Jawa Barat
          ),
        ),
      ),
    );
  }
}
