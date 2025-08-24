// tool/fetch_kabupaten.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const base = 'https://emsifa.github.io/api-wilayah-indonesia/api';

Future<void> main() async {
  // 1) Ambil semua data provinsi
  final provRes = await http.get(Uri.parse('$base/provinces.json'));
  if (provRes.statusCode != 200) {
    stderr.writeln('Gagal ambil provinces: ${provRes.statusCode}');
    exit(1);
  }
  final provinces = (jsonDecode(provRes.body) as List)
      .cast<Map<String, dynamic>>();

  final allKabKota = <Map<String, String>>[];

  // 2) Loop provinsi -> ambil semua kab/kota
  for (final p in provinces) {
    final provId = p['id'].toString();
    final regRes = await http.get(Uri.parse('$base/regencies/$provId.json'));
    if (regRes.statusCode != 200) {
      stderr.writeln(
        'Gagal ambil regencies untuk provinsi $provId: ${regRes.statusCode}',
      );
      exit(1);
    }
    final regs = (jsonDecode(regRes.body) as List).cast<Map<String, dynamic>>();

    for (final r in regs) {
      allKabKota.add({
        'id': r['id'].toString(),
        'id_provinsi': provId,
        'nama': r['name'].toString(), // sumber uppercase; biarkan apa adanya
      });
    }
    stdout.writeln('✔ Provinsi $provId: ${regs.length} kab/kota');
  }

  // 3) Tulis ke assets/wilayah/kabupaten.json
  final outDir = Directory('assets/wilayah');
  if (!await outDir.exists()) await outDir.create(recursive: true);

  final outFile = File('assets/wilayah/kabupaten.json');
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(allKabKota),
  );
  stdout.writeln('✅ Ditulis: ${allKabKota.length} entri → ${outFile.path}');
}
