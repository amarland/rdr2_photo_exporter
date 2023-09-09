import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rdr2_photo_exporter/models/photo.dart';

import '../filesystem/filesystem.dart';
import '../models/game.dart';
import '../models/photo_grid_item.dart';
import '../state/photo_grid_state.dart';

class PhotoGridCubit extends Cubit<PhotoGridState> {
  PhotoGridCubit() : super(PhotoGridState.initial);

  Game? _currentFilter;
  List<PhotoGridItem> _allGridItems = List.empty();

  Iterable<Photo> get _selectedItems =>
      state.items?.where((item) => item.selected).map((item) => item.photo) ??
      List.empty();

  Future<void> onReady() async {
    _allGridItems = await compute(
      _loadPhotosSync,
      await getPhotoPaths().toList(),
    );
    emit(state.copyWith(items: () => _allGridItems));
  }

  void onFilterSelectionChanged(Game? selection) {
    if (selection == _currentFilter) return;
    final items = _requireGridItems();
    _currentFilter = selection;
    emit(
      state.copyWith(
        items: () {
          return selection is Game
              ? items
                  .where((item) => item.photo.game == selection)
                  .toList(growable: false)
              : items;
        },
      ),
    );
  }

  void onPhotoSelectionStateChanged(int selectedIndex) {
    final items = _requireGridItems();
    emit(
      state.copyWith(
        items: () {
          return List.generate(
            items.length,
            (index) {
              final item = items[index];
              return selectedIndex == index
                  ? item.copyWith(selected: !item.selected)
                  : item;
            },
          );
        },
      ),
    );
  }

  Future<void> onSaveButtonClicked() async {
    await savePhotos(_selectedItems); // TODO: handle result
  }

  void onDeleteButtonClicked() {
    emit(state.copyWith(deletionConfirmationDialogShown: true));
  }

  Future<void> onDeletionConfirmationDialogDismissed(bool result) async {
    if (result) await _deleteSelectedPhotos();
    emit(state.copyWith(deletionConfirmationDialogShown: false));
  }

  static List<PhotoGridItem> _loadPhotosSync(Iterable<String> paths) {
    return paths
        .map(parsePhotoFileSync)
        .map((photo) => PhotoGridItem(photo: photo))
        .toList(growable: false)
      // descending
      ..sort(
        (item2, item1) {
          final date1 = item1.photo.dateTaken;
          final date2 = item2.photo.dateTaken;
          if (date1 != null && date2 != null) {
            return date1.compareTo(date2);
          } else if (date1 == null && date2 == null) {
            return 0;
          } else {
            return date1 == null ? -1 : 1;
          }
        },
      );
  }

  List<PhotoGridItem> _requireGridItems() {
    final items = state.items;
    if (items == null || items.isEmpty) {
      throw StateError('`state.items` is null or empty');
    }
    return items;
  }

  Future<void> _deleteSelectedPhotos() async {
    await deletePhotos(_selectedItems); // TODO: handle result
  }
}
