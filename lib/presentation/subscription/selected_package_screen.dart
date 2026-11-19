import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/subscription_repo.dart';
import 'package:fitopia/model/subscription_model.dart';
import 'package:fitopia/presentation/resources/index_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';

class CreaditCardAddView extends StatefulWidget {
  final SubscriptionModel subdata;
  final String clientSecret;
  final String paymentIntentId;

  const CreaditCardAddView({
    super.key,
    required this.subdata,
    required this.clientSecret,
    required this.paymentIntentId,
  });

  @override
  State<CreaditCardAddView> createState() => _CreaditCardAddViewState();
}

class _CreaditCardAddViewState extends State<CreaditCardAddView> {
  final SubscriptionRepo _subscriptionRepo =
      SubscriptionRepo(apiClient: ApiClient());
  bool _isPaying = false;

  Future<void> _pay() async {
    if (_isPaying) {
      return;
    }

    setState(() {
      _isPaying = true;
    });

    try {
      const publishableKey = AppStrings.stripePublishableKey;
      if (publishableKey.isEmpty) {
        throw ApiException(
          'Stripe is not configured. Provide STRIPE_PUBLISHABLE_KEY when launching the app.',
        );
      }

      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: widget.clientSecret,
          merchantDisplayName: 'Fitopia',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      await _subscriptionRepo.confirmPayment(
        packageId: widget.subdata.id,
        paymentIntentId: widget.paymentIntentId,
      );
      final storage = GetStorage();
      final userData = storage.read('user_data');
      if (userData is Map) {
        final updatedUserData = Map<String, dynamic>.from(userData);
        updatedUserData['is_subscribe'] = 1;
        await storage.write('user_data', updatedUserData);
      }

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, Routes.Onboarding1Route);
    } on StripeException catch (error) {
      if (!mounted || error.error.code == FailureCode.Canceled) {
        return;
      }
      _showError(error.error.localizedMessage ?? 'Payment failed.');
    } on ApiException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SvgPicture.asset(ImageAssets.arrowBack),
          ),
        ),
        title: Text(
          'Secure Checkout',
          style: getboldStyle(
            color: ColorManager.blackColor,
            fontSize: FontSize.s14,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.subdata.title1,
                style: getboldStyle(
                  color: ColorManager.blackColor,
                  fontSize: FontSize.s16,
                ),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Your card details are entered securely in Stripe. '
                'Fitopia never receives your card number or security code.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPaying ? null : _pay,
                  child: Text(_isPaying ? 'Processing...' : 'Pay Now'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
