import 'package:flutter/material.dart';

import '../models/provinsi_model.dart';
import '../models/kabupaten_model.dart';
import '../models/kecamatan_model.dart';
import '../models/kelurahan_model.dart';
import '../services/wilayah_service.dart';

/// A form-friendly cascading dropdown for Indonesian administrative areas
/// (Province → Regency/City → District → Village). Uses offline JSON datasets
/// and in-memory caching. See README for usage & examples.
/// 
/// A cascading dropdown for Indonesian regions:
/// Province → Regency/City → District → Village.
///
/// Example:
/// ```dart
/// WilayahPicker(
///   onProvinsiChanged: (p) {},
///   onKabupatenChanged: (k) {},
///   onKecamatanChanged: (kec) {},
///   onKelurahanChanged: (kel) {},
/// )
/// ```
class WilayahPicker extends StatefulWidget {
  const WilayahPicker({
    super.key,
    this.initialProvId,
    this.initialKabId,
    this.initialKecId,
    this.initialKelId,
    this.includeKelurahan = true,
    this.enabled = true,
    this.provLabel = 'Provinsi',
    this.kabLabel = 'Kabupaten/Kota',
    this.kecLabel = 'Kecamatan',
    this.kelLabel = 'Kelurahan/Desa',
    this.spacing = const SizedBox(height: 12),
    this.titleCaseDisplay = true,
    this.onProvinsiChanged,
    this.onKabupatenChanged,
    this.onKecamatanChanged,
    this.onKelurahanChanged,
  });

  final String? initialProvId, initialKabId, initialKecId, initialKelId;

  /// Show the 4th level (Villages). Set to false if you only need up to district.
  final bool includeKelurahan;

  final bool enabled;

  final String provLabel, kabLabel, kecLabel, kelLabel;
  final Widget spacing;

  /// Convert dataset (usually uppercase) into Title Case when displayed.
  final bool titleCaseDisplay;

  final ValueChanged<Provinsi?>? onProvinsiChanged;
  final ValueChanged<Kabupaten?>? onKabupatenChanged;
  final ValueChanged<Kecamatan?>? onKecamatanChanged;
  final ValueChanged<Kelurahan?>? onKelurahanChanged;

  @override
  State<WilayahPicker> createState() => _WilayahPickerState();
}

class _WilayahPickerState extends State<WilayahPicker> {
  // Data lists
  List<Provinsi> _provList = [];
  List<Kabupaten> _kabList = [];
  List<Kecamatan> _kecList = [];
  List<Kelurahan> _kelList = [];

  // Caches by parent id (avoid re-filter / reload)
  final Map<String, List<Kabupaten>> _kabCache = {};
  final Map<String, List<Kecamatan>> _kecCache = {};
  final Map<String, List<Kelurahan>> _kelCache = {};

  // Selections
  String? _provId, _kabId, _kecId, _kelId;

  // Loading flags
  bool _loadingProv = true, _loadingKab = false, _loadingKec = false, _loadingKel = false;

  // Request tokens to prevent race-condition applying stale responses
  int _kabReq = 0, _kecReq = 0, _kelReq = 0;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    // Load provinsi
    _provList = await WilayahService.getProvinsi();
    _provId = widget.initialProvId;

    // Drill down initial selections (if provided)
    if (_provId != null && _provId!.isNotEmpty) {
      setState(() => _loadingKab = true);
      _kabList = await _getKabupaten(_provId!);
      _loadingKab = false;

      _kabId = widget.initialKabId;
      if (_kabId != null && _kabId!.isNotEmpty) {
        setState(() => _loadingKec = true);
        _kecList = await _getKecamatan(_kabId!);
        _loadingKec = false;

        _kecId = widget.initialKecId;
        if (widget.includeKelurahan && _kecId != null && _kecId!.isNotEmpty) {
          setState(() => _loadingKel = true);
          _kelList = await _getKelurahan(_kecId!);
          _loadingKel = false;
          _kelId = widget.initialKelId;
        }
      }
    }

    _loadingProv = false;
    if (mounted) setState(() {});
  }

  // ---------- Cached loaders ----------
  Future<List<Kabupaten>> _getKabupaten(String provId) async {
    if (_kabCache.containsKey(provId)) return _kabCache[provId]!;
    final list = await WilayahService.getKabupatenByProvinsi(provId);
    _kabCache[provId] = list;
    return list;
  }

  Future<List<Kecamatan>> _getKecamatan(String kabId) async {
    if (_kecCache.containsKey(kabId)) return _kecCache[kabId]!;
    final list = await WilayahService.getKecamatanByKabupaten(kabId);
    _kecCache[kabId] = list;
    return list;
  }

  Future<List<Kelurahan>> _getKelurahan(String kecId) async {
    if (_kelCache.containsKey(kecId)) return _kelCache[kecId]!;
    final list = await WilayahService.getKelurahanByKecamatan(kecId);
    _kelCache[kecId] = list;
    return list;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // PROVINSI
        DropdownButtonFormField<String>(
          value: _provId?.isNotEmpty == true ? _provId : null,
          items: _provList
              .map((p) => DropdownMenuItem(value: p.id, child: Text(_disp(p.nama))))
              .toList(),
          onChanged: (!widget.enabled || _loadingProv)
              ? null
              : (val) async {
                  if (val == _provId) return;
                  // Reset chain
                  setState(() {
                    _provId = val;
                    _kabList = [];
                    _kecList = [];
                    _kelList = [];
                    _kabId = _kecId = _kelId = null;
                    _loadingKab = true;
                  });

                  // Fire callback
                  widget.onProvinsiChanged?.call(
                    _provList.firstWhere(
                      (e) => e.id == _provId,
                      orElse: () => Provinsi(id: '', nama: ''),
                    ),
                  );

                  // Load kabupaten for selected provinsi
                  List<Kabupaten> nextKab = [];
                  if (val != null && val.isNotEmpty) {
                    final myReq = ++_kabReq;
                    nextKab = await _getKabupaten(val);
                    if (!mounted || myReq != _kabReq) return;
                  }
                  setState(() {
                    _kabList = nextKab;
                    _loadingKab = false;
                  });
                },
          // ↓ selalu panah bawah
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconSize: 24,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: widget.provLabel,
          ),
        ),

        widget.spacing,

        // KABUPATEN
        DropdownButtonFormField<String>(
          value: _kabId?.isNotEmpty == true ? _kabId : null,
          items: _kabList
              .map((k) => DropdownMenuItem(value: k.id, child: Text(_disp(k.nama))))
              .toList(),
          onChanged: (!widget.enabled || _loadingKab || _provId == null)
              ? null
              : (val) async {
                  if (val == _kabId) return;

                  setState(() {
                    _kabId = val;
                    _kecList = [];
                    _kelList = [];
                    _kecId = _kelId = null;
                    _loadingKec = true;
                  });

                  widget.onKabupatenChanged?.call(
                    _kabList.firstWhere(
                      (e) => e.id == _kabId,
                      orElse: () => Kabupaten(id: '', idProvinsi: '', nama: ''),
                    ),
                  );

                  // Load kecamatan
                  List<Kecamatan> nextKec = [];
                  if (val != null && val.isNotEmpty) {
                    final myReq = ++_kecReq;
                    nextKec = await _getKecamatan(val);
                    if (!mounted || myReq != _kecReq) return;
                  }
                  setState(() {
                    _kecList = nextKec;
                    _loadingKec = false;
                  });
                },
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconSize: 24,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: widget.kabLabel,
            helperText: (_provId == null) ? 'Pilih provinsi terlebih dahulu' : null,
          ),
        ),

        widget.spacing,

        // KECAMATAN
        DropdownButtonFormField<String>(
          value: _kecId?.isNotEmpty == true ? _kecId : null,
          items: _kecList
              .map((kec) => DropdownMenuItem(value: kec.id, child: Text(_disp(kec.nama))))
              .toList(),
          onChanged: (!widget.enabled || _loadingKec || _kabId == null)
              ? null
              : (val) async {
                  if (val == _kecId) return;

                  setState(() {
                    _kecId = val;
                    _kelList = [];
                    _kelId = null;
                    _loadingKel = widget.includeKelurahan;
                  });

                  widget.onKecamatanChanged?.call(
                    _kecList.firstWhere(
                      (e) => e.id == _kecId,
                      orElse: () => Kecamatan(id: '', idKabupaten: '', nama: ''),
                    ),
                  );

                  if (!widget.includeKelurahan) {
                    setState(() => _loadingKel = false);
                    return;
                  }

                  // Load kelurahan
                  List<Kelurahan> nextKel = [];
                  if (val != null && val.isNotEmpty) {
                    final myReq = ++_kelReq;
                    nextKel = await _getKelurahan(val);
                    if (!mounted || myReq != _kelReq) return;
                  }
                  setState(() {
                    _kelList = nextKel;
                    _loadingKel = false;
                  });
                },
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconSize: 24,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: widget.kecLabel,
            helperText: (_kabId == null) ? 'Pilih kabupaten/kota terlebih dahulu' : null,
          ),
        ),

        if (widget.includeKelurahan) ...[
          widget.spacing,

          // KELURAHAN
          DropdownButtonFormField<String>(
            value: _kelId?.isNotEmpty == true ? _kelId : null,
            items: _kelList
                .map((kel) => DropdownMenuItem(value: kel.id, child: Text(_disp(kel.nama))))
                .toList(),
            onChanged: (!widget.enabled || _loadingKel || _kecId == null)
                ? null
                : (val) {
                    if (val == _kelId) return;
                    setState(() => _kelId = val);
                    widget.onKelurahanChanged?.call(
                      _kelList.firstWhere(
                        (e) => e.id == _kelId,
                        orElse: () => Kelurahan(id: '', idKecamatan: '', nama: ''),
                      ),
                    );
                  },
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            iconSize: 24,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: widget.kelLabel,
              helperText: (_kecId == null) ? 'Pilih kecamatan terlebih dahulu' : null,
            ),
          ),
        ],

        // ↓ satu indikator status di bawah semua dropdown
        _buildLoadingHint(),
      ],
    );
  }

  String _disp(String s) => widget.titleCaseDisplay ? _titleCase(s) : s;

  // Very simple Title Case for uppercase dataset + keep common acronyms
  String _titleCase(String input) {
    final words = input.toLowerCase().split(RegExp(r'\\s+')).map((w) {
      if (w.isEmpty) return w;
      const acronyms = {'dki', 'diy', 'ri', 'tk', 'rt', 'rw'};
      if (acronyms.contains(w)) return w.toUpperCase();
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
    }).toList();
    return words.join(' ');
  }

  // ---- Loading status area (single row) ----
  Widget _buildLoadingHint() {
    final t = _loadingText();
    if (t == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(t),
        ],
      ),
    );
  }

  String? _loadingText() {
    if (_loadingProv) return 'Memuat data provinsi...';
    if (_loadingKab) return 'Memuat data kabupaten/kota...';
    if (_loadingKec) return 'Memuat data kecamatan...';
    if (_loadingKel) return 'Memuat data kelurahan/desa...';
    return null;
  }
}
