import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CustomCheckboxTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String text;
  final VoidCallback? onTextTap;

  const CustomCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.text,
    this.onTextTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-8, -4),
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor:AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                width: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: onTextTap == null
                  ? AppText(text: text)
                  : GestureDetector(
                      onTap: onTextTap,
                      child: AppText(
                        text: text,
                        color: AppColors.blue,
                        fontWeight: FontWeight.w500,
                        textAlign: TextAlign.start,
                       // decoration: TextDecoration.underline,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
