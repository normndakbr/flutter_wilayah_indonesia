// tool/fetch_kelurahan_resumable.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

const base = 'https://emsifa.github.io/api-wilayah-indonesia/api';
const progressPath = 'tool/.kelurahan_progress.json';
const ndjsonPath = 'assets/wilayah/kelurahan.ndjson';
const outJsonPath = 'assets/wilayah/kelurahan.json';
const kecamatanPath = 'assets/wilayah/kecamatan.json';

Future<void> main(List<String> args) async {
  if (args.isNotEmpty && args.first == 'finalize') {
    await finalizeNdjson();
    return;
  }
  await fetchAllVillagesResumable();
}

Future<void> fetchAllVillagesResumable() async {
  // Pastikan sumber kecamatan ada
  final kecFile = File(kecamatanPath);
  if (!kecFile.existsSync()) {
    stderr.writeln('$kecamatanPath not found. Generate kecamatan first.');
    exit(1);
  }
  final kecList = (jsonDecode(await kecFile.readAsString()) as List)
      .cast<Map<String, dynamic>>();

  // Muat progress yang sudah selesai
  final done = <String>{};
  final progFile = File(progressPath);
  if (progFile.existsSync()) {
    final m = jsonDecode(await progFile.readAsString()) as Map<String, dynamic>;
    done.addAll((m['done'] as List).map((e) => e.toString()));
  }

  // Siapkan NDJSON sink (append jika sudah ada)
  final ndjsonFile = File(ndjsonPath);
  final sink = ndjsonFile.openWrite(mode: FileMode.append);

  int processed = 0;
  for (final kec in kecList) {
    final kecId = kec['id'].toString();
    if (done.contains(kecId)) {
      processed++;
      continue; // sudah diambil sebelumnya
    }

    final villages = await _fetchVillagesWithRetry(kecId);
    for (final v in villages) {
      final line = jsonEncode({
        'id': v['id'].toString(),
        'id_kecamatan': kecId,
        'nama': v['name'].toString(),
      });
      sink.writeln(line);
    }

    // catat progress
    done.add(kecId);
    processed++;
    if (processed % 50 == 0) {
      await _saveProgress(done);
      stdout.writeln('✔ progress: $processed/${kecList.length}');
    }
  }

  await sink.flush();
  await sink.close();
  await _saveProgress(done);
  stdout.writeln('✅ Selesai fetch NDJSON. Jalankan finalize:');
  stdout.writeln('   dart run tool/fetch_kelurahan_resumable.dart finalize');
}

Future<List<Map<String, dynamic>>> _fetchVillagesWithRetry(String kecId) async {
  final url = Uri.parse('$base/villages/$kecId.json');
  const maxAttempts = 6;
  final rnd = Random();

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final res = await http
          .get(
            url,
            headers: {
              'User-Agent': 'flutter_wilayah_indonesia/1.0 (tool fetch)',
            },
          )
          .timeout(const Duration(seconds: 25));
      // Sukses
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        return list;
      }

      // 404 = tidak ada data → kembalikan kosong, jangan gagal total
      if (res.statusCode == 404) {
        return const <Map<String, dynamic>>[];
      }

      // 429/5xx = rate limit/server error → retry
      if (res.statusCode == 429 ||
          (res.statusCode >= 500 && res.statusCode < 600)) {
        final delayMs = (800 * attempt * attempt) + rnd.nextInt(400);
        stdout.writeln(
          '↻ ($attempt/$maxAttempts) $kecId status ${res.statusCode}, retry in ${delayMs}ms',
        );
        await Future.delayed(Duration(milliseconds: delayMs));
        continue;
      }

      // Lainnya: throw
      throw HttpException('HTTP ${res.statusCode} for $kecId');
    } catch (e) {
      if (attempt == maxAttempts) {
        stderr.writeln(
          '❌ Gagal ambil villages $kecId setelah $maxAttempts attempts: $e',
        );
        // Terakhir: anggap kosong agar proses lanjut (atau rethrow jika ingin berhenti)
        return const <Map<String, dynamic>>[];
      }
      final backoffMs = 600 * attempt * attempt + rnd.nextInt(300);
      stdout.writeln(
        '⚠ ($attempt/$maxAttempts) error $kecId: $e → retry in ${backoffMs}ms',
      );
      await Future.delayed(Duration(milliseconds: backoffMs));
    }
  }
  return const <Map<String, dynamic>>[];
}

Future<void> _saveProgress(Set<String> done) async {
  final progFile = File(progressPath);
  await progFile.create(recursive: true);
  await progFile.writeAsString(jsonEncode({'done': done.toList()}));
}

/// Gabungkan NDJSON → JSON array minified
Future<void> finalizeNdjson() async {
  final nd = File(ndjsonPath);
  if (!nd.existsSync()) {
    stderr.writeln('$ndjsonPath not found. Jalankan fetch dulu.');
    exit(1);
  }
  final lines = await nd.readAsLines();
  final list = <Map<String, dynamic>>[];
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    list.add(jsonDecode(line) as Map<String, dynamic>);
  }
  final out = File(outJsonPath);
  await out.create(recursive: true);
  await out.writeAsString(jsonEncode(list));
  stdout.writeln('✅ Wrote ${list.length} kelurahan → $outJsonPath');

  // opsional: bersihkan file progress & ndjson
  // await File(progressPath).delete().catchError((_) {});
  // await nd.delete().catchError((_) {});
}
