import 'package:app001/models/product.dart';
import 'package:app001/pages/login_page.dart';
import 'package:app001/pages/product_form_page.dart';
import 'package:app001/services/product_service.dart';
import 'package:app001/services/session.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatefulWidget {
  final bool isAdmin;

  const ProductPage({super.key, this.isAdmin = false});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ProductService productService = ProductService();

  late Future<List<Product>> productsFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = productService.getProducts();
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

  Future<bool> _confirmDelete(Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Está seguro de que desea eliminar "${product.names}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _refreshProducts() {
    setState(() {
      productsFuture = productService.getProducts();
    });
  }

  void _logout() {
    Session.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestor de productos"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                widget.isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 16,
              ),
              label: Text(widget.isAdmin ? 'Administrador' : 'Usuario'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await showDialog<bool>(
                  context: context,
                  builder: (context) => const ProductFormPage(),
                );
                if (mounted) {
                  _refreshProducts();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: FutureBuilder<List<Product>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            String errorMessage;
            if (error is ProductServiceException && error.isConnectionError) {
              errorMessage = 'No se pudo conectar con el servidor. Verifique su conexión a internet.';
            } else {
              errorMessage = error is ProductServiceException
                  ? error.message
                  : 'Algo salió mal. Inténtelo de nuevo más tarde.';
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refreshProducts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron productos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (widget.isAdmin) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Toque + para agregar su primer producto',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(product.names.isEmpty
                        ? '?'
                        : product.names[0].toUpperCase()),
                  ),
                  title: Text(
                    product.names,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.attach_money, size: 16),
                          label: Text('${product.price}'),
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.inventory, size: 16),
                          label: Text('Existencias: ${product.stock}'),
                        ),
                      ],
                    ),
                  ),
                  trailing: widget.isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Editar',
                              onPressed: () async {
                                await showDialog<bool>(
                                  context: context,
                                  builder: (context) =>
                                      ProductFormPage(product: product),
                                );
                                if (mounted) {
                                  _refreshProducts();
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Eliminar',
                              onPressed: () async {
                                final confirmed = await _confirmDelete(product);
                                if (confirmed) {
                                  try {
                                    await productService.deleteProduct(product.id ?? 0);
                                    if (mounted) {
                                      _showSuccessSnackbar('Producto eliminado correctamente');
                                      _refreshProducts();
                                    }
                                  } on ProductServiceException catch (e) {
                                    if (mounted) {
                                      _showErrorSnackbar(e.message);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      _showErrorSnackbar('No se pudo eliminar el producto. Inténtelo de nuevo.');
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
