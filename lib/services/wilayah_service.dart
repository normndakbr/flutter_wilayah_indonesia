// lib/services/wilayah_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/provinsi_model.dart';
import '../models/kabupaten_model.dart';
import '../models/kecamatan_model.dart';
import '../models/kelurahan_model.dart';

class WilayahService {
  static const _pkg = 'flutter_wilayah_indonesia';

  static List<Provinsi>? _provinsi;
  static List<Kabupaten>? _kabupaten;
  static List<Kecamatan>? _kecamatan;
  static List<Kelurahan>? _kelurahan;

  // ---- helpers ----
  static Future<String> _load(String relativePath) async {
    // Saat dipakai dari app konsumen package:
    final pkgPath = 'packages/$_pkg/$relativePath';
    try {
      return await rootBundle.loadString(pkgPath);
    } catch (_) {
      // Saat dijalankan dari contoh/example di repo sendiri:
      return await rootBundle.loadString(relativePath);
    }
  }

  // ---- provinsi ----
  static Future<List<Provinsi>> getProvinsi() async {
    if (_provinsi != null) return _provinsi!;
    final raw = await _load('assets/wilayah/provinsi.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _provinsi = list.map((e) => Provinsi.fromJson(e)).toList();
    return _provinsi!;
  }

  // ---- kabupaten/kota ----
  static Future<List<Kabupaten>> _getAllKabupaten() async {
    if (_kabupaten != null) return _kabupaten!;
    final raw = await _load('assets/wilayah/kabupaten.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _kabupaten = list.map((e) => Kabupaten.fromJson(e)).toList();
    return _kabupaten!;
  }

  static Future<List<Kabupaten>> getKabupatenByProvinsi(String provId) async {
    final all = await _getAllKabupaten();
    return all.where((k) => k.idProvinsi == provId).toList();
  }

  // ---- kecamatan ----
  static Future<List<Kecamatan>> _getAllKecamatan() async {
    if (_kecamatan != null) return _kecamatan!;
    final raw = await _load('assets/wilayah/kecamatan.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _kecamatan = list.map((e) => Kecamatan.fromJson(e)).toList();
    return _kecamatan!;
  }

  static Future<List<Kecamatan>> getKecamatanByKabupaten(String kabId) async {
    final all = await _getAllKecamatan();
    return all.where((k) => k.idKabupaten == kabId).toList();
  }

  // ---- kelurahan/desa ----
  static Future<List<Kelurahan>> _getAllKelurahan() async {
    if (_kelurahan != null) return _kelurahan!;
    final raw = await _load('assets/wilayah/kelurahan.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _kelurahan = list.map((e) => Kelurahan.fromJson(e)).toList();
    return _kelurahan!;
  }

  static Future<List<Kelurahan>> getKelurahanByKecamatan(String kecId) async {
    final all = await _getAllKelurahan();
    return all.where((v) => v.idKecamatan == kecId).toList();
  }

  /// Optional: clear caches (mis. untuk testing)
  static void clearCache() {
    _provinsi = null;
    _kabupaten = null;
    _kecamatan = null;
    _kelurahan = null;
  }
}
