import '../models/photo_grid_item.dart';

class PhotoGridState {
  const PhotoGridState._({
    required this.items,
    required this.deletionConfirmationDialogShown,
  });

  static const PhotoGridState initial = PhotoGridState._(
    items: null,
    deletionConfirmationDialogShown: false,
  );

  final List<PhotoGridItem>? items;
  final bool deletionConfirmationDialogShown;

  bool get filteringEnabled => items?.isNotEmpty ?? false;

  bool get actionButtonsEnabled => items?.any((item) => item.selected) ?? false;

  PhotoGridState copyWith({
    List<PhotoGridItem> Function()? items,
    bool? deletionConfirmationDialogShown,
  }) {
    return PhotoGridState._(
      items: items?.call() ?? this.items,
      deletionConfirmationDialogShown: deletionConfirmationDialogShown ??
          this.deletionConfirmationDialogShown,
    );
  }
}
