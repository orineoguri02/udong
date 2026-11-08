/// 약관 동의 화면입니다.
///
/// - 역할: 회원가입 전 필수/선택 약관에 동의하는 화면
/// - Navigator 없음 — Action dispatch만 수행

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';
import '../../../features/auth/bloc/auth-bloc.dart';
import '../../../features/auth/bloc/auth-event.dart';

class TermsAgreementPage extends StatefulWidget {
  const TermsAgreementPage({super.key});

  @override
  State<TermsAgreementPage> createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends State<TermsAgreementPage> {
  final List<_TermsItem> _items = [
    _TermsItem(title: '개인정보 취급방침', isRequired: true),
    _TermsItem(title: '사용자 이용약관', isRequired: true),
    _TermsItem(title: '위치정보 서비스 이용약관', isRequired: true),
    _TermsItem(title: '제3자 정보제공 동의', isRequired: true),
    _TermsItem(title: '만 14세 이상입니다.', isRequired: true),
    _TermsItem(title: '마케팅 정보 이용 동의', isRequired: false),
  ];

  bool get _isAllChecked => _items.every((e) => e.isChecked);
  bool get _allRequiredChecked =>
      _items.where((e) => e.isRequired).every((e) => e.isChecked);

  void _toggleAll() {
    final newValue = !_isAllChecked;
    setState(() {
      for (final item in _items) {
        item.isChecked = newValue;
      }
    });
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index].isChecked = !_items[index].isChecked;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    // 시스템 뒤로가기: Flux 규칙에 따라 dispatch만 하고, _AuthGate가 로그인 화면으로 전환
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.read<AuthBloc>().add(const SignupCancelled());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
          leading: IconButton(
            padding: EdgeInsets.only(left: 12.s),
            icon: Image.asset(
              'assets/icons/icon-arrow-right-small-mono.webp',
              width: 24.s,
              height: 24.s,
            ),
            onPressed: () =>
                context.read<AuthBloc>().add(const SignupCancelled()),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.s,
                right: 24.s,
                top: 12.s,
                bottom: 20.s + bottomPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30.s),
                    Image.asset(
                      'assets/icons/logo-icon.webp',
                      width: 56.s,
                      height: 56.s,
                    ),
                    SizedBox(height: 17.s),
                    Text(
                      '약관 동의',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 25.s,
                        fontWeight: FontWeight.w800,
                        color: AppColors.font,
                      ),
                    ),
                    SizedBox(height: 10.s),
                    Text(
                      '함께하는 반려 동물의 정확한 데이터 조회,\n정확한 의료 정보 서비스 제공을 위하여 꼭 필요합니다.',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 13.s,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF383838),
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 16.s),
                    _buildNoticeBox(),
                    SizedBox(height: 32.s),
                    _buildAllAgreeRow(),
                    SizedBox(height: 28.s),
                    Column(
                      children: [
                        for (int index = 0; index < _items.length; index++) ...[
                          _buildTermsRow(index),
                          if (index != _items.length - 1)
                            SizedBox(height: 20.s),
                        ],
                      ],
                    ),
                    SizedBox(height: 44.s),
                    _buildAgreeButton(context),
                    SizedBox(height: 24.s),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoticeBox() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.s),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(27.s),
      ),
      child: Text(
        '우동은 만 14세 미만 아동의 회원가입을 제한하고 있습니다.',
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 12.s,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF969696),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAllAgreeRow() {
    return GestureDetector(
      onTap: _toggleAll,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _CircleCheckbox(checked: _isAllChecked),
          SizedBox(width: 15.s),
          Text(
            '전체 약관에 동의합니다.',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 17.s,
              fontWeight: FontWeight.w400,
              color: AppColors.font,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsRow(int index) {
    final item = _items[index];
    return GestureDetector(
      onTap: () => _toggleItem(index),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _CircleCheckbox(checked: item.isChecked),
          SizedBox(width: 16.s),
          Expanded(
            child: Text(
              '${item.title} (${item.isRequired ? '필수' : '선택'})',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 13.s,
                fontWeight: FontWeight.w400,
                color: AppColors.font,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreeButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 145.s,
        height: 37.s,
        child: OutlinedButton(
          onPressed: _allRequiredChecked
              ? () {
                  final marketingAgreed = _items.last.isChecked;
                  context.read<AuthBloc>().add(TermsAgreed(marketingAgreed));
                }
              : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _allRequiredChecked
                  ? const Color(0xFFFF9645)
                  : const Color(0xFFD0D0D0),
              width: 1.24.s,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.5.s),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFFF9645),
            disabledForegroundColor: const Color(0xFFBDBDBD),
          ),
          child: Text(
            '동의합니다.',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13.s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsItem {
  final String title;
  final bool isRequired;
  bool isChecked = false;

  _TermsItem({required this.title, required this.isRequired});
}

class _CircleCheckbox extends StatelessWidget {
  final bool checked;

  const _CircleCheckbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22.s,
      height: 22.s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: checked ? AppColors.main : const Color(0xFFD0D0D0),
          width: 2.5.s,
        ),
      ),
      child: checked
          ? Center(
              child: Container(
                width: 11.s,
                height: 11.s,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.main,
                ),
              ),
            )
          : null,
    );
  }
}
