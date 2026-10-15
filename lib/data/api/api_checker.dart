import 'package:get/get_connect/http/src/response/response.dart';

class ApiChecker {
  static void checkApi(Response response) {
    if(response.statusCode == 401) {
      // Get.offAllNamed( Routes.loginRoute);
    }else {
      // showCustomSnackBar(response.statusText);
    }
  }
}
