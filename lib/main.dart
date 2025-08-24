import 'package:flutter/material.dart';
import 'package:flutter_wilayah_indonesia/services/wilayah_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final provinsiList = await WilayahService.getProvinsi(); // <— ganti ini
  for (final prov in provinsiList) {
    print('${prov.id}: ${prov.nama}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Wilayah Indonesia'))),
    );
  }
}
