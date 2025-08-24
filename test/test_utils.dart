import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock channel 'flutter/assets' agar rootBundle.loadString(...) membaca
/// data dari memori, bukan dari file JSON asli.
void mockWilayahAssets({
  required List<Map<String, dynamic>> prov,
  required List<Map<String, dynamic>> kab,
  required List<Map<String, dynamic>> kec,
  required List<Map<String, dynamic>> kel,
  String packageName = 'flutter_wilayah_indonesia',
}) {
  final assets = <String, String>{
    // jalur ketika dipanggil dari app konsumen
    'packages/$packageName/assets/wilayah/provinsi.json': jsonEncode(prov),
    'packages/$packageName/assets/wilayah/kabupaten.json': jsonEncode(kab),
    'packages/$packageName/assets/wilayah/kecamatan.json': jsonEncode(kec),
    'packages/$packageName/assets/wilayah/kelurahan.json': jsonEncode(kel),
    // fallback jalur tanpa prefix (dipakai _load() di service)
    'assets/wilayah/provinsi.json': jsonEncode(prov),
    'assets/wilayah/kabupaten.json': jsonEncode(kab),
    'assets/wilayah/kecamatan.json': jsonEncode(kec),
    'assets/wilayah/kelurahan.json': jsonEncode(kel),
  };

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        final value = assets[key];
        if (value == null) return null;
        final bytes = Uint8List.fromList(utf8.encode(value));
        return ByteData.view(bytes.buffer);
      });
}
