import 'dart:convert';
import 'dart:io';

import 'package:app001/models/product.dart';
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
  final String url = "http://localhost:5050/api/Product";

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ProductServiceException(
            'Unable to connect to server. Please check your internet connection.',
            isConnectionError: true,
          );
        },
      );

      if (response.statusCode == 200) {
        List datos = jsonDecode(response.body);
        return datos.map((item) => Product.fromJson(item)).toList();
      } else {
        throw ProductServiceException('Unable to load products. Please try again.');
      }
    } on SocketException {
      throw ProductServiceException(
        'Unable to connect to server. Please check your internet connection.',
        isConnectionError: true,
      );
    } on ProductServiceException {
      rethrow;
    } catch (e) {
      throw ProductServiceException('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> createProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ProductServiceException(
            'Unable to connect to server. Please check your internet connection.',
            isConnectionError: true,
          );
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else {
        throw ProductServiceException('Unable to save product. Please try again.');
      }
    } on SocketException {
      throw ProductServiceException(
        'Unable to connect to server. Please check your internet connection.',
        isConnectionError: true,
      );
    } on ProductServiceException {
      rethrow;
    } catch (e) {
      throw ProductServiceException('An unexpected error occurred. Please try again.');
    }
  }

  Future<Product?> updateProduct(Product product) async {
    try {
      final response = await http.put(
        Uri.parse('$url/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ProductServiceException(
            'Unable to connect to server. Please check your internet connection.',
            isConnectionError: true,
          );
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
     
        return product.copyWith(version: product.version + 1);
      } else if (response.statusCode == 404) {
        throw ProductServiceException('Product not found. It may have been deleted.');
      } else if (response.statusCode == 400) {
        throw ProductServiceException('Invalid data sent. Please try again.');
      } else if (response.statusCode == 409) {
     
        String serverMessage = 'The product was updated by another user. Please refresh and try again.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey('message')) {
            serverMessage = body['message'];
          }
        } catch (_) {}
        throw ProductVersionConflictException(serverMessage);
      } else {
        throw ProductServiceException('Unable to update product. Please try again.');
      }
    } on SocketException {
      throw ProductServiceException(
        'Unable to connect to server. Please check your internet connection.',
        isConnectionError: true,
      );
    } on ProductServiceException {
      rethrow;
    } on ProductVersionConflictException {
      rethrow;
    } catch (e) {
      throw ProductServiceException('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$url/$id'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ProductServiceException(
            'Unable to connect to server. Please check your internet connection.',
            isConnectionError: true,
          );
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw ProductServiceException('Product not found. It may have been deleted.');
      } else {
        throw ProductServiceException('Unable to delete product. Please try again.');
      }
    } on SocketException {
      throw ProductServiceException(
        'Unable to connect to server. Please check your internet connection.',
        isConnectionError: true,
      );
    } on ProductServiceException {
      rethrow;
    } catch (e) {
      throw ProductServiceException('An unexpected error occurred. Please try again.');
    }
  }
}