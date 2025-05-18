import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/data_provider.dart';
import '../../../utility/constants.dart';
import '../../../utility/snack_bar_helper.dart';

class ProfileProvider extends ChangeNotifier {
  DataProvider? _dataProvider;

  final GlobalKey<FormState> addressFormKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();
  TextEditingController streetController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController postalCodeController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController couponController = TextEditingController();

  ProfileProvider(this._dataProvider) {
    retrieveSavedAddress();
  }

  void update(DataProvider dataProvider) {
    _dataProvider = dataProvider;
  }

  Future<void> storeAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PHONE_KEY, phoneController.text);
    await prefs.setString(STREET_KEY, streetController.text);
    await prefs.setString(CITY_KEY, cityController.text);
    await prefs.setString(STATE_KEY, stateController.text);
    await prefs.setString(POSTAL_CODE_KEY, postalCodeController.text);
    await prefs.setString(COUNTRY_KEY, countryController.text);

    SnackBarHelper.showSuccessSnackBar('Address Stored Successfully');
  }

  Future<void> retrieveSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();

    phoneController.text = prefs.getString(PHONE_KEY) ?? '';
    streetController.text = prefs.getString(STREET_KEY) ?? '';
    cityController.text = prefs.getString(CITY_KEY) ?? '';
    stateController.text = prefs.getString(STATE_KEY) ?? '';
    postalCodeController.text = prefs.getString(POSTAL_CODE_KEY) ?? '';
    countryController.text = prefs.getString(COUNTRY_KEY) ?? '';

    notifyListeners();
  }
}
