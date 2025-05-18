import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../models/category.dart';
import '../../../utility/constants.dart';
import '../../../utility/extensions.dart';
import '../../../widgets/category_image_card.dart';
import '../../../widgets/custom_text_field.dart';
import '../provider/category_provider.dart';

class CategorySubmitForm extends StatelessWidget {
  final Category? category;

  const CategorySubmitForm({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    context.categoryProvider.setDataForUpdateCategory(category);

    return SingleChildScrollView(
      child: Form(
        key: context.categoryProvider.addCategoryFormKey,
        child: Container(
          padding: const EdgeInsets.all(defaultPadding),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Category Image",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Gap(defaultPadding / 2),
              Consumer<CategoryProvider>(
                builder: (context, catProvider, child) {
                  return CategoryImageCard(
                    labelText: "Image",
                    imageFile: catProvider.selectedImage,
                    imageUrlForUpdateImage:
                        (catProvider.selectedImage == null &&
                                category?.image != null &&
                                category!.image!.isNotEmpty)
                            ? category!.image
                            : null,
                    onTap: () {
                      catProvider.pickImage();
                    },
                  );
                },
              ),
              const Gap(defaultPadding),
              CustomTextField(
                controller: context.categoryProvider.categoryNameCtrl,
                labelText: 'Category Name',
                onSave: (val) {},
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const Gap(defaultPadding * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryColor,
                      side: const BorderSide(color: secondaryColor),
                    ),
                    onPressed: () {
                      context.categoryProvider.clearFields();
                      Navigator.of(context).pop(); // Close the popup
                    },
                    child: const Text('Cancel'),
                  ),
                  const Gap(defaultPadding),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: primaryColor,
                    ),
                    onPressed: () {
                      if (context
                          .categoryProvider.addCategoryFormKey.currentState!
                          .validate()) {
                        context
                            .categoryProvider.addCategoryFormKey.currentState!
                            .save();
                        context.categoryProvider.submitCategory();

                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showAddCategoryForm(
    BuildContext context, Category? category, String buttonText) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Center(
          child: Text(
            buttonText.toUpperCase(),
            style: const TextStyle(
                color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        content: CategorySubmitForm(category: category),
      );
    },
  ).then((val) {
    context.categoryProvider.clearFields();
  });
}
