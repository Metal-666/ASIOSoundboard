class TileTutorialState {
  final int revealProgress;
  final bool? showRightClick;

  TileTutorialState({
    this.revealProgress = 0,
    this.showRightClick,
  });

  TileTutorialState copyWith({
    int Function()? revealProgress,
    bool? Function()? showRightClick,
  }) =>
      TileTutorialState(
        revealProgress: revealProgress == null
            ? this.revealProgress
            : revealProgress.call(),
        showRightClick: showRightClick == null
            ? this.showRightClick
            : showRightClick.call(),
      );
}
