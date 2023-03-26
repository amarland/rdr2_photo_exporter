import '../models/photo_grid_item.dart';

class PhotoGridState {
  const PhotoGridState({
    required this.items,
    required this.deletionConfirmationDialogShown,
  });

  static final PhotoGridState initial = PhotoGridState(
    items: List.empty(),
    deletionConfirmationDialogShown: false,
  );

  final List<PhotoGridItem> items;
  final bool deletionConfirmationDialogShown;

  bool get commandBarButtonsEnabled => items.isNotEmpty;

  PhotoGridState copyWith({
    List<PhotoGridItem>? items,
    bool? deletionConfirmationDialogShown,
  }) {
    return PhotoGridState(
      items: items ?? this.items,
      deletionConfirmationDialogShown: deletionConfirmationDialogShown ??
          this.deletionConfirmationDialogShown,
    );
  }
}
