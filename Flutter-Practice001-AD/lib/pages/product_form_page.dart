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
  bool _allowPop = false; // Define the maximum stock limit

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  final ProductService productService = ProductService();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      nameController.text = widget.product!.names;
      priceController.text = widget.product!.price.toString();
      stockController.text = widget.product!.stock.toString();
    }
  }

  bool get _hasUnsavedChanges {
    if (widget.product == null) {
      return nameController.text.trim().isNotEmpty ||
          priceController.text.trim().isNotEmpty ||
          stockController.text.trim().isNotEmpty;
    }

    return nameController.text.trim() != widget.product!.names ||
        priceController.text.trim() != widget.product!.price.toString() ||
        stockController.text.trim() != widget.product!.stock.toString();
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
      final product = Product(
        id: widget.product?.id ?? 0,
        names: nameController.text.trim(),
        price: double.tryParse(priceController.text) ?? 0.0,
        stock: int.tryParse(stockController.text) ?? 0,
        version: widget.product?.version ?? 1,
        descriptions: widget.product?.descriptions,
        imageUrl: widget.product?.imageUrl,
        isActive: widget.product?.isActive ?? true,
      );

      if (widget.product != null) {
        final updatedProduct = await productService.updateProduct(product);
        if (mounted) {
          if (updatedProduct != null) {
            _showSuccessSnackbar('Producto actualizado correctamente');
            Navigator.pop(context, true);
          }
        }
      } else {
        await productService.createProduct(product);
        if (mounted) {
          _showSuccessSnackbar('Producto guardado correctamente');
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
        _showErrorSnackbar('Ocurrió un error inesperado. Inténtelo de nuevo.');
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
        title: const Text('Conflicto de actualización'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              Navigator.pop(context, true); // Close form and refresh list
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context:context,
      builder: (context) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('Tiene cambios sin guardar. ¿Desea descartarlos y salir?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar')
          ),
          TextButton(
            onPressed: (){
              Navigator.pop(context, true);
            },
            child: const Text('Descartar')
          )
        ]
      )
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context){
    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if(didPop){
          return;
        }

        final shouldExit = await _confirmExit();

        if(!shouldExit || !mounted){
          return;
        }

        setState((){
          _allowPop = true;
        });

        Navigator.pop(context);
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                widget.product != null ? "Editar producto" : "Nuevo producto",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                onChanged: (){
                  setState(() {});
                },
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                        LengthLimitingTextInputFormatter(100),
                      ],
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        labelText: "Nombre",
                        border: OutlineInputBorder(),
                        hintText: "De 3 a 100 caracteres",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingrese un nombre";
                        }
                        if (value.trim().length < 3) {
                          return "El nombre debe tener al menos 3 caracteres";
                        }
                        if (value.trim().length > 100) {
                          return "El nombre no puede exceder 100 caracteres";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d{1,8}\.?\d{0,2}')),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final regex = RegExp(r'^\d{0,8}(\.\d{0,2})?$');

                          return regex.hasMatch(newValue.text)
                              ? newValue
                              : oldValue;
                        }),
                      ],
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        labelText: "Precio",
                        border: OutlineInputBorder(),
                        hintText: "Máximo 10 dígitos, 2 decimales (ej. 12345678.99)",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingrese un precio";
                        }
                        if (value.contains(' ')) {
                          return "No se permiten espacios";
                        }
                        final price = double.tryParse(value);
                        if (price == null) {
                          return "Ingrese un precio válido";
                        }
                        if (price <= 0) {
                          return "El precio no puede ser cero ni negativo";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
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
                        labelText: "Existencias",
                        border: OutlineInputBorder(),
                        hintText: "Ingrese un número entero",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingrese la cantidad de existencias";
                        }
                        if (value.contains(' ')) {
                          return "No se permiten espacios";
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return "Solo se permiten números enteros";
                        }
                        final stock = int.tryParse(value);
                        if (stock == null) {
                          return "Ingrese una cantidad de existencias válida";
                        }
                        if (stock < 0) {
                          return "Las existencias no pueden ser negativas";
                        }
                        return null;
                      },
                    ),
                  ]
                )   
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.maybePop(context),
                    child: const Text("Cancelar"),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
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
                        : Text(widget.product != null ? "Actualizar" : "Guardar"),
                  ),
                ],
              ),
            ]
          )
          )
        )
      )
    );
  }


}