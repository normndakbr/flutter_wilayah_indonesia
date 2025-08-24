import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wilayah_indonesia/services/wilayah_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Dataset kecil (cukup untuk ngetes cascade)
    final prov = [
      {"id": "32", "nama": "JAWA BARAT"},
      {"id": "31", "nama": "DKI JAKARTA"},
    ];
    final kab = [
      {"id": "3273", "id_provinsi": "32", "nama": "KOTA BANDUNG"},
      {"id": "3204", "id_provinsi": "32", "nama": "KABUPATEN BANDUNG"},
      {"id": "3173", "id_provinsi": "31", "nama": "KOTA JAKARTA BARAT"},
    ];
    final kec = [
      {"id": "3273010", "id_kabupaten": "3273", "nama": "BOJONGLOA KALER"},
      {"id": "3273011", "id_kabupaten": "3273", "nama": "ASTANA ANYAR"},
      {"id": "3204050", "id_kabupaten": "3204", "nama": "SOREANG"},
    ];
    final kel = [
      {"id": "3273010001", "id_kecamatan": "3273010", "nama": "KELURAHAN X"},
      {"id": "3273010002", "id_kecamatan": "3273010", "nama": "KELURAHAN Y"},
    ];

    // Map key asset → isi file (mock)
    final assets = <String, String>{
      // path saat dipanggil dari app consumer (pakai prefix packages/)
      'packages/flutter_wilayah_indonesia/assets/wilayah/provinsi.json':
          jsonEncode(prov),
      'packages/flutter_wilayah_indonesia/assets/wilayah/kabupaten.json':
          jsonEncode(kab),
      'packages/flutter_wilayah_indonesia/assets/wilayah/kecamatan.json':
          jsonEncode(kec),
      'packages/flutter_wilayah_indonesia/assets/wilayah/kelurahan.json':
          jsonEncode(kel),
      // path fallback (tanpa prefix) — biar aman kalau _load() pakai jalur ini
      'assets/wilayah/provinsi.json': jsonEncode(prov),
      'assets/wilayah/kabupaten.json': jsonEncode(kab),
      'assets/wilayah/kecamatan.json': jsonEncode(kec),
      'assets/wilayah/kelurahan.json': jsonEncode(kel),
    };

    // Hook asset channel di test env
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      final value = assets[key];
      if (value == null) return null;
      final bytes = Uint8List.fromList(utf8.encode(value));
      return ByteData.view(bytes.buffer);
    });
  });

  setUp(() {
    // Pastikan cache kosong di tiap test
    WilayahService.clearCache();
  });

  group('WilayahService (mocked assets)', () {
    test('getProvinsi loads list', () async {
      final list = await WilayahService.getProvinsi();
      expect(list.length, 2);
      expect(list.first.id, '32');
    });

    test('getKabupatenByProvinsi filters correctly', () async {
      final list = await WilayahService.getKabupatenByProvinsi('32');
      expect(list.map((e) => e.id).toSet(), {'3273', '3204'});
    });

    test('getKecamatanByKabupaten filters correctly', () async {
      final list = await WilayahService.getKecamatanByKabupaten('3273');
      expect(list.length, 2);
      expect(list.first.idKabupaten, '3273');
    });

    test('getKelurahanByKecamatan filters correctly', () async {
      final list = await WilayahService.getKelurahanByKecamatan('3273010');
      expect(list.length, 2);
      expect(list.first.idKecamatan, '3273010');
    });
  });
}
