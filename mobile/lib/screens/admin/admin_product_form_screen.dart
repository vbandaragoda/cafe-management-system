import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';

/// Structured data-input screen (name, description, price, category,
/// image URL) for admins to create or edit a product — the
/// assignment's "at least one data-input screen" requirement, paired
/// with the Menu screen as the data-view counterpart. (Renamed from
/// AdminMenuFormScreen; category is now a real picker backed by
/// `/api/categories` instead of free text — category creation isn't
/// exposed to mobile, so admins pick from the existing list.)
class AdminProductFormScreen extends StatefulWidget {
  final Product? existing;
  const AdminProductFormScreen({super.key, this.existing});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _imageUrl;
  int? _categoryId;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(text: e != null ? e.price.toStringAsFixed(2) : '');
    _imageUrl = TextEditingController(text: e?.imageUrl ?? '');
    _categoryId = e?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final admin = context.read<AdminProvider>();
    final categoryName = admin.categories
        .where((c) => c.id == _categoryId)
        .map((c) => c.name)
        .firstOrNull;
    final product = Product(
      id: widget.existing?.id ?? 0,
      name: _name.text.trim(),
      description: _description.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      categoryId: _categoryId,
      categoryName: categoryName ?? widget.existing?.categoryName ?? 'Other',
      imageUrl: _imageUrl.text.trim(),
      status: widget.existing?.status ?? ProductStatus.available,
    );
    final ok = await admin.saveProduct(product, isNew: _isNew);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
    } else if (admin.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(admin.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Add Product' : 'Edit Product')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'Craft Flat White'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Double espresso, steamed milk...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price (\$)', hintText: '4.50'),
                      validator: (v) {
                        final parsed = double.tryParse((v ?? '').trim());
                        return (parsed == null || parsed <= 0) ? 'Enter a valid price' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in admin.categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(labelText: 'Image URL', hintText: 'https://...'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isNew ? 'Add Item' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
