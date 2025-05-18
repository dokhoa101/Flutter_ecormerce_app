import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ecommerce_app/utility/extensions.dart';

import '../../../models/user.dart';
import '../../../utility/constants.dart';
import '../../../widget/app_bar_action_button.dart';
import '../../../widget/custom_search_bar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBarActionButton(
                icon: Icons.menu,
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final userJsonString = prefs.getString(USER_INFO_BOX);

                  User? userLogged;
                  if (userJsonString != null) {
                    final Map<String, dynamic> userMap =
                        json.decode(userJsonString);
                    userLogged = User.fromJson(userMap);
                  }

                  // Optional: You can do something with userLogged if needed.
                  Scaffold.of(context).openDrawer();
                },
              ),
              Expanded(
                child: CustomSearchBar(
                  controller: TextEditingController(),
                  onChanged: (val) {
                    context.dataProvider.filterProducts(val);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
