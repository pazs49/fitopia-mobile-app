// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:fitopia/data/api/api_client.dart';
// import 'package:fitopia/data/repository/auth_repo.dart';

// class AuthController extends GetxController implements GetxService {


//   final AuthRepo authRepo = AuthRepo(apiClient: ApiClient());

//   String? fistName;
//   String? lastName;
//   String? phone;
//   String? emailAddress;
//   String? password;


//   var box = GetStorage();
//   bool isLoading = false;

//   @override
//   void onInit() {

//   super.onInit();
//   }

//   Future<ResponseModel> login(String email, String password) async {
//     isLoading = true;
//     update();
//     Response response = await authRepo.login(email, password);

//     ResponseModel responseModel;

//     if (response.statusCode == 200) {
//       if (!response.body["error"]) {
//         await DBManager().saveUserData(response);
//         responseModel = ResponseModel(true, response.body['message']);
//       } else {
//         responseModel = ResponseModel(false, response.body['message']);
//       }
//     } else {
//       responseModel = ResponseModel(false, response.statusText.toString());
//     }
//     isLoading = false;
//     update();
//     return responseModel;
//   }

//   Future<ResponseModel> signup(

//     String email,
//     String password,

//   ) async {
//     isLoading = true;
//     update();
//     Response response =
//         await authRepo.signup(email, password, fistName!, lastName!, phone!);
//     ResponseModel responseModel;
//     if (response.statusCode == 200) {
//       if (!response.body["error"]) {
//         responseModel = ResponseModel(true, response.body['message']);
//       } else {
//         responseModel = ResponseModel(false, response.body['message']);
//       }
//     } else {
//       responseModel = ResponseModel(false, response.statusText.toString());
//     }
//     isLoading = false;
//     update();
//     return responseModel;
//   }

//   Future<ResponseModel> verification(
//     String code,
//     String userId,
//   ) async {
//     isLoading = true;
//     update();
//     Response response = await authRepo.validateCode(
//       code,
//       userId,
//     );
//     ResponseModel responseModel;
//     if (response.statusCode == 200) {
//       if (!response.body["error"]) {
//         await DBManager().saveUserData(response);
//         responseModel = ResponseModel(true, response.body['message']);
//       } else {
//         responseModel = ResponseModel(false, response.body['message']);
//       }
//     } else {
//       responseModel = ResponseModel(false, response.statusText.toString());
//     }
//     isLoading = false;
//     update();
//     return responseModel;
//   }

//   Future<ResponseModel> checkEmail(
//     String email,
//   ) async {
//     isLoading = true;
//     update();
//     Response response = await authRepo.checkEmail(
//       email,
//     );
//     ResponseModel responseModel;
//     if (response.statusCode == 200) {
//       if (!response.body["error"]) {
//         responseModel = ResponseModel(true, response.body['message']);
//       } else {
//         responseModel = ResponseModel(false, response.body['message']);
//       }
//     } else {
//       responseModel = ResponseModel(false, response.statusText.toString());
//     }
//     isLoading = false;
//     update();
//     return responseModel;
//   }

//   Future<ResponseModel> customApi(
//     String userId,
//   ) async {
//     Response response = await authRepo.generalApi(
//       userId,
//     );
//     ResponseModel responseModel;
//     if (response.statusCode == 200) {
//       if (!response.body["error"]) {
//         await DBManager().saveCustomApi(response);
//         responseModel = ResponseModel(true, response.body['message']);
//       } else {
//         responseModel = ResponseModel(false, response.body['message']);
//       }
//     } else {
//       responseModel = ResponseModel(false, response.statusText.toString());
//     }
//     return responseModel;
//   }

//   Future<ResponseModel> sendCode(
//     String code,
//   ) async {
//     Response response = await authRepo.sendCode(code);
//     ResponseModel responseModel;
//     if (response.statusCode == 200) {
//       if (!response.body["error"]) {
//         responseModel = ResponseModel(true, response.body['message']);
//       } else {
//         responseModel = ResponseModel(false, response.body['message']);
//       }
//     } else {
//       responseModel = ResponseModel(false, response.statusText.toString());
//     }
//     return responseModel;
//   }

//   Future<ResponseModel> validateCode(
//     String code,
//   ) async {
//     isLoading = true;
//     update();
//     Response response = await authRepo.verifyCode(code);
//     ResponseModel responseModel;
//     if (response.statusCode == 200) {
//       if (!response.body["error"]) {
//         // verifyCodeID=response.body['data'].toString();
//         // print("=====response.body:$verifyCodeID==========");
//         responseModel = ResponseModel(true, response.body['data'].toString());
//       } else {
//         responseModel = ResponseModel(false, response.body['message']);
//       }
//     } else {
//       responseModel = ResponseModel(false, response.statusText.toString());
//     }
//     isLoading = false;
//     update();
//     return responseModel;
//   }

//   Future<ResponseModel> createPassword(String password, String toke) async {
//     isLoading = true;
//     update();
//     Response response = await authRepo.createPassword(password, toke);
//     ResponseModel responseModel;
//     if (response.statusCode == 200) {
//       if (!response.body["error"]) {
//         responseModel = ResponseModel(true, response.body['message']);
//       } else {
//         responseModel = ResponseModel(false, response.body['message']);
//       }
//     } else {
//       responseModel = ResponseModel(false, response.statusText.toString());
//     }
//     isLoading = false;
//     update();
//     return responseModel;
//   }

//   Future<ResponseModel> sendCodeForgotPassword(String email) async {
//     isLoading = true;
//     update();
//     Response response = await authRepo.sendCodeToEmail(
//       email,
//     );
//     ResponseModel responseModel;
//     if (response.statusCode == 200) {
//       if (!response.body["error"]) {
//         responseModel = ResponseModel(true, response.body['message']);
//       } else {
//         responseModel = ResponseModel(false, response.body['message']);
//       }
//     } else {
//       responseModel = ResponseModel(false, response.statusText.toString());
//     }
//     isLoading = false;
//     update();
//     return responseModel;
//   }

// }
