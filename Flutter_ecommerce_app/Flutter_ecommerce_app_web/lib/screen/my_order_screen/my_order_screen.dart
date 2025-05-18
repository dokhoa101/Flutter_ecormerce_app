import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../core/data/data_provider.dart';
import '../auth_screen/provider/user_provider.dart';
import '../../utility/app_color.dart';
import '../../utility/constants.dart';
import '../../utility/extensions.dart';
import '../../utility/utility_extention.dart';
import '../../widget/order_tile.dart';
import '../tracking_screen/tracking_screen.dart';

class MyOrderScreen extends StatelessWidget {
  const MyOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    return FutureBuilder(
      future: userProvider.getLoginUsr(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          dataProvider.getAllOrderByUser(user.sId);
        }

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size(
              double.infinity,
              56.0,
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: AppBar(
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                  elevation: 0.0,
                  title: const Text(
                    "Order History",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColor.darkAccent),
                  ),
                  backgroundColor: Colors.black.withOpacity(0),
                ),
              ),
            ),
          ),
          body: Consumer<DataProvider>(
            builder: (context, provider, child) {
              return ListView.builder(
                itemCount: provider.orders.length,
                itemBuilder: (context, index) {
                  final order = provider.orders[index];
                  String title =
                      (order.items.safeElementAt(0)?.productName ?? '');
                  if (order.items!.length - 1 > 1) {
                    title += ' and ${order.items!.length - 1} other items';
                  } else if (order.items!.length - 1 == 1) {
                    title += ' and ${order.items!.length - 1} other item';
                  }

                  return OrderTile(
                    paymentMethod: order.paymentMethod ?? '',
                    items: title,
                    price: order.totalPrice,
                    date: order.orderDate ?? '',
                    status: order.orderStatus ?? ORDER_STATUS_PENDING,
                    onTap: () {
                      if (order.orderStatus == ORDER_STATUS_SHIPPED) {
                        Get.to(TrackingScreen(url: order.trackingUrl ?? ''));
                      }
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
