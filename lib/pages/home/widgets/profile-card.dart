/// 홈 화면의 프로필 카드 위젯입니다.
/// 백엔드(GET /pet/main)에서 가져온 반려동물 정보를 표시합니다.

import 'dart:io';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-logger.dart';
import '../../../core/utils/app-size.dart';
import '../../../core/widgets/profile-select-dialog.dart';
import '../../../features/auth/bloc/auth-bloc.dart';
import '../../../features/auth/bloc/auth-event.dart';
import '../../../features/auth/models/user.dart';
import '../../../features/home/bloc/home-bloc.dart';
import '../../../features/home/bloc/home-event.dart';
import '../../../features/home/models/pet-profile.dart';

class ProfileCard extends StatelessWidget {
  final User user;
  final PetProfile? pet;
  final List<PetProfile>? profiles;
  final int? selectedProfileIndex;
  final ValueChanged<int>? onProfileSelected;
  final ValueChanged<PetProfile>? onProfilePicked;

  const ProfileCard({
    super.key,
    required this.user,
    this.pet,
    this.profiles,
    this.selectedProfileIndex,
    this.onProfileSelected,
    this.onProfilePicked,
  });

  /// 8글자 초과 시 앞 8글자 + '...' 으로 생략
  static String _truncateName(String name) {
    final t = name.trim();
    if (t.length <= 8) return t;
    return '${t.substring(0, 8)}...';
  }

  /// 기준 날짜부터 오늘까지 "N개월 N일" 형식
  static String _formatElapsedFromDate(String baseDate) {
    final birth = _parseDate(baseDate);
    if (birth == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(birth)) return '';

    var months = (today.year - birth.year) * 12 + (today.month - birth.month);
    var monthAnchor = DateTime(birth.year, birth.month + months, birth.day);
    if (monthAnchor.isAfter(today)) {
      months -= 1;
      monthAnchor = DateTime(birth.year, birth.month + months, birth.day);
    }

    final days = today.difference(monthAnchor).inDays;
    if (months > 0) return '$months개월 $days일';
    return '$days일';
  }

  static String _formatAgeFromBirth(String birthDate) {
    return _formatElapsedFromDate(birthDate);
  }

  static DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    String stripTime(String source) {
      final tIndex = source.indexOf('T');
      if (tIndex > 0) return source.substring(0, tIndex);
      final spaceIndex = source.indexOf(' ');
      if (spaceIndex > 0) return source.substring(0, spaceIndex);
      return source;
    }

    final normalized = stripTime(
      trimmed.replaceAll('.', '-').replaceAll('/', '-'),
    );
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final match = RegExp(
      r'(\d{4})\D+(\d{1,2})\D+(\d{1,2})',
    ).firstMatch(trimmed);
    if (match == null) return null;
    final year = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final day = int.tryParse(match.group(3) ?? '');
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }

  /// 홈 프로필 선택/편집 다이얼로그는 `/pet/me`를 사용한다.
  Future<List<PetProfile>> _requestMyPetProfiles(BuildContext context) {
    final completer = Completer<List<PetProfile>>();
    context.read<HomeBloc>().add(
      FetchMyPetProfilesRequested(completer: completer),
    );
    return completer.future;
  }

  Future<void> _requestDeletePetProfile(
    BuildContext context, {
    required int petId,
  }) {
    final completer = Completer<void>();
    context.read<HomeBloc>().add(
      DeletePetProfileRequested(petId: petId, completer: completer),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final isGuest = user.id == 'guest';

    if (isGuest) {
      return const _GuestProfileCard();
    }

    final isPetUnconfigured = pet == null || pet!.name.trim().isEmpty;

    final petName = isPetUnconfigured ? '' : _truncateName(pet!.name);
    final genderIconPath = (pet?.isMale ?? true)
        ? 'assets/icons/zender1.webp'
        : 'assets/icons/zender.webp';

    final ageText = isPetUnconfigured
        ? ''
        : _formatAgeFromBirth(pet!.birthDate);
    final hasAgeText = ageText.isNotEmpty;

    return Container(
      width: double.infinity,
      height: 140.s,
      padding: EdgeInsets.only(
        left: 23.s,
        right: 25.s,
        top: 19.s,
        bottom: 20.s,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.643.s),
      ),
      child: Row(
        children: [
          _ProfileAvatar(imageUrl: pet?.imageUrl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    // 카드 본문은 /pet/main으로 표시되지만, 선택/편집 다이얼로그는
                    // /pet/me(전체 목록) 기준으로 동작한다.
                    List<PetProfile> dialogProfiles;
                    try {
                      final loaded = await _requestMyPetProfiles(context);
                      dialogProfiles = loaded;
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('반려가족 목록을 불러오지 못했습니다.')),
                        );
                      }
                      return;
                    }

                    if (!context.mounted || dialogProfiles.isEmpty) return;

                    var initialIndex = 0;
                    final selectedPetId = pet?.petId;
                    if (selectedPetId != null) {
                      final matched = dialogProfiles.indexWhere(
                        (p) => p.petId == selectedPetId,
                      );
                      if (matched >= 0) {
                        initialIndex = matched;
                      }
                    } else if (selectedProfileIndex != null &&
                        selectedProfileIndex! >= 0 &&
                        selectedProfileIndex! < dialogProfiles.length) {
                      initialIndex = selectedProfileIndex!;
                    }

                    final labels = dialogProfiles
                        .asMap()
                        .entries
                        .map(
                          (e) => e.value.name.isNotEmpty
                              ? _truncateName(e.value.name)
                              : '프로필 ${e.key + 1}',
                        )
                        .toList();

                    final index = await showProfileSelectDialog(
                      context: context,
                      labels: labels,
                      imageUrls: dialogProfiles.map((e) => e.imageUrl).toList(),
                      initialSelectedIndex: initialIndex,
                      enableEdit: true,
                      onDeleteIndex: (deleteIndex) async {
                        if (deleteIndex < 0 ||
                            deleteIndex >= dialogProfiles.length) {
                          return false;
                        }

                        final targetPetId = dialogProfiles[deleteIndex].petId;
                        if (targetPetId == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('삭제할 수 없는 프로필입니다.')),
                            );
                          }
                          return false;
                        }

                        try {
                          await _requestDeletePetProfile(
                            context,
                            petId: targetPetId,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('반려가족 삭제 실패: $e')),
                            );
                          }
                          return false;
                        }

                        dialogProfiles.removeAt(deleteIndex);
                        return true;
                      },
                    );

                    if (!context.mounted || index == null) return;
                    if (index == -1) {
                      onProfileSelected?.call(-1);
                      return;
                    }
                    if (index < 0) return;
                    if (index >= dialogProfiles.length) return;

                    final selectedProfile = dialogProfiles[index];
                    if (onProfilePicked != null) {
                      onProfilePicked!(selectedProfile);
                      return;
                    }
                    if (onProfileSelected != null) {
                      final currentProfiles = profiles ?? const <PetProfile>[];
                      var resolvedIndex = -1;
                      final selectedPetId = selectedProfile.petId;
                      if (selectedPetId != null) {
                        resolvedIndex = currentProfiles.indexWhere(
                          (p) => p.petId == selectedPetId,
                        );
                      }
                      if (resolvedIndex < 0 &&
                          index >= 0 &&
                          index < currentProfiles.length) {
                        resolvedIndex = index;
                      }
                      if (resolvedIndex >= 0) {
                        onProfileSelected!.call(resolvedIndex);
                        return;
                      }
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.s,
                      vertical: 5.s,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(19.s),
                      border: Border.all(width: 1.3.s, color: AppColors.main),
                    ),
                    child: Text(
                      '반려가족 바꾸기',
                      style: TextStyle(
                        color: AppColors.main,
                        fontSize: 8.5.s,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Expanded(child: SizedBox(height: 28.s)),
                if (isPetUnconfigured)
                  Text(
                    '반려가족을 설정해주세요',
                    style: TextStyle(
                      color: const Color(0xFF383838),
                      fontFamily: AppFonts.family,
                      fontSize: 18.96.s,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.36,
                    ),
                    textAlign: TextAlign.end,
                  )
                else if (hasAgeText)
                  Text(
                    '$petName 님',
                    style: TextStyle(
                      color: const Color(0xFF383838),
                      fontFamily: AppFonts.family,
                      fontSize: 18.96.s,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.36,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$petName 님',
                        style: TextStyle(
                          color: const Color(0xFF383838),
                          fontFamily: AppFonts.family,
                          fontSize: 18.96.s,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.36,
                        ),
                      ),
                      SizedBox(width: 6.s),
                      Image.asset(
                        genderIconPath,
                        width: 6.s,
                        height: 10.s,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                if (hasAgeText) ...[
                  SizedBox(height: 4.s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$ageText / ',
                        style: TextStyle(
                          color: AppColors.font,
                          fontFamily: AppFonts.family,
                          fontSize: 11.59.s,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Image.asset(
                        genderIconPath,
                        width: 6.s,
                        height: 10.s,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 게스트 로그인 시 표시하는 카드. 원래 틀 유지, 이름/나이 자리에 회원가입 안내 텍스트.
class _GuestProfileCard extends StatelessWidget {
  const _GuestProfileCard();

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return GestureDetector(
      onTap: () => context.read<AuthBloc>().add(const SignupCancelled()),
      child: Container(
        width: double.infinity,
        height: 140.s,
        padding: EdgeInsets.only(
          left: 23.s,
          right: 25.s,
          top: 19.s,
          bottom: 20.s,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.643.s),
          border: Border.all(color: const Color(0xFFEBEBEB), width: 1.s),
        ),
        child: Row(
          children: [
            const _ProfileAvatar(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 18.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '회원가입이 필요합니다.',
                      style: TextStyle(
                        color: const Color(0xFF383838),
                        fontFamily: AppFonts.family,
                        fontSize: 17.s,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.36,
                      ),
                    ),
                    SizedBox(height: 6.s),
                    Text(
                      '회원가입 하러 가기 >',
                      style: TextStyle(
                        color: const Color(0xFFCBCBCB),
                        fontFamily: AppFonts.family,
                        fontSize: 11.6.s,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;

  const _ProfileAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    AppLogger.info('[ProfileCard] _ProfileAvatar imageUrl=$imageUrl');
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (95.95.s * devicePixelRatio).round();

    Widget inner;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final normalizedPath = _normalizeLocalPath(imageUrl!);
      if (normalizedPath != null) {
        inner = ClipOval(
          child: Image.file(
            File(normalizedPath),
            width: 95.95.s,
            height: 95.95.s,
            fit: BoxFit.cover,
            cacheWidth: cacheSize,
            cacheHeight: cacheSize,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          ),
        );
      } else {
        inner = ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: 95.95.s,
            height: 95.95.s,
            fit: BoxFit.cover,
            memCacheWidth: cacheSize,
            memCacheHeight: cacheSize,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) => _placeholder(),
            errorWidget: (context, url, error) {
              AppLogger.warn('[ProfileCard] 이미지 로드 실패 url=$url error=$error');
              return _placeholder();
            },
          ),
        );
      }
    } else {
      inner = _placeholder();
    }

    return Container(
      width: 95.95.s,
      height: 95.95.s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x33383838), width: 0.6.s),
      ),
      alignment: Alignment.center,
      child: inner,
    );
  }

  String? _normalizeLocalPath(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return null;
    }
    if (value.startsWith('file://')) {
      return value.replaceFirst('file://', '');
    }
    if (value.startsWith('/')) {
      return value;
    }
    return null;
  }

  Widget _placeholder() {
    return Image.asset(
      'assets/icons/profile-placeholder.webp',
      width: 95.95.s,
      height: 95.95.s,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
    );
  }
}
