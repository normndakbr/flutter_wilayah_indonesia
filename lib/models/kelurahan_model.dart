class Kelurahan {
  final String id; // e.g. 1101010001
  final String idKecamatan; // e.g. 1101010
  final String nama; // e.g. "LALANG"

  Kelurahan({required this.id, required this.idKecamatan, required this.nama});

  factory Kelurahan.fromJson(Map<String, dynamic> json) => Kelurahan(
    id: json['id'].toString(),
    idKecamatan: json['id_kecamatan'].toString(),
    nama: json['nama'].toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'id_kecamatan': idKecamatan,
    'nama': nama,
  };

  @override
  String toString() => '$nama ($id)';
}
