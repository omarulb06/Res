import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/venue.dart';
import '../../models/venue_unit.dart';
import '../../providers/venue_provider.dart';

class OwnerVenueEditScreen extends StatefulWidget {
  final String ownerId;
  final Venue? existing;
  const OwnerVenueEditScreen({
    super.key,
    required this.ownerId,
    this.existing,
  });

  @override
  State<OwnerVenueEditScreen> createState() => _OwnerVenueEditScreenState();
}

class _OwnerVenueEditScreenState extends State<OwnerVenueEditScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _location;
  late TextEditingController _imageUrl;
  late TextEditingController _accessCode;
  late bool _isPublic;
  late VenueCategory _category;
  late List<VenueUnit> _units;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _title = TextEditingController(text: v?.title ?? '');
    _description = TextEditingController(text: v?.description ?? '');
    _location = TextEditingController(text: v?.location ?? '');
    _imageUrl = TextEditingController(text: v?.imageUrl ?? '');
    _accessCode = TextEditingController(text: v?.accessCode ?? '');
    _isPublic = v?.isPublic ?? true;
    _category = v?.category ?? VenueCategory.mixed;
    _units = List.of(v?.units ?? const []);
    if (_units.isEmpty) {
      _units.add(const VenueUnit(
        unitId: 'u1',
        name: 'Main Hall',
        capacity: 100,
        pricePerDay: 300,
      ));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _imageUrl.dispose();
    _accessCode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_isPublic) {
      final code = _accessCode.text.trim();
      if (code.length < 4 || code.length > 6) {
        _snack('Access code must be 4–6 digits.');
        return;
      }
    }
    if (_units.isEmpty) {
      _snack('Add at least one unit.');
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.existing?.id ??
          'v-${DateTime.now().microsecondsSinceEpoch}';
      final venue = Venue(
        id: id,
        ownerId: widget.ownerId,
        title: _title.text.trim(),
        description: _description.text.trim(),
        location: _location.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        isPublic: _isPublic,
        accessCode: _isPublic ? null : _accessCode.text.trim(),
        isApprovedByAdmin: widget.existing?.isApprovedByAdmin ?? false,
        category: _category,
        units: _units,
      );
      await context.read<VenueProvider>().save(venue);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit venue' : 'New venue')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Venue name',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location / address',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _imageUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Hero image URL (optional)',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SegmentedButton<VenueCategory>(
              segments: const [
                ButtonSegment(
                    value: VenueCategory.indoor,
                    label: Text('Indoor'),
                    icon: Icon(Icons.house_outlined)),
                ButtonSegment(
                    value: VenueCategory.outdoor,
                    label: Text('Outdoor'),
                    icon: Icon(Icons.park_outlined)),
                ButtonSegment(
                    value: VenueCategory.mixed,
                    label: Text('Mixed'),
                    icon: Icon(Icons.join_full_outlined)),
              ],
              selected: {_category},
              onSelectionChanged: (s) => setState(() => _category = s.first),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              title: const Text('Public listing'),
              subtitle: Text(_isPublic
                  ? 'Anyone can view and reserve.'
                  : 'Visible only with your 4–6 digit access code.'),
              secondary: Icon(_isPublic ? Icons.public : Icons.lock_outline),
              contentPadding: EdgeInsets.zero,
            ),
            if (!_isPublic) ...[
              TextFormField(
                controller: _accessCode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Access code (4–6 digits)',
                  prefixIcon: Icon(Icons.pin_outlined),
                  counterText: '',
                ),
                validator: (v) {
                  if (_isPublic) return null;
                  if (v == null || v.length < 4 || v.length > 6) {
                    return 'Enter 4–6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
            ],
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text('Units / Areas',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _units.add(VenueUnit(
                      unitId: 'u${_units.length + 1}',
                      name: 'New unit',
                      capacity: 50,
                      pricePerDay: 100,
                    ));
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('Add unit'),
                ),
              ],
            ),
            Text(
              'Each unit can be reserved independently on the same date.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _units.length; i++)
              _UnitEditor(
                key: ValueKey(_units[i].unitId),
                unit: _units[i],
                onChanged: (u) => setState(() => _units[i] = u),
                onDelete: _units.length == 1
                    ? null
                    : () => setState(() => _units.removeAt(i)),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isEdit ? 'Save changes' : 'Create venue'),
            ),
            if (!isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'New venues require admin approval before appearing to clients.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.outline, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UnitEditor extends StatefulWidget {
  final VenueUnit unit;
  final ValueChanged<VenueUnit> onChanged;
  final VoidCallback? onDelete;

  const _UnitEditor({
    super.key,
    required this.unit,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_UnitEditor> createState() => _UnitEditorState();
}

class _UnitEditorState extends State<_UnitEditor> {
  late TextEditingController _name;
  late TextEditingController _capacity;
  late TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.unit.name);
    _capacity = TextEditingController(text: '${widget.unit.capacity}');
    _price = TextEditingController(text: '${widget.unit.pricePerDay.toStringAsFixed(0)}');
  }

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(widget.unit.copyWith(
      name: _name.text.trim(),
      capacity: int.tryParse(_capacity.text) ?? 0,
      pricePerDay: double.tryParse(_price.text) ?? 0.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Unit name'),
                    onChanged: (_) => _emit(),
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Capacity',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price / day',
                      prefixText: '\$ ',
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
