import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rdr2_photo_exporter/models/photo.dart';

import '../filesystem/filesystem.dart';
import '../models/game.dart';
import '../models/photo_grid_item.dart';
import '../state/photo_grid_event.dart';
import '../state/photo_grid_state.dart';

typedef _StateEmitter = Emitter<PhotoGridState>;

class PhotoGridBloc extends Bloc<PhotoGridEvent, PhotoGridState> {
  PhotoGridBloc() : super(PhotoGridState.initial) {
    on<Ready>((_, emit) async => await _loadPhotos(emit));
    on<FilterSelectionChanged>(
      (event, emit) => _onFilterChanged(event.selection, emit),
    );
    on<PhotoClicked>(
        (event, emit) => _onPhotoSelectionStateChanged(event.index, emit));
    on<SaveButtonClicked>((_, __) async => await _saveSelectedPhotos());
    on<DeleteButtonClicked>((_, emit) => _showDeletionConfirmationDialog(emit));
    on<DeletionConfirmationDialogDismissed>(
      (event, emit) => _onConfirmationDialogDismissed(event.result, emit),
    );
  }

  Game? _currentFilter;
  List<PhotoGridItem> _allGridItems = PhotoGridState.initial.items;

  Iterable<Photo> get _selectedItems =>
      state.items.where((item) => item.selected).map((item) => item.photo);

  Future<void> _loadPhotos(_StateEmitter emit) async {
    _allGridItems = await compute(
      _loadPhotosSync,
      await getPhotoPaths().toList(),
    );
    emit(state.copyWith(items: _allGridItems));
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

  void _onFilterChanged(Game? selection, _StateEmitter emit) {
    if (selection != _currentFilter) {
      _currentFilter = selection;
      emit(
        state.copyWith(
          items: selection is Game
              ? state.items
                  .where((item) => item.photo.game == selection)
                  .toList(growable: false)
              : state.items,
        ),
      );
    }
  }

  void _onPhotoSelectionStateChanged(int selectedIndex, _StateEmitter emit) {
    emit(
      state.copyWith(
        items: List.generate(
          state.items.length,
          (index) {
            final item = state.items[index];
            return selectedIndex == index
                ? item.copyWith(selected: !item.selected)
                : item;
          },
        ),
      ),
    );
  }

  Future<void> _saveSelectedPhotos() async {
    await savePhotos(_selectedItems); // TODO: handle result
  }

  void _showDeletionConfirmationDialog(_StateEmitter emit) {
    emit(state.copyWith(deletionConfirmationDialogShown: true));
  }

  Future<void> _onConfirmationDialogDismissed(
    bool result,
    _StateEmitter emit,
  ) async {
    emit(state.copyWith(deletionConfirmationDialogShown: false));
    if (result) {
      await _deleteSelectedPhotos();
    }
  }

  Future<void> _deleteSelectedPhotos() async {
    await deletePhotos(_selectedItems); // TODO: handle result
  }
}
