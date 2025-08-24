# flutter\_wilayah\_indonesia

[![pub](https://img.shields.io/pub/v/flutter_wilayah_indonesia.svg)](https://pub.dev/packages/flutter_wilayah_indonesia)
[![points](https://img.shields.io/pub/points/flutter_wilayah_indonesia.svg)](https://pub.dev/packages/flutter_wilayah_indonesia/score)
[![likes](https://img.shields.io/pub/likes/flutter_wilayah_indonesia.svg)](https://pub.dev/packages/flutter_wilayah_indonesia)

Cascading Indonesian regions (**Provinsi → Kabupaten/Kota → Kecamatan → Kelurahan**) with **offline JSON datasets**, simple **services API**, and a ready‑to‑use **WilayahPicker** widget.

> No internet at runtime. Data is bundled with the package.

---

## ✨ Features

* Offline datasets: **provinsi, kabupaten/kota, kecamatan, kelurahan** (JSON)
* **`WilayahService`**: cached loaders + filter by parent
* **`WilayahPicker`**: plug‑and‑play cascading dropdown for forms
* Title‑case display option (dataset is UPPERCASE)
* Example app + unit & widget tests

---

## 🧩 Requirements

* **Dart** ≥ 3.8
* **Flutter** ≥ 1.17
* Platforms: Android, iOS, Web, macOS, Windows, Linux

---

## 🚀 Quick Start

Add the dependency in your app’s `pubspec.yaml` (if consuming from a path or pub.dev):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_wilayah_indonesia: ^0.1.0  # or use path: ../
```

### 1) Service usage

```dart
import 'package:flutter_wilayah_indonesia/flutter_wilayah_indonesia.dart';

Future<void> demo() async {
  final prov = await WilayahService.getProvinsi();
  final kab  = await WilayahService.getKabupatenByProvinsi('32'); // Jawa Barat
  final kec  = await WilayahService.getKecamatanByKabupaten(kab.first.id);
  final kel  = await WilayahService.getKelurahanByKecamatan(kec.first.id);
}
```

### 2) Widget usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_wilayah_indonesia/flutter_wilayah_indonesia.dart';

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: WilayahPicker(
        // initialProvId: '32',  // Example: preselect Jawa Barat
        // includeKelurahan: false, // up to Kecamatan only
      ),
    );
  }
}
```

#### Preselect & partial levels

```dart
WilayahPicker(
  initialProvId: '32',      // Jawa Barat
  includeKelurahan: false,  // stop at Kecamatan
  onKabupatenChanged: (k) => debugPrint(k?.nama),
)
```

#### Form integration (ringkas)

```dart
final _formKey = GlobalKey<FormState>();
Provinsi? _p; Kabupaten? _k; Kecamatan? _c; Kelurahan? _l;

Form(
  key: _formKey,
  child: WilayahPicker(
    onProvinsiChanged: (v) => _p = v,
    onKabupatenChanged: (v) => _k = v,
    onKecamatanChanged: (v) => _c = v,
    onKelurahanChanged: (v) => _l = v,
  ),
);
```

#### Headless / console usage (tanpa UI)

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_wilayah_indonesia/flutter_wilayah_indonesia.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prov = await WilayahService.getProvinsi();
  for (final p in prov.take(5)) debugPrint('${p.id} ${p.nama}');
  runApp(const SizedBox.shrink()); // no UI
}
```

---

## 🧰 API Overview

### `WilayahService`

* `Future<List<Provinsi>> getProvinsi()`
* `Future<List<Kabupaten>> getKabupatenByProvinsi(String provId)`
* `Future<List<Kecamatan>> getKecamatanByKabupaten(String kabId)`
* `Future<List<Kelurahan>> getKelurahanByKecamatan(String kecId)`
* `void clearCache()` – clear in‑memory caches (useful in tests)

> Loading is cached in memory. Repeated calls won’t re‑parse JSON.

### `WilayahPicker`

Configurable cascading dropdown:

* `initialProvId`, `initialKabId`, `initialKecId`, `initialKelId`
* `includeKelurahan` (default: `true`)
* `titleCaseDisplay` (default: `true`)
* Labels: `provLabel`, `kabLabel`, `kecLabel`, `kelLabel`
* Callbacks: `onProvinsiChanged`, `onKabupatenChanged`, `onKecamatanChanged`, `onKelurahanChanged`

---

## 📦 Assets & Setup

No extra setup needed for consumers. Datasets are declared as assets within this package and resolved via `rootBundle` using the `packages/<name>/...` path when required.

> If you fork/modify the package: assets live under `assets/wilayah/*.json` and are registered in this package’s `pubspec.yaml`.

---

## 🛠️ Troubleshooting: Unable to load asset (404)

Jika di web muncul 404 saat memuat JSON:

* Pastikan `pubspec.yaml` (package ini) mendeklarasikan assets:

  ```yaml
  flutter:
    assets:
      - assets/wilayah/provinsi.json
      - assets/wilayah/kabupaten.json
      - assets/wilayah/kecamatan.json
      - assets/wilayah/kelurahan.json
  ```
* Konstanta di service: `static const _pkg = 'flutter_wilayah_indonesia';`
* Setelah mengubah assets: `flutter clean && flutter pub get` (root & example).

---

## 🧪 Testing

This repo includes tests. To run from the package root:

```bash
flutter test
```

Tests use a small in‑memory dataset by mocking the `flutter/assets` channel so they don’t rely on the large JSON files.

---

## 🗂️ Data structure

All datasets are arrays of flat objects:

```json
// provinsi.json
[{ "id": "32", "nama": "JAWA BARAT" }]
```

```json
// kabupaten.json
[{ "id": "3273", "id_provinsi": "32", "nama": "KOTA BANDUNG" }]
```

```json
// kecamatan.json
[{ "id": "3273010", "id_kabupaten": "3273", "nama": "BOJONGLOA KALER" }]
```

```json
// kelurahan.json
[{ "id": "3273010002", "id_kecamatan": "3273010", "nama": "KELURAHAN Y" }]
```

---

## ⚙️ Updating datasets (maintainers)

We ship scripts under `tool/` to (re)generate datasets from a public source and write them into `assets/wilayah/`.

**Kabupaten:**

```bash
dart run tool/fetch_kabupaten.dart
```

**Kecamatan:** (with retry)

```bash
dart run tool/fetch_kecamatan.dart
```

**Kelurahan:** resumable (retry + resume + finalize)

```bash
# fetch with retry/resume → writes NDJSON + progress
dart run tool/fetch_kelurahan_resumable.dart
# finalize NDJSON → kelurahan.json
dart run tool/fetch_kelurahan_resumable.dart finalize
```

> Large file note: `kelurahan.json` can be sizable. Consider making `includeKelurahan` optional (already supported) or splitting per province if needed.

---

## 📐 Title Case display

The original dataset uses uppercase names. `WilayahPicker` can display title‑case (`titleCaseDisplay: true`), with a few common acronyms (e.g., DKI, DIY) preserved.

---

## 🗺️ Roadmap / Ideas

* Split large datasets per province to reduce bundle size
* Searchable dropdowns (type‑ahead)
* Localization for labels
* Helper: find by name/ID

Contributions are welcome!

---

## 🤝 Contributing

1. Fork & create a feature branch
2. Run `dart format .` and `dart analyze`
3. Add tests when possible
4. Open a PR ✨

---

## 🔗 Quick links

* Example app: [`example/`](./example)
* Changelog: [`CHANGELOG.md`](./CHANGELOG.md)
* Issues: use the repository issue tracker

---

## 📄 License

This project is licensed under the **MIT License**. See `LICENSE` for details.

---

## 📚 Data source / Credits

This package bundles offline datasets derived from
[emsifa/api-wilayah-indonesia](https://github.com/emsifa/api-wilayah-indonesia)
(snapshot: 2025‑08‑24). All credit goes to the original author(s).

If you redistribute the data, please retain attribution. A `NOTICE` file with third‑party license info is included for clarity.
