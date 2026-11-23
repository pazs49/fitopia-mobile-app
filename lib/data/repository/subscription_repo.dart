import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/subscription_model.dart';

class SubscriptionRepo {
  final ApiClient apiClient;

  SubscriptionRepo({required this.apiClient});

  Future<bool> hasActiveSubscription() async {
    final response = await apiClient.getData('api/check-subscription-status');
    final hasActiveSubscription = response['has_active_subscription'];

    if (hasActiveSubscription is bool) {
      return hasActiveSubscription;
    }
    if (hasActiveSubscription is num) {
      return hasActiveSubscription == 1;
    }

    throw ApiException(
      'The subscription status response was invalid.',
    );
  }

  Future<List<SubscriptionModel>> getPackages() async {
    final response = await apiClient.getData('api/package-list');
    final rawPackages = response['data'];

    if (rawPackages is! List) {
      throw ApiException('The package response was invalid.');
    }

    return rawPackages
        .whereType<Map>()
        .map((package) =>
            SubscriptionModel.fromJson(Map<String, dynamic>.from(package)))
        .toList();
  }

  Future<PaymentIntentResult> createPaymentIntent(int packageId) async {
    final response = await apiClient.postAuthenticatedData(
      'api/stripe/create-payment-intent',
      <String, dynamic>{
        'package_id': packageId,
      },
    );

    final clientSecret = response['clientSecret'];
    final paymentIntentId = response['paymentIntentId'];
    if (clientSecret is! String ||
        clientSecret.isEmpty ||
        paymentIntentId is! String ||
        paymentIntentId.isEmpty) {
      throw ApiException('The payment intent response was invalid.');
    }

    return PaymentIntentResult(
      clientSecret: clientSecret,
      paymentIntentId: paymentIntentId,
    );
  }

  Future<void> confirmPayment({
    required int packageId,
    required String paymentIntentId,
  }) async {
    await apiClient.postAuthenticatedData(
      'api/stripe/confirm-payment',
      <String, dynamic>{
        'package_id': packageId,
        'payment_intent_id': paymentIntentId,
      },
    );
  }
}

class PaymentIntentResult {
  final String clientSecret;
  final String paymentIntentId;

  const PaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
  });
}
