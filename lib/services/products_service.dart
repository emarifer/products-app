import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../services/services.dart';

class ProductsService extends ChangeNotifier {
  final String _baseURL = '${dotenv.env['FIREBASE_BASE_URL']}';

  final List<Product> products = [];

  late Product selectedProduct;

  final storage = const FlutterSecureStorage();

  File? newPictureFile;

  bool isLoading = true;
  bool isSaving = false;

  ProductsService() {
    loadProducts();
  }

  Future<List<Product>> loadProducts() async {
    isLoading = true;
    notifyListeners();

    final Uri url = Uri.https(_baseURL, 'products.json', {
      'auth': await storage.read(key: 'idToken') ?? '',
    });

    final http.Response resp = await http.get(url);

    final Map<String, dynamic> productsMap = json.decode(resp.body);

    productsMap.forEach((key, value) {
      final Product tempProduct = Product.fromMap(value);

      tempProduct.iD = key;

      products.add(tempProduct);
    });

    isLoading = false;
    notifyListeners();

    return products;
  }

  Future saveOrCreateProduct(Product product) async {
    isSaving = true;
    notifyListeners();

    if (product.iD == null) {
      // Es necesario crear un product
      await createProduct(product);
    } else {
      // Es necesario actualizar el product
      await updateProduct(product);
    }

    isSaving = false;
    notifyListeners();
  }

  Future<String> updateProduct(Product product) async {
    final Uri uri = Uri.https(_baseURL, 'products/${product.iD}.json', {
      'auth': await storage.read(key: 'idToken') ?? '',
    });

    /* final http.Response resp = */
    await http.put(uri, body: product.toJson());

    // final decodeData = resp.body;

    // print(decodeData);

    int index = products.indexWhere((element) => element.iD == product.iD);

    products[index] = product;

    NotificationsService.showSnackbar('Actualizado satisfactoriamente 😀');

    return product.iD!;
  }

  Future<String> createProduct(Product product) async {
    final Uri uri = Uri.https(_baseURL, 'products.json', {
      'auth': await storage.read(key: 'idToken') ?? '',
    });

    final http.Response resp = await http.post(uri, body: product.toJson());

    final decodeData = json.decode(resp.body);

    // print(decodeData);
    product.iD = decodeData['name'];

    products.add(product);

    NotificationsService.showSnackbar('Creado satisfactoriamente 😀');

    return product.iD!;
  }

  void updateSelectedProductImage(String path) {
    selectedProduct.picture = path;
    newPictureFile = File.fromUri(Uri(path: path));

    notifyListeners();
  }

  Future<String?> uploadImage() async {
    if (newPictureFile == null) return null;

    isSaving = true;
    notifyListeners();

    final String cloudinaryCloudName = '${dotenv.env['CLOUDINARY_CLOUD_NAME']}';
    final String uploadPreset = '${dotenv.env['UPLOAD_PRESET']}';

    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload?upload_preset=$uploadPreset');

    final http.MultipartRequest imageUploadRequest =
        http.MultipartRequest('POST', url);

    final http.MultipartFile file =
        await http.MultipartFile.fromPath('file', newPictureFile!.path);

    imageUploadRequest.files.add(file);

    final http.StreamedResponse streamResponse =
        await imageUploadRequest.send();

    final http.Response resp = await http.Response.fromStream(streamResponse);

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      // print('Algo salió mal');
      // print(resp.body);
      NotificationsService.showSnackbar('Algo salió mal 😲');
      return null;
    }

    newPictureFile = null;

    final decodeData = json.decode(resp.body);

    return decodeData['secure_url'];
  }
}
