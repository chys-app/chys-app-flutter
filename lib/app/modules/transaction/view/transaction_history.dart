import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/widget/shimmer/lottie_animation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/transaction_history_controller.dart';
import '../model/transaction_model.dart';

class TransactionHistoryView extends StatelessWidget {
  const TransactionHistoryView({Key? key}) : super(key: key);

  String _getTitle(TransactionModel tx) {
    switch (tx.type) {
      case 'podcast_fund':
        return 'Podcast Fund: ${tx.podcastTitle ?? ''}';
      case 'post_fund':
        return 'Post Fund: ${tx.postDescription ?? ''}';
      case 'donation':
        return 'Donation';
      case 'withdrawal':
        return 'Withdrawal';
      default:
        return tx.type;
    }
  }

  IconData _getIcon(TransactionModel tx) {
    switch (tx.type) {
      case 'podcast_fund':
        return Icons.podcasts;
      case 'post_fund':
        return Icons.post_add;
      case 'donation':
        return Icons.volunteer_activism;
      case 'withdrawal':
        return Icons.account_balance_wallet;
      default:
        return Icons.monetization_on;
    }
  }

  Color _getColor(TransactionModel tx) {
    switch (tx.type) {
      case 'podcast_fund':
        return const Color(0xFF3B82F6);
      case 'post_fund':
        return const Color(0xFF10B981);
      case 'donation':
        return const Color(0xFF8B5CF6);
      case 'withdrawal':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TransactionHistoryController>(
      init: TransactionHistoryController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFBFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4A5568), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            centerTitle: true,
            actions: [
              Obx(() => controller.isRefreshing.value
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF4A5568)),
                      onPressed: () => controller.refreshTransactions(),
                    )),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFAFBFC),
                  Color(0xFFF7FAFC),
                ],
              ),
            ),
            child: Obx(() {
              // Loading State
              if (controller.isLoading.value && controller.transactions.isEmpty && controller.withDraws.isEmpty) {
                return _buildLoadingState();
              }

              // Error State
              if (controller.hasError.value && controller.transactions.isEmpty && controller.withDraws.isEmpty) {
                return _buildErrorState(controller);
              }

              final transactions = controller.allTransactions;
              
              if (transactions.isEmpty) {
                return _buildEmptyState();
              }

              // Group transactions by date
              final groupedTransactions = _groupTransactionsByDate(transactions);
              
              return RefreshIndicator(
                onRefresh: controller.refreshTransactions,
                color: const Color(0xFF3B82F6),
                backgroundColor: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: groupedTransactions.length,
                  itemBuilder: (context, index) {
                    final dateGroup = groupedTransactions[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                          ),
                          child: Text(
                            _formatDateHeader(dateGroup['date'] as DateTime),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                        
                        // Transactions for this date
                        ...(dateGroup['transactions'] as List<TransactionModel>).map((tx) => 
                          _buildTransactionCard(tx)
                        ),
                        
                        if (index < groupedTransactions.length - 1)
                          const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch your transaction history',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF718096).withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TransactionHistoryController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFECACA), width: 1),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Failed to Load',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              controller.errorMessage.value,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF718096).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => controller.fetchTransactions(forceRefresh: true),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            ),
            child: CustomLottieAnimation(
              jsonPath: AppImages.emptyPodcast,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF718096).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final isWithdrawal = tx.type == 'withdrawal';
    final isCompleted = tx.status == 'completed';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A202C).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColor(tx).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getColor(tx).withOpacity(0.2), width: 1),
              ),
              child: Icon(
                _getIcon(tx),
                color: _getColor(tx),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitle(tx),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(tx.date),
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF718096).withOpacity(0.8),
                    ),
                  ),
                  if (tx.status != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted 
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFFDE68A),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle : Icons.schedule,
                            size: 14,
                            color: isCompleted 
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tx.status!.capitalizeFirst!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isCompleted 
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isWithdrawal ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isWithdrawal 
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isWithdrawal ? 'Debit' : 'Credit',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF718096).withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupTransactionsByDate(List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};
    
    for (final tx in transactions) {
      final dateKey = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(tx);
    }
    
    // Sort by date (newest first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return sortedKeys.map((key) {
      final date = grouped[key]!.first.date;
      return {
        'date': DateTime(date.year, date.month, date.day),
        'transactions': grouped[key]!..sort((a, b) => b.date.compareTo(a.date)),
      };
    }).toList();
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
