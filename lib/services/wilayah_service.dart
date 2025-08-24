import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/provinsi_model.dart';

class WilayahService {
  // load data provinsi dari provinsi.json
  static Future<List<Provinsi>> loadProvinsi() async {
    final String jsonStr = await rootBundle.loadString('assets/wilayah/provinsi.json');
    final List<dynamic> jsonList = json.decode(jsonStr);

    return jsonList.map((e) => Provinsi.fromJson(e)).toList();
  }
}
