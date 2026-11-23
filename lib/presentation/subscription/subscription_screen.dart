import 'package:fitopia/presentation/subscription/selected_package_screen.dart';
import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/subscription_repo.dart';
import 'package:flutter/material.dart';
import 'package:fitopia/widgets/custome_button.dart';
import 'package:fitopia/presentation/Mixins/size.dart';
import 'package:fitopia/model/subscription_model.dart';
import 'package:fitopia/widgets/subscriptionModelList.dart';

import '../resources/index_manager.dart';

class SubscriptionView extends StatefulWidget {
  SubscriptionView({super.key});
  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  int selectedIndex = 0;
  final SubscriptionRepo _subscriptionRepo =
      SubscriptionRepo(apiClient: ApiClient());
  List<SubscriptionModel> _packages = <SubscriptionModel>[];
  bool _isLoading = true;
  bool _isCreatingPaymentIntent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final packages = await _subscriptionRepo.getPackages();
      if (!mounted) {
        return;
      }
      if (packages.isEmpty) {
        setState(() {
          _packages = <SubscriptionModel>[];
          _isLoading = false;
          _errorMessage =
              'No subscription packages are available. Please try again.';
        });
        return;
      }
      setState(() {
        _packages = packages;
        _isLoading = false;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _continueToPayment() async {
    if (_packages.isEmpty || _isCreatingPaymentIntent) {
      return;
    }

    setState(() {
      _isCreatingPaymentIntent = true;
    });

    try {
      final selectedPackage = _packages[selectedIndex];
      final paymentIntent =
          await _subscriptionRepo.createPaymentIntent(selectedPackage.id);

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreaditCardAddView(
            subdata: selectedPackage,
            clientSecret: paymentIntent.clientSecret,
            paymentIntentId: paymentIntent.paymentIntentId,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPaymentIntent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(height: 20.vs),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                height: AppSize.sizeHeight(context) * 0.22,
                // width: 500,
                decoration: BoxDecoration(
                  // color: Colors.green,
                  image: DecorationImage(
                    image: AssetImage(ImageAssets.subscriptionImage),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Text(
              "Your first 7 days are free.",
              style: getboldStyle(
                  color: ColorManager.blackColor, fontSize: AppSize.s16),
            ),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_errorMessage!),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadPackages();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              subWidget(_packages),
            SizedBox(height: 10.vs),
            button(
                text: _isCreatingPaymentIntent ? "Creating payment..." : "Next",
                color: ColorManager.primary,
                onTap: _isLoading ||
                        _errorMessage != null ||
                        _packages.isEmpty ||
                        _isCreatingPaymentIntent
                    ? null
                    : _continueToPayment),
            SizedBox(height: 1.vs),
          ],
        ),
      ),
    );
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
          onTap: onTap),
    );
  }

  Widget subWidget(List<SubscriptionModel> itemList) {
    return FixedTogglesSubscriptionList(
      selected: selectedIndex,
      callback: (int index) {
        setState(() {
          selectedIndex = index;
        });
      },
      sub: itemList,
    );
  }
}
