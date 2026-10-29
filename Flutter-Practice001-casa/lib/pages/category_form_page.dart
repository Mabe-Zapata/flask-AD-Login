import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;

class CategoryFormPage extends StatefulWidget {
  const CategoryFormPage({super.key});

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _allowPop = false;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  // Switch para categoría activa
  bool _isActive = true;


  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    return nameController.text.trim().isNotEmpty ||
        descriptionController.text.trim().isNotEmpty ||
        _isActive != true;
  }

 
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _saveCategory() {
    if (!_formKey.currentState!.validate()) return;

    _showSuccessSnackbar('Category saved successfully');

    Navigator.pop(context, {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'isActive': _isActive
    });
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them and exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _confirmExit();

        if (!shouldExit || !mounted) return;

        setState(() => _allowPop = true);
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("New Category"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo nombre
                TextFormField(
                  controller: nameController,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                    LengthLimitingTextInputFormatter(50),
                  ],
                  decoration: const InputDecoration(
                    labelText: "Category Name",
                    border: OutlineInputBorder(),
                    hintText: "Enter category name",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a category name";
                    }
                    if (value.trim().length < 2) {
                      return "Name must have at least 2 characters";
                    }
                    if (value.trim().length > 100) {
                      return "Name must not exceed characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

              
                const SizedBox(height: 25),

                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveCategory,
                    child: const Text("Save Category"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
