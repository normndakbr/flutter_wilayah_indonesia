class Kecamatan {
  final String id; // e.g. 1101010
  final String idKabupaten; // e.g. 1101
  final String nama; // e.g. "TEUPAH SELATAN"

  Kecamatan({required this.id, required this.idKabupaten, required this.nama});

  factory Kecamatan.fromJson(Map<String, dynamic> json) => Kecamatan(
    id: json['id'].toString(),
    idKabupaten: json['id_kabupaten'].toString(),
    nama: json['nama'].toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'id_kabupaten': idKabupaten,
    'nama': nama,
  };

  @override
  String toString() => '$nama ($id)';
}
