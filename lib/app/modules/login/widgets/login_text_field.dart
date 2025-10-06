import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LoginTextField extends StatefulWidget {
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

  const LoginTextField({
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
  });

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField> {
  late TextEditingController _localController;

  @override
  void initState() {
    super.initState();
    _localController = TextEditingController();
    _initializeText();
  }

  void _initializeText() {
    // Copy text from the provided controller if it's valid
    if (widget.controller != null) {
      try {
        _localController.text = widget.controller!.text;
      } catch (e) {
        // Controller is disposed, use empty text
        _localController.text = '';
      }
    }
  }

  @override
  void didUpdateWidget(LoginTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the controller changed, reinitialize the text
    if (oldWidget.controller != widget.controller) {
      _initializeText();
    }
  }

  void _syncTextToController() {
    // Don't sync to the original controller to avoid disposed controller errors
    // The LoginController will access the text through the onChanged callback
  }

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color actualFillColor = widget.fillColor ?? AppColors.cultured;
    final Color actualBorderColor = widget.borderColor ?? AppColors.gunmetal;

    final inputDecoration = InputDecoration(
      hintText: widget.hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onBackground.withOpacity(0.5),
          ),
      filled: widget.filled,
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
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      errorStyle: TextStyle(color: AppColors.error),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: widget.suffixIcon,
    );

    return TextFormField(
      onTapOutside: (event) {
        FocusScope.of(context).unfocus(); // Dismiss keyboard
      },
      controller: _localController,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      autocorrect: true,
      enableSuggestions: true,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onFieldTap,
      readOnly: widget.readOnly,
      cursorColor: AppColors.onBackground,
      onChanged: (value) {
        // Sync text to original controller immediately
        _syncTextToController();
        // Call the original onChanged if provided
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppColors.onBackground),
      decoration: inputDecoration.copyWith(
        hintText: widget.label,
      ),
      validator: widget.validator,
    );
  }
}
