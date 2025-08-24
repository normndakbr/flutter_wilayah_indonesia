import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wilayah_indonesia/services/wilayah_service.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Dataset mini buat ngetes cascade
  final prov = [
    {'id': '32', 'nama': 'JAWA BARAT'},
    {'id': '31', 'nama': 'DKI JAKARTA'},
  ];
  final kab = [
    {'id': '3273', 'id_provinsi': '32', 'nama': 'KOTA BANDUNG'},
    {'id': '3204', 'id_provinsi': '32', 'nama': 'KABUPATEN BANDUNG'},
    {'id': '3173', 'id_provinsi': '31', 'nama': 'KOTA JAKARTA BARAT'},
  ];
  final kec = [
    {'id': '3273010', 'id_kabupaten': '3273', 'nama': 'BOJONGLOA KALER'},
    {'id': '3273011', 'id_kabupaten': '3273', 'nama': 'ASTANA ANYAR'},
    {'id': '3204050', 'id_kabupaten': '3204', 'nama': 'SOREANG'},
  ];
  final kel = [
    {'id': '3273010001', 'id_kecamatan': '3273010', 'nama': 'KELURAHAN X'},
    {'id': '3273010002', 'id_kecamatan': '3273010', 'nama': 'KELURAHAN Y'},
  ];

  setUpAll(() {
    mockWilayahAssets(prov: prov, kab: kab, kec: kec, kel: kel);
  });

  setUp(() {
    WilayahService.clearCache(); // bersihkan cache antar test
  });

  test('getProvinsi memuat daftar provinsi', () async {
    final list = await WilayahService.getProvinsi();
    expect(list.length, 2);
    expect(list.first.id, '32');
    expect(list.first.nama, 'JAWA BARAT');
  });

  test('getKabupatenByProvinsi memfilter dengan benar', () async {
    final list = await WilayahService.getKabupatenByProvinsi('32');
    expect(list.map((e) => e.id).toSet(), {'3273', '3204'});
  });

  test('getKecamatanByKabupaten memfilter dengan benar', () async {
    final list = await WilayahService.getKecamatanByKabupaten('3273');
    expect(list.length, 2);
    expect(list.first.idKabupaten, '3273');
  });

  test('getKelurahanByKecamatan memfilter dengan benar', () async {
    final list = await WilayahService.getKelurahanByKecamatan('3273010');
    expect(list.length, 2);
    expect(list.first.idKecamatan, '3273010');
  });
}
