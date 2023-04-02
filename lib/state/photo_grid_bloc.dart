import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rdr2_photo_exporter/models/photo.dart';

import '../filesystem/filesystem.dart';
import '../models/game.dart';
import '../models/photo_grid_item.dart';
import '../state/photo_grid_event.dart';
import '../state/photo_grid_state.dart';

// TODO: replace with Cubit?
class PhotoGridBloc extends Bloc<PhotoGridEvent, PhotoGridState> {
  PhotoGridBloc() : super(PhotoGridState.initial) {
    on<Ready>((_, emit) async {
      emit(await _onReady());
    });
    on<FilterSelectionChanged>(
      (event, emit) {
        final newState = _onFilterSelectionChanged(event.selection);
        if (newState != null) {
          emit(newState);
        }
      },
    );
    on<PhotoClicked>((event, emit) {
      emit(_onPhotoSelectionStateChanged(event.index));
    });
    on<SaveButtonClicked>((_, __) async {
      await _onSaveButtonClicked();
    });
    on<DeleteButtonClicked>((_, emit) {
      emit(_onDeleteButtonClicked());
    });
    on<DeletionConfirmationDialogDismissed>(
      (event, emit) async {
        emit(await _onDeletionConfirmationDialogDismissed(event.result));
      },
    );
  }

  Game? _currentFilter;
  List<PhotoGridItem> _allGridItems = PhotoGridState.initial.items;

  Iterable<Photo> get _selectedItems =>
      state.items.where((item) => item.selected).map((item) => item.photo);

  Future<PhotoGridState> _onReady() async {
    _allGridItems = await compute(
      _loadPhotosSync,
      await getPhotoPaths().toList(),
    );
    return state.copyWith(items: _allGridItems);
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

  PhotoGridState? _onFilterSelectionChanged(Game? selection) {
    if (selection != _currentFilter) {
      _currentFilter = selection;
      return state.copyWith(
        items: selection is Game
            ? state.items
                .where((item) => item.photo.game == selection)
                .toList(growable: false)
            : state.items,
      );
    } else {
      return null;
    }
  }

  PhotoGridState _onPhotoSelectionStateChanged(int selectedIndex) {
    return state.copyWith(
      items: List.generate(
        state.items.length,
        (index) {
          final item = state.items[index];
          return selectedIndex == index
              ? item.copyWith(selected: !item.selected)
              : item;
        },
      ),
    );
  }

  Future<void> _onSaveButtonClicked() async {
    await savePhotos(_selectedItems); // TODO: handle result
  }

  PhotoGridState _onDeleteButtonClicked() {
    return state.copyWith(deletionConfirmationDialogShown: true);
  }

  Future<PhotoGridState> _onDeletionConfirmationDialogDismissed(
    bool result,
  ) async {
    if (result) {
      await _deleteSelectedPhotos();
    }
    return state.copyWith(deletionConfirmationDialogShown: false);
  }

  Future<void> _deleteSelectedPhotos() async {
    await deletePhotos(_selectedItems); // TODO: handle result
  }
}
