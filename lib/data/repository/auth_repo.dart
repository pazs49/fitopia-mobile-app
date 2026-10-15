// import 'dart:async';

// import 'package:fitopia/data/api/api_client.dart';
// import 'package:get/get_connect/http/src/response/response.dart';


// import '../../presentation/resources/index_manager.dart';

// class AuthRepo {
//   final ApiClient apiClient;
//   AuthRepo({ required this.apiClient,});

//   Future<Response> login(String email, String password) async {
//     return await apiClient.postData(AppStrings.LOGIN_URI, {"email": email, "password": password});
//   }
//   // Future<Response> generalApi(String userId) async {
//   //   return await apiClient.postData(AppStrings.GENERAL_URI, {"session_user_id": userId,});
//   // }
//   // Future<Response> checkEmail(String email,) async {
//   //   return await apiClient.postData(AppStrings.CHECK_EMAIL, {"email": email,});
//   // }
//   // Future<Response> sendCodeToEmail(String email,) async {
//   //   return await apiClient.postData(AppStrings.SEND_CODE_TO_EMAIL, {"email": email,});
//   // }
//   // Future<Response> signup(String email, String password,String fName,String lName,String number) async {
//   //   return await apiClient.postData(AppStrings.SIGNUP_URI, {"email": email, "password": password,"first_name":fName,'last_name':lName,"number":number});
//   // }
//   // Future<Response> sendCode(String code,) async {
//   //   return await apiClient.postData(AppStrings.SEND_CODE, {"session_user_id": code,});
//   // }

//   // Future<Response> validateCode(String code,String userId) async {
//   //   return await apiClient.postData(AppStrings.VALIDATE_CODE, {"code": code,"session_user_id":userId});
//   // }

//   // Future<Response> verifyCode(String code,) async {
//   //   return await apiClient.postData(AppStrings.VALIDATE_CODE_TO_EMAIL, {"code": code,});
//   // }

//   // Future<Response> createPassword(String password,String token) async {
//   //   return await apiClient.postData(AppStrings.CREATE_PASSWORD, {"token": token,"password":password});
//   // }

//   // Future<Response> viewProfile(String loginUserID,String userID) async {
//   //   return await apiClient.getData(AppStrings.GET_USER+"?session_user_id=$loginUserID&user_id=$userID",);
//   // }
// }
