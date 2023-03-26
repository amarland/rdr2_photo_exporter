import '../models/game.dart';

abstract class PhotoGridEvent {
  const PhotoGridEvent();
}

class Ready extends PhotoGridEvent {
  const Ready();
}

class FilterSelectionChanged extends PhotoGridEvent {
  const FilterSelectionChanged(this.selection);

  final Game? selection;
}

class PhotoClicked extends PhotoGridEvent {
  const PhotoClicked(this.index);

  final int index;
}

class SaveButtonClicked extends PhotoGridEvent {
  const SaveButtonClicked();
}

class DeleteButtonClicked extends PhotoGridEvent {
  const DeleteButtonClicked();
}

class DeletionConfirmationDialogDismissed extends PhotoGridEvent {
  const DeletionConfirmationDialogDismissed(this.result);

  final bool result;
}
