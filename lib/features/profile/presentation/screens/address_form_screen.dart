import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../shared/widgets/states.dart';
import '../../data/address_repository.dart';

class AddressFormScreen extends StatefulWidget {
  final int? addressId;
  const AddressFormScreen({super.key, this.addressId});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AddressRepository();
  bool _saving = false;
  bool _loading = false;

  final _label = TextEditingController();
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _province = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _village = TextEditingController();
  final _postal = TextEditingController();
  final _notes = TextEditingController();
  bool _isPrimary = false;

  bool get _isEdit => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.list();
      final match = list.firstWhere(
        (a) => a.id == widget.addressId,
        orElse: () => list.first,
      );
      _label.text = match.label ?? '';
      _recipient.text = match.recipient;
      _phone.text = match.phone;
      _line1.text = match.addressLine1;
      _line2.text = match.addressLine2 ?? '';
      _province.text = match.province;
      _city.text = match.city;
      _district.text = match.district;
      _village.text = match.village ?? '';
      _postal.text = match.postalCode;
      _notes.text = match.notes ?? '';
      _isPrimary = match.isPrimary;
    } catch (_) {
      /* ignore */
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _province.dispose();
    _city.dispose();
    _district.dispose();
    _village.dispose();
    _postal.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'label': _label.text.trim(),
      'recipient': _recipient.text.trim(),
      'phone': _phone.text.trim(),
      'address_line_1': _line1.text.trim(),
      if (_line2.text.trim().isNotEmpty) 'address_line_2': _line2.text.trim(),
      'province': _province.text.trim(),
      'city': _city.text.trim(),
      'district': _district.text.trim(),
      if (_village.text.trim().isNotEmpty) 'village': _village.text.trim(),
      'postal_code': _postal.text.trim(),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      'is_primary': _isPrimary,
    };
    try {
      if (_isEdit) {
        await _repo.update(widget.addressId!, body);
      } else {
        await _repo.create(body);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Alamat' : 'Alamat Baru')),
      body: _loading
          ? const LoadingIndicator()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  TextFormField(
                    controller: _label,
                    decoration: const InputDecoration(
                      labelText: 'Label (opsional, contoh: Rumah, Kantor)',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _recipient,
                    decoration: const InputDecoration(
                      labelText: 'Nama Penerima',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No. HP',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'No. HP wajib diisi';
                      if (!RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,10}$')
                          .hasMatch(v.trim())) {
                        return 'No. HP tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _line1,
                    decoration: const InputDecoration(
                      labelText: 'Alamat',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Alamat wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _line2,
                    decoration: const InputDecoration(
                      labelText: 'Detail (opsional)',
                      hintText: 'No. rumah, RT/RW, patokan',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _province,
                          decoration: const InputDecoration(
                            labelText: 'Provinsi',
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _city,
                          decoration: const InputDecoration(
                            labelText: 'Kota/Kabupaten',
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _district,
                          decoration: const InputDecoration(
                            labelText: 'Kecamatan',
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _village,
                          decoration: const InputDecoration(
                            labelText: 'Kelurahan (opsional)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _postal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kode Pos',
                      prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Kode pos wajib diisi';
                      if (!RegExp(r'^[0-9]{5}$').hasMatch(v.trim())) {
                        return 'Kode pos harus 5 digit';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile.adaptive(
                    value: _isPrimary,
                    onChanged: (v) => setState(() => _isPrimary = v),
                    title: const Text('Jadikan alamat utama'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LoadingButton(
                    onPressed: _saving ? null : _submit,
                    loading: _saving,
                    child: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Alamat'),
                  ),
                ],
              ),
            ),
    );
  }
}
