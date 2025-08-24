class Provinsi {
  final String id;
  final String nama;

  Provinsi({required this.id, required this.nama});

  factory Provinsi.fromJson(Map<String, dynamic> json) {
    return Provinsi(id: json['id'] as String, nama: json['nama'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama': nama};
  }

  @override
  String toString() => '$nama ($id)';
}
