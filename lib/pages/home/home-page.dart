/// 홈 화면(UI) 파일입니다.
///
/// - 데이터: HomeBloc (ProfileCard, 갱신). 화면 전환은 HomeNavigator(Navigator) 사용.
/// - UI는 그대로 유지.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app-size.dart';
import '../../core/widgets/common-app-bar.dart';
import '../../core/widgets/open-my-page-from-app-bar.dart';
import '../../features/home/bloc/home-bloc.dart';
import '../../features/home/bloc/home-event.dart';
import '../../features/home/bloc/home-state.dart';
import '../pet-family-settings/pet-family-settings-page.dart';
import 'widgets/ad-banner.dart';
import 'widgets/feature-cards.dart';
import 'widgets/home-root-back-handler.dart';
import 'widgets/magazine-section.dart';
import 'widgets/pet-record-section.dart';
import 'widgets/profile-card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return HomeRootBackHandler(
          child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: CommonAppBar(
            onNotificationPressed: null,
            onMyPagePressed: () => openMyPageFromAppBar(context),
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 1.s),
                        ProfileCard(
                          user: state.user,
                          pet: state.selectedPet,
                          profiles: state.profiles,
                          selectedProfileIndex: state.selectedProfileIndex,
                          onProfilePicked: (selectedProfile) {
                            final petId = selectedProfile.petId;
                            if (petId == null) return;
                            // MainPetSelected: optimistic 업데이트 → PATCH → RefreshHome
                            context.read<HomeBloc>().add(
                              MainPetSelected(
                                petId: petId,
                                profile: selectedProfile,
                              ),
                            );
                          },
                          onProfileSelected: (index) async {
                            if (index == -1) {
                              Navigator.of(context)
                                  .push<PetFamilySettingsResult>(
                                    MaterialPageRoute<PetFamilySettingsResult>(
                                      builder: (_) => PetFamilySettingsPage(
                                        initialSelectedIndex:
                                            state.selectedProfileIndex,
                                        initialProfiles: state.profiles,
                                        startWithAddProfile: true,
                                      ),
                                    ),
                                  )
                                  .then((result) {
                                    if (result != null && context.mounted) {
                                      context.read<HomeBloc>().add(
                                        ProfilesUpdated(
                                          profiles: result.profiles,
                                          selectedIndex: result.selectedIndex,
                                        ),
                                      );
                                    }
                                  });
                              return;
                            }
                            if (index >= 0 && index < state.profiles.length) {
                              context.read<HomeBloc>().add(
                                ProfileSelected(index),
                              );
                              return;
                            }
                          },
                        ),
                        SizedBox(height: 14.s),
                        FeatureCards(user: state.user),
                        SizedBox(height: 13.s),
                        AdBanner(
                          imageUrls: state.adBannerUrls,
                          isLoading: state.isAdBannerLoading,
                        ),
                        SizedBox(height: 13.s),
                        const PetRecordSection(),
                        SizedBox(height: 15.s),
                        MagazineSection(imageUrls: state.magazineUrls),
                        SizedBox(height: 35.s),
                      ],
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }
}
