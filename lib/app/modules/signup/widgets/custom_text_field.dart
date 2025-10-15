import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Color? fillColor;
  final Color? borderColor;
  final bool filled;
  final String? hint;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final VoidCallback? onFieldTap;
  final bool readOnly;

  // Dropdown-specific fields
  final bool isDropdown;
  final Color? hintColor;
  final List<String>? items;
  final String? selectedValue;
  final void Function(String?)? onDropdownChanged;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.fillColor,
    this.borderColor,
    this.filled = true,
    this.hint,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.onFieldTap,
    this.readOnly = false,
    this.isDropdown = false,
    this.items,
    this.selectedValue,
    this.onDropdownChanged,
    this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color actualFillColor = fillColor ?? AppColors.cultured;
    final Color actualBorderColor = borderColor ?? AppColors.gunmetal;

    final inputDecoration = InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onBackground.withOpacity(0.5),
          ),
      filled: filled,
      fillColor: actualFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: actualBorderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: actualBorderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: actualBorderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      errorStyle: const TextStyle(color: AppColors.error),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
    );

    // Use DropdownButtonFormField if isDropdown is true
    if (isDropdown) {
      return DropdownButtonFormField<String>(
        value: selectedValue,
        items: items
            ?.map(
              (item) => DropdownMenuItem(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: onDropdownChanged,
        validator: validator,
        decoration: inputDecoration,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.onBackground),
      );
    }

    // Default to TextFormField
    return Builder(
      builder: (context) {
        // Create a safe controller that handles disposed state
        TextEditingController? safeController;
        
        if (controller != null) {
          try {
            // Try to access the controller to check if it's disposed
            final text = controller!.text;
            safeController = controller;
          } catch (e) {
            // Controller is disposed, create a new one
            safeController = TextEditingController();
          }
        }

        return TextFormField(
          onTapOutside: (event) {
            FocusScope.of(context).unfocus(); // Dismiss keyboard
          },
          controller: safeController,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          autocorrect: true,
          enableSuggestions: true,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          onTap: onFieldTap,
          readOnly: readOnly,
          cursorColor: AppColors.onBackground,
          onChanged: onChanged,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.onBackground),
          decoration: inputDecoration.copyWith(
            hintText: label,
          ),
          validator: validator,
        );
      },
    );
  }
}
