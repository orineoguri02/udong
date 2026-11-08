import 'package:flutter/material.dart';

import '../theme/app-theme.dart';
import '../utils/app-size.dart';

/// 회원가입 필요 다이얼로그와 동일한 디자인의 단일 메시지 + 확인 버튼 다이얼로그.
Future<void> showCenteredMessageDialog(
  BuildContext context, {
  required String message,
  String confirmLabel = '확인',
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (dialogContext) {
      SizeConfig.init(dialogContext);
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 300.s,
          height: 132.s,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12.644.s),
          ),
          padding: EdgeInsets.only(
            top: 8.s,
            left: 30.s,
            right: 30.s,
            bottom: 8.s,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF383838),
                  fontFamily: AppFonts.family,
                  fontSize: 14.s,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w800,
                  height: 22 / 14,
                ),
              ),
              SizedBox(height: 28.s),
              SizedBox(
                width: 99.797.s,
                height: 26.519.s,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.main,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13.196.s),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 14.s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
