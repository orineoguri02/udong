import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth-bloc.dart';
import '../../features/auth/bloc/auth-event.dart';
import '../theme/app-theme.dart';
import '../utils/app-size.dart';

Future<void> showSignupRequiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (dialogContext) {
      SizeConfig.init(dialogContext);
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 300.s,
          height: 157.s,
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
                '회원가입이 필요한 서비스입니다.\n회원가입 하시겠습니까?',
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
              SizedBox(height: 20.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 99.797.s,
                    height: 26.519.s,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF383838),
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
                        '취소',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 14.s,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.s),
                  SizedBox(
                    width: 99.797.s,
                    height: 26.519.s,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<AuthBloc>().add(const SignupCancelled());
                      },
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
                        '회원가입',
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
            ],
          ),
        ),
      );
    },
  );
}
