import 'dart:developer';
import 'package:chys/app/services/http_service.dart';
import 'package:get/get.dart';

import '../../../services/short_message_utils.dart';
import '../model/transaction_model.dart';

class TransactionHistoryController extends GetxController {
  final transactions = <TransactionModel>[].obs;
  final withDraws = <TransactionModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final lastFetchTime = Rxn<DateTime>();

  // Cache duration (5 minutes)
  static const Duration cacheDuration = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    // Check if we should use cached data
    if (!forceRefresh && _shouldUseCachedData()) {
      return;
    }

    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await ApiClient().get(ApiEndPoints.transactions);

      if (response['success'] == true) {
        final List<dynamic> sent = response['sentTransactions'] ?? [];
        final List<dynamic> withdraw = response['withdrawals'] ?? [];

        transactions.value = sent.map((e) => TransactionModel.fromJson(e)).toList();
        withDraws.value = withdraw.map((e) => TransactionModel.fromJson(e)).toList();
        
        // Update last fetch time
        lastFetchTime.value = DateTime.now();
        
        log("✅ Transactions loaded successfully: ${transactions.length} sent, ${withDraws.length} withdrawals");
      } else {
        hasError.value = true;
        errorMessage.value = response['message'] ?? 'Failed to fetch transactions';
        ShortMessageUtils.showError(errorMessage.value);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Network error: Please check your connection';
      log("❌ Error fetching transactions: $e");
      ShortMessageUtils.showError('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTransactions() async {
    isRefreshing.value = true;
    await fetchTransactions(forceRefresh: true);
    isRefreshing.value = false;
  }

  bool _shouldUseCachedData() {
    if (lastFetchTime.value == null) return false;
    if (transactions.isEmpty && withDraws.isEmpty) return false;
    
    final timeSinceLastFetch = DateTime.now().difference(lastFetchTime.value!);
    return timeSinceLastFetch < cacheDuration;
  }

  // Get all transactions sorted by date (newest first)
  List<TransactionModel> get allTransactions {
    final all = [...transactions, ...withDraws];
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  // Get transactions for a specific date range
  List<TransactionModel> getTransactionsForDateRange(DateTime start, DateTime end) {
    return allTransactions.where((tx) {
      return tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
             tx.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get recent transactions (last 7 days)
  List<TransactionModel> get recentTransactions {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return allTransactions.where((tx) => tx.date.isAfter(sevenDaysAgo)).toList();
  }

  // Get total amount for a specific period
  double getTotalAmountForPeriod(DateTime start, DateTime end) {
    final periodTransactions = getTransactionsForDateRange(start, end);
    return periodTransactions.fold(0.0, (sum, tx) {
      if (tx.type == 'withdrawal') {
        return sum - tx.amount.toDouble();
      } else {
        return sum + tx.amount.toDouble();
      }
    });
  }

  // Clear cache and reload
  void clearCache() {
    lastFetchTime.value = null;
    fetchTransactions(forceRefresh: true);
  }

  @override
  void onClose() {
    // Clean up any resources if needed
    super.onClose();
  }
}
