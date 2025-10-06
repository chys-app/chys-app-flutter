import 'package:chys/app/core/validators/form_validators.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/widgets/custom_text_field.dart';

class AddBankInfoScreen extends StatelessWidget {
  const AddBankInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

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
          'Add Bank Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Secure Banking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your banking information is encrypted and secure',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF1E40AF).withOpacity(0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Form Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A202C).withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bank Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Account Holder Name
                      _buildFormField(
                        controller: controller.accountHolderName,
                        label: "Account Holder Name",
                        hint: "Enter full name as it appears on your account",
                        icon: Icons.person,
                        validator: (value) => FormValidators.validateRequired(
                            value, "Account Holder Name"),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Bank Name
                      _buildFormField(
                        controller: controller.bankName,
                        label: "Bank Name",
                        hint: "Enter your bank name",
                        icon: Icons.account_balance,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Account Type
                      _buildAccountTypeDropdown(controller),
                      
                      const SizedBox(height: 20),
                      
                      // Routing Number
                      _buildFormField(
                        controller: controller.routingNumber,
                        label: "Routing Number",
                        hint: "Enter 9-digit routing number",
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            FormValidators.validateRequired(value, "Routing Number"),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Account Number
                      _buildFormField(
                        controller: controller.accountNumber,
                        label: "Account Number",
                        hint: "Enter your account number",
                        icon: Icons.credit_card,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            FormValidators.validateRequired(value, "Account Number"),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Bank Address (Optional)
                      _buildFormField(
                        controller: controller.bankAddress,
                        label: "Bank Address (Optional)",
                        hint: "Enter bank branch address",
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                controller.updateBankDetails();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.save,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Bank Information',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Security Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your information is encrypted and secure. We use bank-level security to protect your data.',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF92400E).withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Icon(
                icon,
                size: 16,
                color: const Color(0xFF4A5568),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: controller,
          label: hint,
          hint: hint,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          fillColor: const Color(0xFFF7FAFC),
          borderColor: const Color(0xFFE2E8F0),
        ),
      ],
    );
  }

  Widget _buildAccountTypeDropdown(ProfileController controller) {
    final accountTypes = [
      'Checking',
      'Savings',
      'Business',
      'Credit Union',
      'Investment',
      'Other'
    ];

    // Helper function to normalize account type for comparison
    String normalizeAccountType(String type) {
      return type.toLowerCase().trim();
    }

    // Find the matching account type (case-insensitive)
    String? getMatchingValue() {
      if (controller.accountType.value.isEmpty) return null;
      
      final normalizedCurrentValue = normalizeAccountType(controller.accountType.value);
      for (String type in accountTypes) {
        if (normalizeAccountType(type) == normalizedCurrentValue) {
          return type; // Return the properly capitalized version
        }
      }
      return null; // No match found
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 16,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Account Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: DropdownButtonFormField<String>(
            value: getMatchingValue(),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              hintText: 'Select account type',
              hintStyle: TextStyle(
                color: Color(0xFFA0AEC0),
                fontSize: 16,
              ),
            ),
            items: accountTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(
                  type,
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.accountType.value = newValue;
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an account type';
              }
              return null;
            },
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF4A5568),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
