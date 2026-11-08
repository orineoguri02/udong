/// 마이페이지 화면(UI) 파일입니다.
///
/// - 역할: 프로필 정보 표시, 로그아웃, 프로필 수정 및 설정 메뉴 제공

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-size.dart';
import '../../core/widgets/confirm-dialog.dart';
import '../../core/widgets/page-title-app-bar.dart';
import '../../features/auth/bloc/auth-bloc.dart';
import '../../features/auth/bloc/auth-event.dart';
import '../../features/auth/bloc/auth-state.dart';
import '../../features/auth/models/user.dart';
import '../../features/auth/models/user-profile.dart';
import '../../features/home/bloc/home-bloc.dart';
import '../../features/home/bloc/home-event.dart';
import '../../features/home/bloc/home-state.dart';
import '../../features/home/models/pet-profile.dart';
import 'profile-edit-page.dart';
import 'terms-page.dart';
import '../pet-family-settings/pet-family-settings-page.dart';
import 'inquiry-page.dart';
import 'member-withdrawal-page.dart';
import 'notification-page.dart';

class MyPageResult {
  final int selectedPetIndex;
  final List<PetProfile> petProfiles;

  const MyPageResult({
    required this.selectedPetIndex,
    required this.petProfiles,
  });
}

class MyPage extends StatefulWidget {
  final User user;
  final int initialPetIndex;
  final List<PetProfile> initialPetProfiles;

  const MyPage({
    super.key,
    required this.user,
    this.initialPetIndex = 0,
    this.initialPetProfiles = const [],
  });

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late int _selectedPetIndex;
  late List<PetProfile> _petProfiles;

  @override
  void initState() {
    super.initState();
    final homeState = context.read<HomeBloc>().state;
    if (homeState.profiles.isNotEmpty) {
      _petProfiles = List<PetProfile>.from(homeState.profiles);
      _selectedPetIndex = homeState.selectedProfileIndex;
      if (_selectedPetIndex < 0 || _selectedPetIndex >= _petProfiles.length) {
        _selectedPetIndex = 0;
      }
    } else {
      _selectedPetIndex = widget.initialPetIndex;
      _petProfiles = List<PetProfile>.from(widget.initialPetProfiles);
    }
    if (homeState.user.id != 'guest' && homeState.profiles.isEmpty) {
      context.read<HomeBloc>().add(const RefreshHome());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(const ProfileFetchRequested());
    });
  }

  void _refreshProfile() {
    context.read<AuthBloc>().add(
      const ProfileFetchRequested(forceRefresh: true),
    );
  }

  void _syncFromHomeState(HomeState state) {
    if (!mounted) return;
    var nextIndex = state.selectedProfileIndex;
    if (state.profiles.isEmpty) {
      nextIndex = 0;
    } else if (nextIndex < 0 || nextIndex >= state.profiles.length) {
      nextIndex = 0;
    }
    final nextProfiles = List<PetProfile>.from(state.profiles);
    final changed =
        _selectedPetIndex != nextIndex ||
        !HomeState.areSameProfiles(_petProfiles, nextProfiles);
    if (!changed) return;

    setState(() {
      _selectedPetIndex = nextIndex;
      _petProfiles = nextProfiles;
    });
  }

  Future<void> _openPetFamilySettings() async {
    final result = await Navigator.of(context).push<PetFamilySettingsResult>(
      MaterialPageRoute<PetFamilySettingsResult>(
        builder: (_) => PetFamilySettingsPage(
          initialSelectedIndex: _selectedPetIndex,
          initialProfiles: _petProfiles,
        ),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      _selectedPetIndex = result.selectedIndex;
      _petProfiles = List<PetProfile>.from(result.profiles);
    });
    context.read<HomeBloc>().add(
      ProfilesUpdated(
        profiles: List<PetProfile>.from(result.profiles),
        selectedIndex: result.selectedIndex,
      ),
    );

    Navigator.of(context).pop(
      MyPageResult(
        selectedPetIndex: _selectedPetIndex,
        petProfiles: _petProfiles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeBloc, HomeState>(
          listenWhen: (previous, current) {
            return previous.selectedProfileIndex !=
                    current.selectedProfileIndex ||
                !HomeState.areSameProfiles(previous.profiles, current.profiles);
          },
          listener: (context, state) {
            _syncFromHomeState(state);
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            if (current is AuthUnauthenticated || current is AuthGuest) {
              return true;
            }
            if (current is AuthAuthenticated) {
              final prevError = previous is AuthAuthenticated
                  ? previous.logoutError
                  : null;
              return current.logoutError != null &&
                  current.logoutError!.isNotEmpty &&
                  current.logoutError != prevError;
            }
            return false;
          },
          listener: (context, state) {
            if (state is AuthUnauthenticated || state is AuthGuest) {
              Navigator.of(context).pop();
              return;
            }
            if (state is AuthAuthenticated &&
                state.logoutError != null &&
                state.logoutError!.isNotEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.logoutError!)));
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: PageTitleAppBar(title: '마이페이지'),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(15.s, 14.s, 15.s, 35.s),
          child: BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) {
              if (previous is AuthAuthenticated &&
                  current is AuthAuthenticated) {
                return previous.user.id != current.user.id ||
                    previous.user.serverId != current.user.serverId ||
                    previous.user.displayName != current.user.displayName ||
                    previous.user.email != current.user.email ||
                    previous.profile != current.profile;
              }
              return previous.runtimeType != current.runtimeType;
            },
            builder: (context, state) {
              final authenticated = state is AuthAuthenticated ? state : null;
              final user = authenticated?.user ?? widget.user;
              final profile = authenticated?.profile;
              return Column(
                children: [
                  _ProfileSection(
                    user: user,
                    profile: profile,
                    onProfileUpdated: _refreshProfile,
                  ),
                  SizedBox(height: 14.s),
                  _MenuSection(onPetFamilySettingsTap: _openPetFamilySettings),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final User user;
  final UserProfile? profile;
  final VoidCallback onProfileUpdated;

  const _ProfileSection({
    required this.user,
    required this.profile,
    required this.onProfileUpdated,
  });

  void _logout(BuildContext context) {
    showConfirmDialog(
      context: context,
      highlightText: '로그아웃',
      message: ' 하시겠습니까?',
      confirmLabel: '로그아웃',
      onConfirm: () {
        context.read<AuthBloc>().add(const LogoutRequested());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final profileName = profile?.name?.trim() ?? '';
    final userName = user.displayName.trim();
    final displayName = profileName.isNotEmpty
        ? profileName
        : (userName.isNotEmpty ? userName : '이름없음');
    final email = user.email?.trim();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 28.s, vertical: 16.7.s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12.643.s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 3.s,
            spreadRadius: 0.198.s,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.main,
                  side: BorderSide(color: AppColors.main, width: 1.24.s),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.75.s),
                  ),
                  minimumSize: Size(0, 0),
                  fixedSize: Size(50.362.s, 22.068.s),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  '로그아웃',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 9.43.s,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 6.s),
              Text(
                displayName,
                style: TextStyle(
                  color: AppColors.font,
                  fontFamily: AppFonts.family,
                  fontSize: 16.s,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.s),
              Text(
                email != null && email.isNotEmpty ? 'E-mail: $email' : '',
                style: TextStyle(
                  color: AppColors.fontLight,
                  fontFamily: AppFonts.family,
                  fontSize: 12.s,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.s),
          OutlinedButton(
            onPressed: () async {
              final profileForEdit =
                  profile ??
                  (user.serverId != null
                      ? UserProfile(
                          id: user.serverId!,
                          name: '이름없음',
                          nickname: '',
                          email: user.email,
                        )
                      : null);
              if (profileForEdit == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('프로필 정보를 먼저 불러와주세요.')),
                );
                return;
              }
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) =>
                      ProfileEditPage(user: user, profile: profileForEdit),
                ),
              );
              if (updated == true && context.mounted) {
                onProfileUpdated();
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.main,
              side: BorderSide(color: AppColors.main, width: 1.24.s),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.75.s),
              ),
              minimumSize: Size(0, 0),
              padding: EdgeInsets.symmetric(vertical: 8.s),
            ),
            child: Text(
              '프로필 수정',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 12.644.s,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final VoidCallback onPetFamilySettingsTap;

  const _MenuSection({required this.onPetFamilySettingsTap});
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final List<_MenuItem> items = [
      _MenuItem(
        title: '반려가족 설정',
        hasArrow: true,
        onTap: onPetFamilySettingsTap,
      ),
      _MenuItem(
        title: '문의하기',
        hasArrow: true,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const InquiryPage()));
        },
      ),
      _MenuItem(
        title: '알림 및 수신 동의',
        hasArrow: true,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NotificationPage()),
          );
        },
      ),
      _MenuItem(
        title: '이용약관 및 개인정보 처리방침',
        hasArrow: true,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const TermsPage()));
        },
      ),
      const _MenuItem(title: '앱 버전 관리', hasArrow: false, trailing: '1.0'),
      _MenuItem(
        title: '회원탈퇴',
        hasArrow: true,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MemberWithdrawalPage(),
            ),
          );
        },
      ),
    ];

    return Column(
      children: List.generate(items.length * 2 - 1, (index) {
        if (index.isOdd) {
          return SizedBox(height: 15.s);
        }
        final item = items[index ~/ 2];
        return _MenuTile(item: item);
      }),
    );
  }
}

class _MenuItem {
  final String title;
  final bool hasArrow;
  final String? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.title,
    required this.hasArrow,
    this.trailing,
    this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12.644.s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 3.s,
            spreadRadius: 0.198.s,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.644.s),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12.644.s),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.s, vertical: 16.s),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: AppColors.font,
                      fontFamily: AppFonts.family,
                      fontSize: 15.8.s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (item.trailing != null)
                  Text(
                    item.trailing!,
                    style: TextStyle(
                      color: AppColors.font,
                      fontFamily: AppFonts.family,
                      fontSize: 14.45.s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (item.hasArrow) ...[
                  if (item.trailing != null) SizedBox(width: 8.s),
                  Image.asset(
                    'assets/icons/next-icon.webp',
                    width: 8.s,
                    height: 14.s,
                    fit: BoxFit.contain,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
