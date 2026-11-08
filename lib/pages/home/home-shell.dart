import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/models/user.dart';
import '../../features/home/bloc/home-bloc.dart';
import '../../features/home/bloc/home-event.dart';
import '../../features/home/bloc/home-state.dart';
import '../../features/home/repository/home-repository.dart';
import 'home-navigator.dart';

/// AuthGate 안에서만 사용. HomeBloc 제공 + Home 전용 Navigator 래핑.
class HomeShell extends StatelessWidget {
  final User user;

  const HomeShell({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(
        context.read<HomeRepository>(),
        initialState: HomeState(user: user),
      )..add(const HomeStarted()),
      child: const HomeNavigator(),
    );
  }
}
