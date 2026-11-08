import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-size.dart';
import '../../core/widgets/page-title-app-bar.dart';
import '../../features/auth/bloc/auth-bloc.dart';
import '../../features/auth/bloc/auth-event.dart';
import '../../features/auth/models/user.dart';
import '../../features/auth/models/user-profile.dart';

class ProfileEditPage extends StatefulWidget {
  final User user;
  final UserProfile profile;

  const ProfileEditPage({super.key, required this.user, required this.profile});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _loginAccountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profileName = widget.profile.name?.trim();
    final initialName = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : '이름없음';
    _nameController = TextEditingController(text: initialName);
    _loginAccountController = TextEditingController(
      text: widget.profile.email ?? widget.user.email ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _loginAccountController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름을 입력해주세요.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final completer = Completer<UserProfile>();
      context.read<AuthBloc>().add(
        ProfileNameUpdateRequested(
          userId: widget.profile.id,
          name: name,
          completer: completer,
        ),
      );
      await completer.future;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름이 수정되었습니다.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('프로필 수정 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: PageTitleAppBar(title: '프로필 수정'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(15.s, 28.s, 15.s, 0.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 13.s),
              child: Text(
                '기본 정보',
                style: TextStyle(
                  color: Color(0xFF383838),
                  fontSize: 18.9.s,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: 17.87.s),
            _ProfileInfoField(label: '사용자 이름', controller: _nameController),
            SizedBox(height: 17.87.s),
            _ProfileInfoField(
              label: '로그인 계정정보',
              controller: _loginAccountController,
              readOnly: true,
            ),
            SizedBox(height: 23.92.s),
            Center(
              child: SizedBox(
                width: 93.279.s,
                child: OutlinedButton(
                  onPressed: _saveProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.main,
                    side: BorderSide(color: AppColors.main, width: 1.24.s),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.2.s),
                    ),
                    minimumSize: Size(0, 0),
                    padding: EdgeInsets.symmetric(vertical: 7.s),
                  ),
                  child: Text(
                    '저장하기',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 13.65.s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;

  const _ProfileInfoField({
    required this.label,
    required this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 13.s),
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF383838),
              fontSize: 15.8.s,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 10.s),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12.644.s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                offset: Offset(0, 0),
                blurRadius: 3.s,
                spreadRadius: 0.198.s,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15.s,
                vertical: 16.s,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintStyle: TextStyle(
                color: const Color(0xFF383838),
                fontSize: 15.8.s,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
