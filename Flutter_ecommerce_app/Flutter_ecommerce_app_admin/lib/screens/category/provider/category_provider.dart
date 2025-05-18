import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:admin/models/api_response.dart';
import 'package:admin/utility/snack_bar_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/data_provider.dart';
import '../../../models/category.dart';
import '../../../services/http_services.dart';

class CategoryProvider extends ChangeNotifier {
  final HttpService service = HttpService();
  final DataProvider _dataProvider;
  final addCategoryFormKey = GlobalKey<FormState>();
  final TextEditingController categoryNameCtrl = TextEditingController();

  Category? categoryForUpdate;
  File? selectedImage;
  XFile? imgXFile;
  String? imageUrl;

  CategoryProvider(this._dataProvider);

  Future<void> addCategory() async {
    try {
      if (imgXFile == null) {
        SnackBarHelper.showErrorSnackBar('Please choose an image!');
        return;
      }

      final Map<String, dynamic> formDataMap = {
        'name': categoryNameCtrl.text,
        'image': 'no_data',
      };

      final FormData form =
          await createFormData(imgXFile: imgXFile, formData: formDataMap);
      final response =
          await service.addItem(endpointUrl: 'categories', itemData: form);

      if (response.isOk) {
        final ApiResponse apiResponse =
            ApiResponse.fromJson(response.body, null);

        if (apiResponse.success == true) {
          clearFields();
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          log('Category added');
          _dataProvider.getAllCategories();
        } else {
          SnackBarHelper.showErrorSnackBar(
              'Failed to add category: ${apiResponse.message}');
        }
      } else {
        SnackBarHelper.showErrorSnackBar(
            'Error: ${response.body?['message'] ?? response.statusText}');
      }
    } catch (e) {
      print(e);
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      rethrow;
    }
  }

  Future<void> updateCategory() async {
    try {
      final Map<String, dynamic> formDataMap = {
        'name': categoryNameCtrl.text,
        'image': categoryForUpdate?.image ?? '',
      };

      final FormData form =
          await createFormData(imgXFile: imgXFile, formData: formDataMap);
      final response = await service.updateItem(
        endpointUrl: 'categories',
        itemId: categoryForUpdate?.sId ?? '',
        itemData: form,
      );

      if (response.isOk) {
        final ApiResponse apiResponse =
            ApiResponse.fromJson(response.body, null);

        if (apiResponse.success == true) {
          clearFields();
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          log('Category updated');
          _dataProvider.getAllCategories();
        } else {
          SnackBarHelper.showErrorSnackBar(
              'Failed to update category: ${apiResponse.message}');
        }
      } else {
        SnackBarHelper.showErrorSnackBar(
            'Error: ${response.body?['message'] ?? response.statusText}');
      }
    } catch (e) {
      print(e);
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      rethrow;
    }
  }

  Future<void> submitCategory() async {
    if (categoryForUpdate != null) {
      await updateCategory();
    } else {
      await addCategory();
    }
  }

  Future<void> deleteCategory(Category category) async {
    try {
      final response = await service.deleteItem(
        endpointUrl: 'categories',
        itemId: category.sId ?? '',
      );

      if (response.isOk) {
        final ApiResponse apiResponse =
            ApiResponse.fromJson(response.body, null);
        if (apiResponse.success == true) {
          SnackBarHelper.showSuccessSnackBar('Category deleted successfully!');
          _dataProvider.getAllCategories();
        }
      } else {
        SnackBarHelper.showErrorSnackBar(
            'Error: ${response.body?['message'] ?? response.statusText}');
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      imgXFile = image;
      if (!kIsWeb) {
        selectedImage = File(image.path);
      }
      notifyListeners();
    }
  }

  Future<FormData> createFormData(
      {required XFile? imgXFile,
      required Map<String, dynamic> formData}) async {
    if (imgXFile != null) {
      MultipartFile multipartFile;
      if (kIsWeb) {
        final String fileName = imgXFile.name;
        final Uint8List byteImg = await imgXFile.readAsBytes();
        multipartFile = MultipartFile(byteImg, filename: fileName);
      } else {
        final String fileName = imgXFile.path.split('/').last;
        multipartFile = MultipartFile(imgXFile.path, filename: fileName);
      }
      formData['img'] = multipartFile;
    } else if (imageUrl != null && categoryForUpdate != null) {
      formData['img'] = categoryForUpdate!.image;
    }
    return FormData(formData);
  }

  void setDataForUpdateCategory(Category? category) {
    clearFields();
    if (category != null) {
      categoryForUpdate = category;
      categoryNameCtrl.text = category.name ?? '';
      imageUrl = category.image;
    }
  }

  void clearFields() {
    categoryNameCtrl.clear();
    selectedImage = null;
    imgXFile = null;
    categoryForUpdate = null;
    imageUrl = null;
  }
}
