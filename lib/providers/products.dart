import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/http_exception.dart';
import 'product.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Red Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://cdn.shopify.com/s/files/1/0011/4651/9637/products/TS2--scarf_1_grande.png?v=1634826211',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];

  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  final bool _showFavoritesOnly = false;

  List<Product> get items {
    if (_showFavoritesOnly) {
      return _items.where((prodItem) => prodItem.isFavorite == true).toList();
    } else {
      return [..._items];
    }

    //prefent adding and editing list from outside the classs
  }

  List<Product> get favoriteItem {
    return _items.where((prodItem) => prodItem.isFavorite == true).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;lib/providers/products.dart
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Future<void> addProduct(Product product) async {
    //_items.add(value);

    try {
      //store in web server
      final response = await http.post(
        Uri.parse(
            'https://sisakala-645ac-default-rtdb.firebaseio.com/products.json?auth=$authToken'),
        body: jsonEncode(
          {
            'title': product.title,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price,
            'isFavorite': product.isFavorite,
            'creatorId': userId,
          },
        ),
      );

      //print(json.decode(response.body));
      //store in device
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
        title: product.title,
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    await http.patch(
      Uri.parse(
          'https://sisakala-645ac-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken'),
      body: json.encode(
        {
          'title': newProduct.title,
          'price': newProduct.price,
          'imageUrl': newProduct.imageUrl,
          'description': newProduct.description,
        },
      ),
    );
    _items[prodIndex] = newProduct;
    notifyListeners();
  }

  Future<void> deleteProducts(String id) async {
    final existingProductIndex = _items.indexWhere(
      (prod) => prod.id == id,
    );
    Product? existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(
      Uri.parse(
          'https://sisakala-645ac-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken'),
    );

    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete the item');
    }
    existingProduct = null;
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    try {
      //print('filterString = $filterString');
      final response = await http.get(
        Uri.parse(
            'https://sisakala-645ac-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString'),
      );
      //print(json.decode(response.body));
      final Map<String, dynamic>? extractedData =
          json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      final favoriteResponse = await http.get(Uri.parse(
          'https://sisakala-645ac-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken'));
      final favoriteData = json.decode(favoriteResponse.body);
      //print(favoriteData);

      final List<Product> loadedProducts = [];
      extractedData.forEach(
        (prodId, prodData) {
          loadedProducts.add(
            Product(
              id: prodId,
              title: prodData['title'],
              description: prodData['description'],
              price: prodData['price'],
              imageUrl: prodData['imageUrl'],
              isFavorite: favoriteData == null
                  ? false
                  : favoriteData['isFavorite'] ?? false,
            ),
          );
        },
      );
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }
}
