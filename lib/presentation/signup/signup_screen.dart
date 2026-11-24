import 'package:easy_localization/easy_localization.dart';
import 'package:fitopia/controller/auth_controller.dart';
import 'package:fitopia/presentation/Mixins/size.dart';
import 'package:fitopia/translations/locale_keys.g.dart';
import 'package:fitopia/widgets/app_logo_widget.dart';
import 'package:fitopia/widgets/background_image_widget.dart';
import 'package:fitopia/widgets/custome_button.dart';
import 'package:fitopia/widgets/text_form_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../resources/index_manager.dart';

class SignUp1 extends StatefulWidget {
  const SignUp1({Key? key}) : super(key: key);

  @override
  State<SignUp1> createState() => _SignUp1State();
}

class _SignUp1State extends State<SignUp1> {
  bool rememberMe = false;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _authController = AuthController();
  int pageno = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: AppSize.s80.vs),
                AppLogoView(),
                SizedBox(height: AppSize.s20.vs),
                Text(
                  LocaleKeys.createAnAccount.tr(),
                  //AppStrings.createAnAccount,
                  style: getboldStyle(
                      color: ColorManager.blackColor, fontSize: AppSize.s20.mv),
                ),
                //loginImage
                SizedBox(height: AppSize.s20.vs),
                SvgPicture.asset(
                  ImageAssets.loginImage,
                ),
                SizedBox(height: AppSize.s28.vs),
                pageno == 0
                    ? SignUp1Container()
                    : pageno == 1
                        ? SignUp2Container()
                        : SignUp3Container(),

                SizedBox(height: 1.vs),
                textspan(
                  text1: LocaleKeys.alreadyHaveanAccount
                      .tr(), //AppStrings.alreadyHaveanAccount,
                  text2: LocaleKeys.signIn.tr(), //AppStrings.signIn,
                  onTap: () => Navigator.pushReplacementNamed(
                      context, Routes.loginRoute),
                ),
                SizedBox(height: 1.vs)
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///Signup1
  Widget SignUp1Container() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30.0, bottom: 0.0, top: 10.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              LocaleKeys.whatsYourEmail.tr(),
              textAlign: TextAlign.left,
              style: getboldStyle(
                  color: ColorManager.blackColor, fontSize: AppSize.s13.mv),
            ),
          ),
        ),
        SizedBox(height: AppSize.s15.vs),
        CustomeTextFormField(
          controller: _emailController,
          hintText: LocaleKeys.enterYourEmail.tr(),
          keyboardType: TextInputType.emailAddress,
          validator: (String? val) {
            if (val == null || val.trim().isEmpty) {
              return LocaleKeys.enterYourEmail.tr();
            }
            if (!val.contains('@')) {
              return 'Enter a valid email address.';
            }
            return null;
          },
        ),
        TermAndCondition(),
        SizedBox(height: 10.vs),
        button(
            text: LocaleKeys.contine.tr(), //AppStrings.contine,
            color: ColorManager.primary,
            onTap: () {
              if (_formKey.currentState!.validate()) {
                setState(() => pageno = 1);
              }
            }),
      ],
    );
  }

  ///Signup2
  Widget SignUp2Container() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30.0, bottom: 0.0, top: 10.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              LocaleKeys.ChoosePassword.tr(), //AppStrings.ChoosePassword,
              textAlign: TextAlign.left,
              style: getboldStyle(
                  color: ColorManager.blackColor, fontSize: AppSize.s13.mv),
            ),
          ),
        ),
        SizedBox(height: AppSize.s15.vs),
        CustomeTextFormField(
          controller: _passwordController,
          hintText: LocaleKeys.enterPassword.tr(), //AppStrings.enterPassword,
          obscureText: true,
          validator: (String? val) {
            if (val == null || val.length < 8) {
              return 'Password must be at least 8 characters.';
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30.0, bottom: 10.0, top: 10.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              LocaleKeys.passwordValidation.tr(),
              textAlign: TextAlign.left,
              style: getRegularStyle(
                  color: ColorManager.greyBorderColor,
                  fontSize: AppSize.s13.mv),
            ),
          ),
        ),
        SizedBox(height: 10.vs),
        button(
            text: LocaleKeys.contine.tr(), // AppStrings.contine,
            color: ColorManager.primary,
            onTap: () {
              if (_formKey.currentState!.validate()) {
                setState(() => pageno = 2);
              }
            }),
        SizedBox(height: 2.vs),
        GestureDetector(
          onTap: (() {
            setState(() {
              pageno = 0;
            });
          }),
          child: Text(
            LocaleKeys.back.tr(), //AppStrings.back,
            textAlign: TextAlign.left,
            style: getboldStyle(
                color: ColorManager.greyBorderColor, fontSize: AppSize.s13.mv),
          ),
        ),
      ],
    );
  }

  ///Signup3
  Widget SignUp3Container() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30.0, bottom: 0.0, top: 10.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              LocaleKeys.WhatsYourName.tr(), //AppStrings.WhatsYourName,
              textAlign: TextAlign.left,
              style: getboldStyle(
                  color: ColorManager.blackColor, fontSize: AppSize.s13.mv),
            ),
          ),
        ),
        SizedBox(height: AppSize.s15.vs),
        CustomeTextFormField(
          controller: _firstNameController,
          hintText: LocaleKeys.FirstName.tr(), //AppStrings.FirstName,
          validator: (String? val) {
            if (val == null || val.trim().isEmpty) {
              return 'Enter your first name.';
            }
            return null;
          },
        ),
        SizedBox(height: AppSize.s15.vs),
        CustomeTextFormField(
          controller: _lastNameController,
          hintText: LocaleKeys.LastName.tr(), //AppStrings.LastName,
          validator: (String? val) {
            if (val == null || val.trim().isEmpty) {
              return 'Enter your last name.';
            }
            return null;
          },
        ),
        TermAndCondition(),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 10.0, right: 10.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: textspan(
              text1: LocaleKeys.privacyPlicy.tr(), //AppStrings.privacyPlicy,
              text2: "Privacy Policy and Terms & Conditions.",
              onTap: () =>
                  Navigator.pushReplacementNamed(context, Routes.loginRoute),
            ),
          ),
        ),
        SizedBox(height: 10.vs),
        button(
            text: LocaleKeys.CREATEACCOUNT.tr(), //AppStrings.CREATEACCOUNT,
            color: ColorManager.primary,
            onTap: _isSubmitting ? null : _handleRegistration),
        SizedBox(height: 2.vs),
        GestureDetector(
          onTap: (() {
            setState(() {
              pageno = 1;
            });
          }),
          child: Text(
            LocaleKeys.back.tr(), //AppStrings.back,
            textAlign: TextAlign.left,
            style: getboldStyle(
                color: ColorManager.greyBorderColor, fontSize: AppSize.s13.mv),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!rememberMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please accept the terms and conditions.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await _authController.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.pushReplacementNamed(
        context,
        Routes.subscriptionViewPageRoute,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _authController.errorMessage ?? 'Unable to create account.',
        ),
      ),
    );
  }

  Widget TermAndCondition() {
    return Padding(
      padding: EdgeInsets.only(left: AppSize.sizeWidth(context) * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: 40.0,
            width: 40.0,
            child: Checkbox(
              side: const BorderSide(color: Color(0xff585858), width: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: rememberMe,
              activeColor: ColorManager.primary,
              checkColor: Colors.white,
              onChanged: (value) => setState(
                () => rememberMe = value ?? false,
              ),
            ),
          ),
          RichText(
            text: TextSpan(
              text: 'I accept Fitopia\'s ',
              style: getRegularStyle(color: ColorManager.blackColor),
              children: <TextSpan>[
                TextSpan(
                  text: 'Privacy Policy and Terms & Conditions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: ColorManager.primary,
                      fontSize: 14.sp),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Navigator.of(context).pushReplacement(
                      //   MaterialPageRoute(
                      //     builder: (BuildContext context) =>
                      //     const LoginScreen(),
                      //   ),
                      // );
                      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      //     content: Text("Please Accept Terms and conditions")));
                    },
                ),
              ],
            ),
          ),
        ],
      ),
    );
    //SizedBox(height: 10.0),
  }

  Widget button({Function()? onTap, String? text, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: AppSize.sizeWidth(context) * 0.06, vertical: 10.0),
      child: CustomeButton(
          color: color!,
          text: text ?? "",
          style: getboldStyle(
            color: ColorManager.whiteColor,
            fontSize: AppSize.s12.mv,
          ),
          isLoading: _isSubmitting && pageno == 2,
          onTap: onTap),
    );
  }

  Widget textspan(
      {String? text1,
      String? text2,
      BuildContext? context,
      Function()? onTap}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppPadding.p14, vertical: AppPadding.p20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: text1,
          style: getRegularStyle(
              color: ColorManager.blackColor, fontSize: AppSize.s12.mv),
          children: <TextSpan>[
            TextSpan(
                text: text2,
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: ColorManager.primary,
                    fontFamily: FontConstants.fontFamily,
                    fontWeight: FontWeightManager.bold,
                    fontSize: AppSize.s12.mv),
                recognizer: TapGestureRecognizer()..onTap = onTap)
          ],
        ),
      ),
    );
  }
}
