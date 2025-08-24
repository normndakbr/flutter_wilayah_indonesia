// models/kabupaten_model.dart
class Kabupaten {
  final String id;
  final String idProvinsi;
  final String nama;

  Kabupaten({required this.id, required this.idProvinsi, required this.nama});

  factory Kabupaten.fromJson(Map<String, dynamic> json) {
    return Kabupaten(
      id: json['id'],
      idProvinsi: json['id_provinsi'],
      nama: json['nama'],
    );
  }
}
