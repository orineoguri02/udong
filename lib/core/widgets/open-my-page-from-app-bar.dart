import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/home/bloc/home-bloc.dart';
import '../../features/home/bloc/home-event.dart';
import '../../pages/my-page/my-page.dart';
import 'signup-required-dialog.dart';

/// [CommonAppBar] 마이페이지 아이콘과 동일한 동작(게스트 다이얼로그 + [MyPage] + 프로필 동기화).
void openMyPageFromAppBar(BuildContext context) {
  final state = context.read<HomeBloc>().state;
  if (state.user.id == 'guest') {
    showSignupRequiredDialog(context);
    return;
  }
  Navigator.of(context)
      .push<MyPageResult>(
        MaterialPageRoute<MyPageResult>(
          builder: (_) => MyPage(
            user: state.user,
            initialPetIndex: state.selectedProfileIndex,
            initialPetProfiles: state.profiles,
          ),
        ),
      )
      .then((result) {
        if (result != null && context.mounted) {
          context.read<HomeBloc>().add(
                ProfilesUpdated(
                  profiles: result.petProfiles,
                  selectedIndex: result.selectedPetIndex,
                ),
              );
        }
      });
}
