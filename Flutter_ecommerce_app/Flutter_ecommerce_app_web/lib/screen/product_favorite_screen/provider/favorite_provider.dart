import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/data_provider.dart';
import '../../../models/product.dart';
import '../../../utility/constants.dart';

class FavoriteProvider extends ChangeNotifier {
  DataProvider? _dataProvider;
  List<Product> favoriteProduct = [];

  FavoriteProvider(this._dataProvider);

  void update(DataProvider dataProvider) {
    _dataProvider = dataProvider;
  }

  Future<void> updateToFavoriteList(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favoriteList =
        prefs.getStringList(FAVORITE_PRODUCT_BOX) ?? [];

    if (favoriteList.contains(productId)) {
      favoriteList.remove(productId);
    } else {
      favoriteList.add(productId);
    }

    await prefs.setStringList(FAVORITE_PRODUCT_BOX, favoriteList);
    await loadFavoriteItems(); // refresh product list

    notifyListeners();
  }

  Future<bool> checkIsItemFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favoriteList =
        prefs.getStringList(FAVORITE_PRODUCT_BOX) ?? [];
    return favoriteList.contains(productId);
  }

  Future<void> loadFavoriteItems() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favoriteList =
        prefs.getStringList(FAVORITE_PRODUCT_BOX) ?? [];

    // Check if _dataProvider is ready
    if (_dataProvider == null || _dataProvider!.products.isEmpty) {
      favoriteProduct = [];
    } else {
      favoriteProduct = _dataProvider!.products
          .where((product) => favoriteList.contains(product.sId))
          .toList();
    }

    notifyListeners();
  }

  Future<void> clearFavoriteList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(FAVORITE_PRODUCT_BOX);
    favoriteProduct.clear();
    notifyListeners();
  }
}
