/// 반려동물 프로필 입력 화면입니다.
///
/// - 역할: 회원가입 시 반려동물 프로필을 입력받는 화면
/// - Action dispatch 중심, 동물 종류 선택은 push 라우트로 분리

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';
import '../../../core/widgets/calendar-picker.dart';
import '../../../features/auth/bloc/auth-bloc.dart';
import '../../../features/auth/bloc/auth-event.dart';
import '../../../features/auth/models/signup-pet-data.dart';
import '../../pet-family-settings/animal-type-select-page.dart';
import '../../pet-family-settings/widgets/birth-adopt-date-section.dart';
import '../../pet-family-settings/widgets/pet-form-widgets.dart';
import '../../pet-family-settings/widgets/profile-settings-section.dart';

class PetProfileInputPage extends StatefulWidget {
  final String? nickname;
  final bool marketingAgreed;

  const PetProfileInputPage({
    super.key,
    this.nickname,
    this.marketingAgreed = false,
  });

  @override
  State<PetProfileInputPage> createState() => _PetProfileInputPageState();
}

class _PetProfileInputPageState extends State<PetProfileInputPage> {
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  DateTime? _birthDate;
  DateTime? _adoptDate;
  bool _isMale = true;
  String _category = '';
  String _species = '';
  String? _petImagePath;

  @override
  void dispose() {
    _petNameController.dispose();
    _speciesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _formatApiDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final result = await showCalendarPicker(
      context,
      initialDate: _birthDate ?? yesterday,
      firstDate: DateTime(2000, 1, 1),
      lastDate: yesterday, // 생년월일은 오늘·미래 선택 불가
    );
    if (result != null) {
      setState(() {
        _birthDate = result;
        if (_adoptDate != null && _adoptDate!.isBefore(_birthDate!)) {
          _adoptDate = _birthDate;
        }
      });
    }
  }

  Future<void> _pickAdopt() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minAdoptDate = _birthDate ?? DateTime(2000, 1, 1);
    final initial = _adoptDate != null
        ? (_adoptDate!.isBefore(minAdoptDate) ? minAdoptDate : _adoptDate!)
        : (today.isBefore(minAdoptDate) ? minAdoptDate : today);
    final result = await showCalendarPicker(
      context,
      initialDate: initial,
      firstDate: minAdoptDate, // 입양일은 생년월일보다 이전 불가
      lastDate: today,
    );
    if (result != null) setState(() => _adoptDate = result);
  }

  void _submitSignup() {
    final petName = _petNameController.text.trim();
    final birthday = _formatApiDate(_birthDate);
    final adoptedAt = _formatApiDate(_adoptDate);
    final pet = SignupPetData(
      name: petName.isEmpty ? '반려동물' : petName,
      species: _category.isEmpty ? '기타' : _category,
      breed: _species.isEmpty ? '' : _species,
      birthday: birthday.isEmpty ? _formatApiDate(DateTime.now()) : birthday,
      adoptedAt: adoptedAt.isEmpty ? _formatApiDate(DateTime.now()) : adoptedAt,
      gender: _isMale ? 'male' : 'female',
    );
    context.read<AuthBloc>().add(
      SignupCompleted(
        nickname: widget.nickname,
        pet: pet,
        petImagePath: _petImagePath,
        marketingAgreed: widget.marketingAgreed,
      ),
    );
  }

  void _skipPet() {
    context.read<AuthBloc>().add(
      SignupCompleted(
        nickname: widget.nickname,
        marketingAgreed: widget.marketingAgreed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/icon-arrow-right-small-mono.webp',
            width: 24.s,
            height: 24.s,
            fit: BoxFit.contain,
          ),
          onPressed: () =>
              context.read<AuthBloc>().add(const SignupBackFromPetProfile()),
          padding: EdgeInsets.zero,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 17.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '반려동물 정보를 입력해주세요',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 20.s,
                fontWeight: FontWeight.w800,
                color: AppColors.font,
                height: 1.2,
              ),
            ),
            SizedBox(height: 8.s),
            Text(
              '나중에 마이페이지에서 수정할 수 있어요',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 13.s,
                fontWeight: FontWeight.w400,
                color: AppColors.fontLight,
                height: 1.69,
                letterSpacing: -0.32.s,
              ),
            ),
            SizedBox(height: 28.s),
            PetMainProfileSection(
              onImagePicked: (path) => setState(() => _petImagePath = path),
            ),
            SizedBox(height: 20.s),
            PetLabeledTextField(
              label: '반려가족 이름',
              hintText: '꼬북이',
              controller: _petNameController,
              maxLength: 20,
            ),
            SizedBox(height: 22.s),
            Padding(
              padding: EdgeInsets.only(left: 13.s),
              child: Text(
                '성별',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 13.s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.font,
                ),
              ),
            ),
            SizedBox(height: 8.s),
            PetGenderSelector(
              initialIsMale: _isMale,
              onChanged: (isMale) => setState(() => _isMale = isMale),
            ),
            SizedBox(height: 22.s),
            Row(
              children: [
                Expanded(
                  child: PetCompactLabeledTextField(
                    key: ValueKey('cat$_category'),
                    label: '동물 종류',
                    hintText: '동물 종류 선택',
                    initialText: _category.isEmpty
                        ? null
                        : (_species.isEmpty
                              ? _category
                              : '$_category · $_species'),
                    showArrow: true,
                    width: double.infinity,
                    onTap: () async {
                      final result = await Navigator.of(context)
                          .push<Map<String, String>>(
                            MaterialPageRoute<Map<String, String>>(
                              builder: (_) => const AnimalTypeSelectPage(),
                            ),
                          );
                      if (result != null && mounted) {
                        setState(() {
                          _category = result['category'] ?? '';
                          final selectedSpecies = result['species'] ?? '';
                          if (selectedSpecies.isEmpty ||
                              selectedSpecies == '직접입력') {
                            _species = '';
                            _speciesController.text = '';
                          } else {
                            _species = selectedSpecies;
                            _speciesController.text = selectedSpecies;
                          }
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 16.s),
                Expanded(
                  child: PetCompactLabeledTextField(
                    key: const ValueKey('spec-field'),
                    label: '세부 종',
                    hintText: '직접입력',
                    controller: _speciesController,
                    onChanged: (value) =>
                        setState(() => _species = value.trim()),
                    width: double.infinity,
                  ),
                ),
              ],
            ),
            SizedBox(height: 22.s),
            Row(
              children: [
                Expanded(
                  child: PetDateField(
                    label: '생년월일',
                    value: _formatDate(_birthDate),
                    onTap: _pickBirth,
                    width: double.infinity,
                  ),
                ),
                SizedBox(width: 16.s),
                Expanded(
                  child: PetDateField(
                    label: '입양일자',
                    value: _formatDate(_adoptDate),
                    onTap: _pickAdopt,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
            SizedBox(height: 48.s),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 145.s,
                    height: 37.s,
                    child: OutlinedButton(
                      onPressed: _submitSignup,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.main, width: 1.24.s),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.5.s),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.main,
                      ),
                      child: Text(
                        '회원가입 완료',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 16.s,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.s),
                  GestureDetector(
                    onTap: _skipPet,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.s,
                        horizontal: 4.s,
                      ),
                      child: Text(
                        '나중에 할게요',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 13.s,
                          fontWeight: FontWeight.w800,
                          color: const Color.fromRGBO(255, 150, 69, 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 22.s),
          ],
        ),
      ),
    );
  }
}
