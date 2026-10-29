import 'package:app001/models/product.dart';
import 'package:app001/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;

class ProductFormPage extends StatefulWidget {
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _allowPop = false;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();

  // Control para "Esta Activo" (Switch)
  bool _isActive = true;

  final ProductService productService = ProductService();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      nameController.text = widget.product!.names;
      priceController.text = widget.product!.price.toString();
      stockController.text = widget.product!.stock.toString();
      descriptionController.text = widget.product!.description ?? '';
      imageUrlController.text = widget.product!.imageUrl ?? '';
      _isActive = widget.product!.isActive;
    }
  }

  bool get _hasUnsavedChanges {
    if (widget.product == null) {
      return nameController.text.trim().isNotEmpty ||
          priceController.text.trim().isNotEmpty ||
          stockController.text.trim().isNotEmpty ||
          descriptionController.text.trim().isNotEmpty ||
          imageUrlController.text.trim().isNotEmpty;
    }

    return nameController.text.trim() != widget.product!.names ||
        priceController.text.trim() != widget.product!.price.toString() ||
        stockController.text.trim() != widget.product!.stock.toString() ||
        descriptionController.text.trim() != (widget.product!.description ?? '') ||
        imageUrlController.text.trim() != (widget.product!.imageUrl ?? '') ||
        _isActive != widget.product!.isActive;
  }

  // Validar si una cadena es una URL válida de imagen
  bool _isValidImageUrl(String url) {
    if (url.trim().isEmpty) return true; // URL vacía es válida (opcional)
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  // Widget para previsualizar imagen desde URL
  Widget _buildImageUrlPreview() {
    final url = imageUrlController.text.trim();

    if (url.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'No hay URL de imagen',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Validar que sea una URL válida
    if (!_isValidImageUrl(url)) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
              const SizedBox(height: 8),
              Text(
                'URL de imagen inválida',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.red.shade50,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 40, color: Colors.red.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No se pudo cargar la imagen',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey.shade100,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> saveUpdateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrl = imageUrlController.text.trim();
      final product = Product(
        id: widget.product?.id ?? 0,
        names: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.tryParse(priceController.text) ?? 0.0,
        stock: int.tryParse(stockController.text) ?? 0,
        isActive: _isActive,
        version: widget.product?.version ?? 1,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
      );

      if (widget.product != null) {
        final updatedProduct = await productService.updateProduct(product);
        if (mounted) {
          if (updatedProduct != null) {
            _showSuccessSnackbar('Product updated successfully');
            Navigator.pop(context, true);
          }
        }
      } else {
        await productService.createProduct(product);
        if (mounted) {
          _showSuccessSnackbar('Product saved successfully');
          Navigator.pop(context, true);
        }
      }
    } on ProductVersionConflictException catch (e) {
      if (mounted) {
        _showVersionConflictDialog(e.message);
      }
    } on ProductServiceException catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showVersionConflictDialog(String message) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Conflict'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              Navigator.pop(context, true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them and exit?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
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
        if (didPop) {
          return;
        }

        final shouldExit = await _confirmExit();

        if (!shouldExit || !mounted) {
          return;
        }

        setState(() {
          _allowPop = true;
        });

        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: widget.product != null ? Text("Edit Product") : Text("New Product"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                onChanged: () {
                  setState(() {});
                },
                child: Column(
                  children: [
                    // CAMPO NOMBRE
                    TextFormField(
                      controller: nameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                        LengthLimitingTextInputFormatter(100),
                      ],
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        labelText: "Name",
                        border: OutlineInputBorder(),
                        hintText: "3-100 characters",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a name";
                        }
                        if (value.trim().length < 3) {
                          return "Name must have at least 3 characters";
                        }
                        if (value.trim().length > 100) {
                          return "Name cannot exceed 100 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // CAMPO DESCRIPCION
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      maxLength: 200,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(200),
                      ],
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        labelText: "Description",
                        border: OutlineInputBorder(),
                        hintText: "Enter product description (max 200 characters)",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a description";
                        }
                        if (value.trim().length < 10) {
                          return "Description must have at least 10 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // SWITCH "ESTA ACTIVO"
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _isActive ? 'Product is active' : 'Product is inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // CAMPO PRECIO
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d{1,8}\.?\d{0,2}')),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final regex = RegExp(r'^\d{0,8}(\.\d{0,2})?$');

                          return regex.hasMatch(newValue.text) ? newValue : oldValue;
                        }),
                      ],
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        labelText: "Price",
                        border: OutlineInputBorder(),
                        hintText: "Max 10 digits, 2 decimals (e.g. 12345678.99)",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a price";
                        }
                        if (value.contains(' ')) {
                          return "Spaces are not allowed";
                        }
                        final price = double.tryParse(value);
                        if (price == null) {
                          return "Please enter a valid price";
                        }
                        if (price <= 0) {
                          return "Price cannot be zero or negative";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // CAMPO STOCK
                    TextFormField(
                      controller: stockController,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        FilteringTextInputFormatter.deny(RegExp(r'[^0-9]')),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (newValue.text.isEmpty) {
                            return newValue;
                          }

                          const maxStock = 2147483647;
                          const maxDigits = 10;

                          if (newValue.text.length > maxDigits) {
                            return oldValue;
                          }

                          final value = int.tryParse(newValue.text);

                          if (value == null) {
                            return oldValue;
                          }

                          if (value > maxStock) {
                            final maxValue = maxStock.toString();

                            return TextEditingValue(
                              text: maxValue,
                              selection: TextSelection.collapsed(
                                offset: maxValue.length,
                              ),
                            );
                          }
                          return newValue;
                        }),
                      ],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        labelText: "Stock",
                        border: OutlineInputBorder(),
                        hintText: "Enter a whole number (integer only)",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a stock quantity";
                        }
                        if (value.contains(' ')) {
                          return "Spaces are not allowed";
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return "Only whole numbers are allowed";
                        }
                        final stock = int.tryParse(value);
                        if (stock == null) {
                          return "Please enter a valid stock quantity";
                        }
                        if (stock < 0) {
                          return "Stock cannot be negative";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // SECCIÓN DE URL DE IMAGEN
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Image URL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: imageUrlController,
                      keyboardType: TextInputType.url,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(200),
                      ],
                      decoration: InputDecoration(
                        alignLabelWithHint: true,
                        labelText: "Image URL",
                        border: const OutlineInputBorder(),
                        hintText: "https://example.com/image.jpg",
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !_isValidImageUrl(value)) {
                          return "Please enter a valid URL (http:// or https://)";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter a valid image URL (http:// or https://)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildImageUrlPreview(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : saveUpdateProduct,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.product != null ? "Update" : "Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
