// tool/fetch_kelurahan.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const base = 'https://emsifa.github.io/api-wilayah-indonesia/api';

Future<void> main() async {
  // Pastikan assets kecamatan sudah ada
  final kecFile = File('assets/wilayah/kecamatan.json');
  if (!kecFile.existsSync()) {
    stderr.writeln(
      'assets/wilayah/kecamatan.json not found. Generate kecamatan first.',
    );
    exit(1);
  }
  final kecList = (jsonDecode(await kecFile.readAsString()) as List)
      .cast<Map<String, dynamic>>();

  final out = <Map<String, String>>[];

  var processed = 0;
  for (final kec in kecList) {
    final kecId = kec['id'].toString();
    final url = Uri.parse('$base/villages/$kecId.json');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      stderr.writeln('❌ gagal villages $kecId: ${res.statusCode}');
      exit(1);
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    for (final v in list) {
      out.add({
        'id': v['id'].toString(),
        'id_kecamatan': kecId,
        'nama': v['name'].toString(),
      });
    }

    processed++;
    if (processed % 50 == 0)
      stdout.writeln('✔ villages progress: $processed/${kecList.length}');
    await Future.delayed(const Duration(milliseconds: 120)); // throttle
  }

  final dir = Directory('assets/wilayah');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final outFile = File('assets/wilayah/kelurahan.json');
  await outFile.writeAsString(jsonEncode(out)); // minified
  stdout.writeln('✅ wrote ${out.length} kelurahan → ${outFile.path}');
}
