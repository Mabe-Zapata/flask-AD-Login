import 'dart:convert';
import 'dart:io';

import 'package:app001/models/product.dart';
import 'package:app001/services/session.dart';
import 'package:http/http.dart' as http;

class ProductServiceException implements Exception {
  final String message;
  final bool isConnectionError;

  ProductServiceException(this.message, {this.isConnectionError = false});

  @override
  String toString() => message;
}

class ProductVersionConflictException implements Exception {
  final String message;

  ProductVersionConflictException(this.message);

  @override
  String toString() => message;
}

class ProductService {
  final String url = "http://localhost:5000/api/Product";

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse(url), headers: Session.headers()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ProductServiceException(
            'No se pudo conectar con el servidor. Verifique su conexión a internet.',
            isConnectionError: true,
          );
        },
      );

      if (response.statusCode == 401) {
        throw ProductServiceException('Su sesión expiró. Inicie sesión nuevamente.');
      }
      if (response.statusCode == 200) {
        List datos = jsonDecode(response.body);
        return datos.map((item) => Product.fromJson(item)).toList();
      } else {
        throw ProductServiceException('No se pudieron cargar los productos. Inténtelo de nuevo.');
      }
    } on SocketException {
      throw ProductServiceException(
        'No se pudo conectar con el servidor. Verifique su conexión a internet.',
        isConnectionError: true,
      );
    } on ProductServiceException {
      rethrow;
    } catch (e) {
      throw ProductServiceException('Ocurrió un error inesperado. Inténtelo de nuevo.');
    }
  }

  Future<void> createProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: Session.headers(json: true),
        body: jsonEncode(product.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ProductServiceException(
            'No se pudo conectar con el servidor. Verifique su conexión a internet.',
            isConnectionError: true,
          );
        },
      );

      if (response.statusCode == 401) {
        throw ProductServiceException('Su sesión expiró. Inicie sesión nuevamente.');
      }
      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else {
        throw ProductServiceException('No se pudo guardar el producto. Inténtelo de nuevo.');
      }
    } on SocketException {
      throw ProductServiceException(
        'No se pudo conectar con el servidor. Verifique su conexión a internet.',
        isConnectionError: true,
      );
    } on ProductServiceException {
      rethrow;
    } catch (e) {
      throw ProductServiceException('Ocurrió un error inesperado. Inténtelo de nuevo.');
    }
  }

  Future<Product?> updateProduct(Product product) async {
    try {
      final response = await http.put(
        Uri.parse('$url/${product.id}'),
        headers: Session.headers(json: true),
        body: jsonEncode(product.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ProductServiceException(
            'No se pudo conectar con el servidor. Verifique su conexión a internet.',
            isConnectionError: true,
          );
        },
      );

      if (response.statusCode == 401) {
        throw ProductServiceException('Su sesión expiró. Inicie sesión nuevamente.');
      }
      if (response.statusCode == 204 || response.statusCode == 200) {
     
        return product.copyWith(version: product.version + 1);
      } else if (response.statusCode == 404) {
        throw ProductServiceException('Producto no encontrado. Es posible que haya sido eliminado.');
      } else if (response.statusCode == 400) {
        throw ProductServiceException('Datos inválidos. Inténtelo de nuevo.');
      } else if (response.statusCode == 409) {
     
        String serverMessage = 'El producto fue actualizado por otro usuario. Actualice e inténtelo de nuevo.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey('message')) {
            serverMessage = body['message'];
          }
        } catch (_) {}
        throw ProductVersionConflictException(serverMessage);
      } else {
        throw ProductServiceException('No se pudo actualizar el producto. Inténtelo de nuevo.');
      }
    } on SocketException {
      throw ProductServiceException(
        'No se pudo conectar con el servidor. Verifique su conexión a internet.',
        isConnectionError: true,
      );
    } on ProductServiceException {
      rethrow;
    } on ProductVersionConflictException {
      rethrow;
    } catch (e) {
      throw ProductServiceException('Ocurrió un error inesperado. Inténtelo de nuevo.');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$url/$id'),
        headers: Session.headers(),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ProductServiceException(
            'No se pudo conectar con el servidor. Verifique su conexión a internet.',
            isConnectionError: true,
          );
        },
      );

      if (response.statusCode == 401) {
        throw ProductServiceException('Su sesión expiró. Inicie sesión nuevamente.');
      }
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw ProductServiceException('Producto no encontrado. Es posible que haya sido eliminado.');
      } else {
        throw ProductServiceException('No se pudo eliminar el producto. Inténtelo de nuevo.');
      }
    } on SocketException {
      throw ProductServiceException(
        'No se pudo conectar con el servidor. Verifique su conexión a internet.',
        isConnectionError: true,
      );
    } on ProductServiceException {
      rethrow;
    } catch (e) {
      throw ProductServiceException('Ocurrió un error inesperado. Inténtelo de nuevo.');
    }
  }
}