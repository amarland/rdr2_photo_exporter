import '../models/photo_grid_item.dart';

class PhotoGridState {
  const PhotoGridState._({
    required this.items,
    required this.deletionConfirmationDialogShown,
  });

  static final PhotoGridState initial = PhotoGridState._(
    items: List.empty(),
    deletionConfirmationDialogShown: false,
  );

  final List<PhotoGridItem> items;
  final bool deletionConfirmationDialogShown;

  bool get filteringEnabled => items.isNotEmpty;
  bool get actionButtonsEnabled => items.any((item) => item.selected);

  PhotoGridState copyWith({
    List<PhotoGridItem>? items,
    bool? deletionConfirmationDialogShown,
  }) {
    return PhotoGridState._(
      items: items ?? this.items,
      deletionConfirmationDialogShown: deletionConfirmationDialogShown ??
          this.deletionConfirmationDialogShown,
    );
  }
}
