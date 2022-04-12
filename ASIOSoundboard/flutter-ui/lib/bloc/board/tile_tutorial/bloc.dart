import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'events.dart';
import 'state.dart';

class TileTutorialBloc extends Bloc<TileTutorialEvent, TileTutorialState> {
  TileTutorialBloc() : super(TileTutorialState()) {
    on<TutorialOpened>((event, emit) async {
      await Future.delayed(const Duration(
        seconds: 1,
        milliseconds: 500,
      ));
      for (int i = 1; i <= 3; i++) {
        emit(state.copyWith(
            revealProgress: () => i,
            showRightClick: () => i >= 2 ? false : null));
        await Future.delayed(const Duration(
          seconds: 2,
        ));
      }
    });
    on<MouseSwitchedSide>((event, emit) {
      if (state.revealProgress >= 2) {
        emit(state.copyWith(showRightClick: () => event.rightSide));
      }
    });
  }
}
