import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/wallet.dart';
import '../services/database_service.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  UserProfile _profile = UserProfile();
  bool _loading = true;
  bool _onboardingComplete = false;
  String? _error;

  UserProfile get profile => _profile;
  bool get loading => _loading;
  bool get onboardingComplete => _onboardingComplete;
  String? get error => _error;

  Future<void> init() async {
    _loading = true;
    _error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    try {
      await _db.init();
      final saved = await _db.getUserProfile();
      if (saved != null) {
        _profile = saved;
        _onboardingComplete = true;
      } else {
        _onboardingComplete = false;
      }
    } catch (e) {
      _error = e.toString();
      _onboardingComplete = false;
    } finally {
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    _profile = profile;
    _onboardingComplete = true;
    await _db.saveUserProfile(profile);
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    _profile.name = name;
    await _db.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> updateCurrency(String currency) async {
    _profile.currency = currency;
    await _db.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> updateWallets(List<Wallet> wallets) async {
    _profile.wallets = wallets;
    await _db.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> updateWalletBalance(String walletName, double amount, {bool isIncome = false}) async {
    for (final w in _profile.wallets) {
      if (w.name == walletName) {
        w.balance += isIncome ? amount : -amount;
        break;
      }
    }
    await _db.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> updateStartingBalance(double balance) async {
    _profile.startingBalance = balance;
    await _db.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> updateMonthlyBudget(double budget) async {
    _profile.monthlyBudget = budget;
    await _db.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> updateWarningThreshold(double percent) async {
    _profile.warningThresholdPercent = percent;
    await _db.saveUserProfile(_profile);
    notifyListeners();
  }
}
