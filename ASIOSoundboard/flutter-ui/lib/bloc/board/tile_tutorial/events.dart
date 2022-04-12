abstract class TileTutorialEvent {}

class TutorialOpened extends TileTutorialEvent {}

class MouseSwitchedSide extends TileTutorialEvent {
  final bool rightSide;

  MouseSwitchedSide(this.rightSide);
}
