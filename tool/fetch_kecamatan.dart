// tool/fetch_kecamatan.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const base = 'https://emsifa.github.io/api-wilayah-indonesia/api';

Future<void> main() async {
  // Pastikan assets kabupaten sudah ada
  final kabFile = File('assets/wilayah/kabupaten.json');
  if (!kabFile.existsSync()) {
    stderr.writeln(
      'assets/wilayah/kabupaten.json not found. Generate kabupaten first.',
    );
    exit(1);
  }
  final kabList = (jsonDecode(await kabFile.readAsString()) as List)
      .cast<Map<String, dynamic>>();

  final out = <Map<String, String>>[];

  var processed = 0;
  for (final kab in kabList) {
    final kabId = kab['id'].toString();
    final url = Uri.parse('$base/districts/$kabId.json');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      stderr.writeln('❌ gagal districts $kabId: ${res.statusCode}');
      exit(1);
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    for (final d in list) {
      out.add({
        'id': d['id'].toString(),
        'id_kabupaten': kabId,
        'nama': d['name'].toString(),
      });
    }
    processed++;
    if (processed % 20 == 0)
      stdout.writeln('✔ districts progress: $processed/${kabList.length}');
    await Future.delayed(const Duration(milliseconds: 120)); // throttle
  }

  final dir = Directory('assets/wilayah');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final outFile = File('assets/wilayah/kecamatan.json');
  await outFile.writeAsString(jsonEncode(out)); // minified
  stdout.writeln('✅ wrote ${out.length} kecamatan → ${outFile.path}');
}
