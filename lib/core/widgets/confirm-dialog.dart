import 'package:flutter/material.dart';

import '../theme/app-theme.dart';
import '../utils/app-size.dart';

Future<void> showConfirmDialog({
  required BuildContext context,
  required String highlightText,
  required String message,
  required String confirmLabel,
  required VoidCallback onConfirm,
  String cancelLabel = '취소',
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => _ConfirmDialog(
      highlightText: highlightText,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
    ),
  );
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _DialogButton({
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 114.558.s,
      height: 30.442.s,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.147.s),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 14.s,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String highlightText;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.highlightText,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 346.s,
        height: 178.s,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.644.s),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 5.268.s,
              spreadRadius: 0.198.s,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 20.3.s,
                  fontWeight: FontWeight.w800,
                  color: AppColors.font,
                ),
                children: [
                  TextSpan(
                    text: highlightText,
                    style: const TextStyle(color: AppColors.main),
                  ),
                  TextSpan(text: message),
                ],
              ),
            ),
            SizedBox(height: 20.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DialogButton(
                  label: cancelLabel,
                  backgroundColor: const Color(0xFF383838),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                SizedBox(width: 10.s),
                _DialogButton(
                  label: confirmLabel,
                  backgroundColor: AppColors.main,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
