import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ecommerce_app/models/api_response.dart';
import 'package:flutter_ecommerce_app/utility/utility_extention.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../models/coupon.dart';
import '../../../services/http_services.dart';
import '../../../utility/constants.dart';
import '../../../utility/snack_bar_helper.dart';
import '../../auth_screen/provider/user_provider.dart';

class CartProvider extends ChangeNotifier {
  HttpService service = HttpService();
  Razorpay razorpay = Razorpay();
  UserProvider? _userProvider;
  var flutterCart = FlutterCart();
  List<CartModel> myCartItems = [];

  final GlobalKey<FormState> buyNowFormKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();
  TextEditingController streetController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController postalCodeController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController couponController = TextEditingController();
  bool isExpanded = false;

  Coupon? couponApplied;
  double couponCodeDiscount = 0;
  String selectedPaymentOption = PAYMENT_METHOD_COD;

  CartProvider(this._userProvider) {
    retrieveSavedAddress();
  }

  void update(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  void updateCart(CartModel cartItem, int quantity) {
    quantity = cartItem.quantity + quantity;
    flutterCart.updateQuantity(cartItem.productId, cartItem.variants, quantity);
    notifyListeners();
  }

  double getCartSubTotal() {
    return flutterCart.subtotal;
  }

  double getGrandTotal() {
    return getCartSubTotal() - couponCodeDiscount;
  }

  getCartItems() {
    myCartItems = flutterCart.cartItemsList;
    notifyListeners();
  }

  clearCartItems() {
    flutterCart.clearCart();
    notifyListeners();
  }

  checkCoupon() async {
    try {
      if (couponController.text.isEmpty) {
        SnackBarHelper.showErrorSnackBar('Enter a coupon code.');
        return;
      }

      List<String> productIds =
          myCartItems.map((cartItem) => cartItem.productId).toList();

      Map<String, dynamic> couponData = {
        'couponCode': couponController.text,
        'purchaseAmount': getCartSubTotal(),
        'productIds': productIds,
      };

      final response = await service.addItem(
        endpointUrl: 'couponCodes/check-coupon',
        itemData: couponData,
      );

      log('Coupon response: ${response.body}');

      if (response.isOk) {
        final body = response.body;

        if (body is Map<String, dynamic>) {
          bool success = body['success'] == true;
          String message = body['message'] ?? 'No message';

          if (success) {
            final data = body['data'];
            if (data is Map<String, dynamic>) {
              final coupon = Coupon.fromJson(data);
              couponApplied = coupon;
              couponCodeDiscount = getCouponDiscountAmount(coupon);
              SnackBarHelper.showSuccessSnackBar(message);
              log('Coupon is valid');
            } else {
              SnackBarHelper.showErrorSnackBar('Invalid coupon format.');
              log('Coupon data is not a map: $data');
            }
          } else {
            SnackBarHelper.showErrorSnackBar(message);
          }
        } else {
          SnackBarHelper.showErrorSnackBar('Invalid server response format.');
        }
      } else {
        String error =
            response.body?['message'] ?? response.statusText ?? 'Unknown error';
        SnackBarHelper.showErrorSnackBar('Error: $error');
      }

      notifyListeners();
    } catch (e, stack) {
      log('Coupon error: $e\n$stack');
      SnackBarHelper.showErrorSnackBar(
          'An error occurred while checking coupon.');
    }
  }

  double getCouponDiscountAmount(Coupon coupon) {
    String discountType = coupon.discountType ?? 'fixed';

    if (discountType == 'fixed') {
      return coupon.discountAmount ?? 0;
    } else {
      double discountPercentage = coupon.discountAmount ?? 0;
      double amountAfterDiscountPercentage =
          getCartSubTotal() * (discountPercentage / 100);
      return amountAfterDiscountPercentage;
    }
  }

  Future<String?> submitOrder() async {
    if (selectedPaymentOption == PAYMENT_METHOD_COD) {
      return await addOrder();
    } else {
      return await stripePayment(operation: () async {
        return await addOrder();
      });
    }
  }

  Future<String?> addOrder() async {
    try {
      final loggedInUser = await _userProvider!.getLoginUsr();

      if (loggedInUser == null) {
        return 'User not logged in';
      }

      Map<String, dynamic> order = {
        'userID': loggedInUser.sId ?? '',
        'orderStatus': ORDER_STATUS_PENDING,
        'items': cartItemToOrderItem(myCartItems),
        'totalPrice': getCartSubTotal(),
        'shippingAddress': {
          'phone': phoneController.text,
          'street': streetController.text,
          'city': cityController.text,
          'state': stateController.text,
          'postalCode': postalCodeController.text,
          'country': countryController.text,
        },
        'paymentMethod': selectedPaymentOption,
        'couponCode': couponApplied?.sId,
        'orderTotal': {
          'subTotal': getCartSubTotal(),
          'discount': couponCodeDiscount,
          'total': getGrandTotal(),
        },
      };

      final response =
          await service.addItem(endpointUrl: 'orders', itemData: order);

      if (response.isOk) {
        ApiResponse apiResponse = ApiResponse.fromJson(response.body, null);

        if (apiResponse.success == true) {
          log('order added');
          await saveAddress(); // Save address after successful order
          return null;
        } else {
          return 'Failed to order: ${apiResponse.message}';
        }
      } else {
        return 'Error: ${response.body?['message'] ?? response.statusText}';
      }
    } catch (e) {
      log(e.toString());
      return 'An error occurred: $e';
    }
  }

  List<Map<String, dynamic>> cartItemToOrderItem(List<CartModel> cartItems) {
    return cartItems
        .map((cartItem) => {
              'productID': cartItem.productId,
              'productName': cartItem.productName,
              'quantity': cartItem.quantity,
              'price': cartItem.variants.safeElementAt(0)?.price ?? 0,
              'variant': cartItem.variants.safeElementAt(0)?.color ?? ''
            })
        .toList();
  }

  clearCouponDiscount() {
    couponApplied = null;
    couponCodeDiscount = 0;
    couponController.text = '';
    notifyListeners();
  }

  Future<void> retrieveSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    phoneController.text = prefs.getString(PHONE_KEY) ?? '';
    streetController.text = prefs.getString(STREET_KEY) ?? '';
    cityController.text = prefs.getString(CITY_KEY) ?? '';
    stateController.text = prefs.getString(STATE_KEY) ?? '';
    postalCodeController.text = prefs.getString(POSTAL_CODE_KEY) ?? '';
    countryController.text = prefs.getString(COUNTRY_KEY) ?? '';
  }

  Future<void> saveAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PHONE_KEY, phoneController.text);
    await prefs.setString(STREET_KEY, streetController.text);
    await prefs.setString(CITY_KEY, cityController.text);
    await prefs.setString(STATE_KEY, stateController.text);
    await prefs.setString(POSTAL_CODE_KEY, postalCodeController.text);
    await prefs.setString(COUNTRY_KEY, countryController.text);
  }

  Future<String?> stripePayment({
    required Future<String?> Function() operation,
  }) async {
    try {
      final user = await _userProvider!.getLoginUsr();
      if (user == null) return 'User not logged in';

      Map<String, dynamic> paymentData = {
        "email": user.name,
        "name": user.name,
        "address": {
          "line1": streetController.text,
          "city": cityController.text,
          "state": stateController.text,
          "postal_code": postalCodeController.text,
          "country": "US"
        },
        "amount": (getGrandTotal() * 100).toInt(),
        "currency": "usd",
        "description": "Your transaction description here"
      };

      Response response = await service.addItem(
        endpointUrl: 'payment/stripe',
        itemData: paymentData,
      );

      final data = response.body;
      final paymentIntent = data['paymentIntent'];
      final ephemeralKey = data['ephemeralKey'];
      final customer = data['customer'];
      final publishableKey = data['publishableKey'];

      Stripe.publishableKey = publishableKey;

      BillingDetails billingDetails = BillingDetails(
        email: user.name,
        phone: '91234123908',
        name: user.name,
        address: Address(
          country: 'US',
          city: cityController.text,
          line1: streetController.text,
          line2: stateController.text,
          postalCode: postalCodeController.text,
          state: stateController.text,
        ),
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customFlow: false,
          merchantDisplayName: 'MOBIZATE',
          paymentIntentClientSecret: paymentIntent,
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customer,
          style: ThemeMode.light,
          billingDetails: billingDetails,
        ),
      );

      await Stripe.instance.presentPaymentSheet().then((_) async {
        log('payment success');
        return await operation();
      }).onError((error, stackTrace) {
        if (error is StripeException) {
          return 'Error: ${error.error.localizedMessage}';
        } else {
          return 'Stripe Error: $error';
        }
      });
    } catch (e) {
      log(e.toString());
      return 'An error occurred: $e';
    }

    return null;
  }

  Future<String?> razorpayPayment({
    required Future<String?> Function() operation,
  }) async {
    try {
      final user = await _userProvider!.getLoginUsr();
      if (user == null) return 'User not logged in';

      final response = await service.addItem(
        endpointUrl: 'payment/razorpay',
        itemData: {},
      );

      final data = response.body;
      final razorpayKey = data['key'];

      if (razorpayKey != null && razorpayKey != '') {
        final options = {
          'key': razorpayKey,
          'amount': (getGrandTotal() * 100).toInt(),
          'name': user.name ?? 'User',
          'currency': 'INR',
          'description': 'Your transaction description',
          'send_sms_hash': true,
          'prefill': {
            'email': user.name,
            'contact': '', // Update if phone available
          },
          'theme': {'color': '#4A77FF'},
          'image':
              'https://store.rapidflutter.com/digitalAssetUpload/rapidlogo.png',
        };

        razorpay.open(options);

        razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
            (PaymentSuccessResponse response) async {
          log('Payment successful: ${response.paymentId}');
          await operation();
          razorpay.clear();
        });

        razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
            (PaymentFailureResponse response) {
          log('Payment failed: ${response.message}');
          razorpay.clear();
          Get.snackbar('Payment Failed', response.message ?? 'Unknown error',
              backgroundColor: Colors.red, colorText: Colors.white);
        });
      } else {
        return 'Razorpay key not found';
      }
    } catch (e) {
      log('Razorpay error: $e');
      return 'An error occurred: $e';
    }

    return null;
  }

  void updateUI() {
    notifyListeners();
  }
}
