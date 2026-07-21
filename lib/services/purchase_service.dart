import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles the single "Remove Ads" non-consumable in-app purchase.
///
/// This must have a matching In-App Purchase product created in App Store
/// Connect (Non-Consumable, $1.99) with the exact product ID below before
/// purchases will work — the App Store Connect ID and this constant must
/// match exactly.
class PurchaseService extends ChangeNotifier {
  static const String removeAdsProductId = 'remove_ads';
  static const String _prefsKey = 'ads_removed';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _adsRemoved = false;
  bool get adsRemoved => _adsRemoved;

  ProductDetails? _removeAdsProduct;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _purchasePending = false;
  bool get purchasePending => _purchasePending;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _adsRemoved = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );

    final response = await _iap.queryProductDetails({removeAdsProductId});
    if (response.productDetails.isNotEmpty) {
      _removeAdsProduct = response.productDetails.first;
      notifyListeners();
    }
  }

  Future<void> buyRemoveAds() async {
    if (_removeAdsProduct == null) return;
    final param = PurchaseParam(productDetails: _removeAdsProduct!);
    _purchasePending = true;
    notifyListeners();
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == removeAdsProductId) {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            _purchasePending = true;
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _markAdsRemoved();
            _purchasePending = false;
            break;
          case PurchaseStatus.error:
          case PurchaseStatus.canceled:
            _purchasePending = false;
            break;
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
    notifyListeners();
  }

  Future<void> _markAdsRemoved() async {
    _adsRemoved = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
