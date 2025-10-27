import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/services/payment_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PromoteProductView extends StatefulWidget {
  final Products product;

  const PromoteProductView({Key? key, required this.product}) : super(key: key);

  @override
  State<PromoteProductView> createState() => _PromoteProductViewState();
}

class _PromoteProductViewState extends State<PromoteProductView> {
  int? _selectedPlanIndex;
  String _selectedPlanType = 'local'; // 'local' or 'nationwide'

  final List<Map<String, dynamic>> _localPromotionPlans = [
    {
      'duration': '1 Week',
      'price': 5.0,
      'days': 7,
      'description': 'Boost your product visibility for 7 days',
      'icon': Icons.calendar_today,
      'type': 'local',
    },
    {
      'duration': '2 Weeks',
      'price': 9.0,
      'days': 14,
      'description': 'Extended promotion for 14 days',
      'icon': Icons.calendar_view_week,
      'popular': true,
      'type': 'local',
    },
    {
      'duration': '1 Month',
      'price': 19.0,
      'days': 30,
      'description': 'Maximum exposure for 30 days',
      'icon': Icons.calendar_month,
      'type': 'local',
    },
  ];

  final List<Map<String, dynamic>> _nationwidePromotionPlans = [
    {
      'duration': '1 Week',
      'price': 99.0,
      'days': 7,
      'description': 'Nationwide visibility for 7 days',
      'icon': Icons.public,
      'type': 'nationwide',
    },
    {
      'duration': '2 Weeks',
      'price': 189.0,
      'days': 14,
      'description': 'Extended nationwide reach for 14 days',
      'icon': Icons.language,
      'popular': true,
      'type': 'nationwide',
    },
    {
      'duration': '1 Month',
      'price': 299.0,
      'days': 30,
      'description': 'Maximum nationwide exposure for 30 days',
      'icon': Icons.travel_explore,
      'type': 'nationwide',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF262626)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Promote Product',
          style: TextStyle(
            color: Color(0xFF262626),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product preview card
                  _buildProductPreview(),
                  const SizedBox(height: 24),

                  // Promotion benefits
                  _buildPromotionBenefits(),
                  const SizedBox(height: 24),

                  // Local Promotion Section
                  const Text(
                    'Local Promotion',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Promote to users in your area',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Local promotion plans
                  ...List.generate(
                    _localPromotionPlans.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPlanCard(index, 'local'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nationwide Promotion Section
                  Row(
                    children: [
                      const Text(
                        'Promote Nationwide',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF262626),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PREMIUM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reach customers across the entire country',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nationwide promotion plans
                  ...List.generate(
                    _nationwidePromotionPlans.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPlanCard(index, 'nationwide'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Purchase button
          _buildPurchaseButton(),
        ],
      ),
    );
  }

  Widget _buildProductPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.product.media.isNotEmpty
                ? Image.network(
                    widget.product.media.first,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 16),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF262626),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${widget.product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0095F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionBenefits() {
    final benefits = [
      {'icon': Icons.visibility, 'text': 'Increased visibility'},
      {'icon': Icons.trending_up, 'text': 'Higher ranking in search'},
      {'icon': Icons.people, 'text': 'Reach more customers'},
      {'icon': Icons.star, 'text': 'Featured badge on listing'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0095F6).withOpacity(0.1),
            const Color(0xFF00C851).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0095F6).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.campaign,
                color: Color(0xFF0095F6),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Promotion Benefits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF262626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      benefit['icon'] as IconData,
                      size: 20,
                      color: const Color(0xFF0095F6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      benefit['text'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF262626),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index, String planType) {
    final plans = planType == 'local' ? _localPromotionPlans : _nationwidePromotionPlans;
    final plan = plans[index];
    final isSelected = _selectedPlanIndex == index && _selectedPlanType == planType;
    final isNationwide = planType == 'nationwide';
    final isPopular = plan['popular'] == true;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
          _selectedPlanType = planType;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0095F6)
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0095F6).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isNationwide && isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          )
                        : null,
                    color: isNationwide && !isSelected
                        ? const Color(0xFFFFD700).withOpacity(0.1)
                        : isSelected
                            ? const Color(0xFF0095F6).withOpacity(0.1)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    plan['icon'] as IconData,
                    color: isNationwide && isSelected
                        ? Colors.white
                        : isNationwide
                            ? const Color(0xFFFFA500)
                            : isSelected
                                ? const Color(0xFF0095F6)
                                : Colors.grey.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Plan details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['duration'] as String,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isNationwide && isSelected
                              ? const Color(0xFFFFA500)
                              : isSelected
                                  ? const Color(0xFF0095F6)
                                  : const Color(0xFF262626),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${plan['price'].toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isNationwide && isSelected
                            ? const Color(0xFFFFA500)
                            : isSelected
                                ? const Color(0xFF0095F6)
                                : const Color(0xFF262626),
                      ),
                    ),
                    Text(
                      '${plan['days']} days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                // Selection indicator
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isNationwide && isSelected
                          ? const Color(0xFFFFA500)
                          : isSelected
                              ? const Color(0xFF0095F6)
                              : Colors.grey.shade300,
                      width: 2,
                    ),
                    color: isNationwide && isSelected
                        ? const Color(0xFFFFA500)
                        : isSelected
                            ? const Color(0xFF0095F6)
                            : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Popular badge
          if (isPopular)
            Positioned(
              top: -8,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton() {
    final isEnabled = _selectedPlanIndex != null;
    final plans = _selectedPlanType == 'local' ? _localPromotionPlans : _nationwidePromotionPlans;
    final selectedPlan = isEnabled ? plans[_selectedPlanIndex!] : null;
    final isNationwide = _selectedPlanType == 'nationwide';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEnabled) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8E8E8E),
                    ),
                  ),
                  Text(
                    '\$${selectedPlan!['price']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0095F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isEnabled ? _handlePurchase : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled && isNationwide
                      ? const Color(0xFFFFA500)
                      : const Color(0xFF0095F6),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isEnabled ? 4 : 0,
                  shadowColor: const Color(0xFF0095F6).withOpacity(0.3),
                ),
                child: Text(
                  isEnabled ? 'Purchase Promotion' : 'Select a Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase() {
    if (_selectedPlanIndex == null) return;

    final plans = _selectedPlanType == 'local' ? _localPromotionPlans : _nationwidePromotionPlans;
    final selectedPlan = plans[_selectedPlanIndex!];
    final isNationwide = _selectedPlanType == 'nationwide';

    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Color(0xFF0095F6)),
            SizedBox(width: 12),
            Text('Confirm Promotion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to promote:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.product.description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF262626),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isNationwide
                    ? LinearGradient(
                        colors: [Color(0xFFFFD700).withOpacity(0.2), Color(0xFFFFA500).withOpacity(0.2)],
                      )
                    : null,
                color: isNationwide ? null : const Color(0xFF0095F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Duration:'),
                      Text(
                        selectedPlan['duration'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Price:'),
                      Text(
                        '\$${selectedPlan['price'].toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isNationwide ? const Color(0xFFFFA500) : const Color(0xFF0095F6),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _processPurchase(selectedPlan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0095F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm Purchase'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(Map<String, dynamic> plan) async {
    try {
      final amount = plan['price'].toString();
      final promotionId = widget.product.id; // Using product ID as promotion identifier
      
      // Process Stripe payment
      final success = await PaymentServices.stripePayment(
        amount,
        promotionId,
        context,
        onSuccess: () async {
          // Show success message
          Get.snackbar(
            'Promotion Activated!',
            'Your ${_selectedPlanType == 'nationwide' ? 'nationwide' : 'local'} promotion for ${plan['duration']} has been activated successfully!',
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            margin: const EdgeInsets.all(16),
          );
          
          // Navigate back after showing success message
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Get.back();
            }
          });
        },
      );
      
      // Payment was cancelled or failed - don't show error, user cancelled intentionally
      if (!success) {
        // Just silently return, the PaymentServices already handles error messages
        return;
      }
    } catch (e) {
      // Only show error for unexpected exceptions
      print('Error in _processPurchase: $e');
      // Don't show error snackbar as PaymentServices already handles it
    }
  }
}
