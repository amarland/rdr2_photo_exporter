import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/game.dart';
import '../models/photo_grid_item.dart';
import '../state/photo_grid_bloc.dart';
import '../state/photo_grid_state.dart';
import 'command_bar_combo_box.dart';
import 'photo_tile.dart';

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PhotoGridCubit()..onReady(),
      child: BlocConsumer<PhotoGridCubit, PhotoGridState>(
        builder: (context, state) {
          final cubit = context.read<PhotoGridCubit>();
          return ScaffoldPage(
            header: CommandBarCard(
              child: CommandBar(
                primaryItems: [
                  CommandBarComboBox<dynamic>(
                    icon: FluentIcons.filter,
                    label: 'Filter:',
                    items: [
                      const ComboBoxItem(
                        value: Game.values, // so as not to use `null`
                        child: Text('All'),
                      ),
                      const ComboBoxItem(
                        value: Game.gta5,
                        child: Text('Grand Theft Auto V'),
                      ),
                      const ComboBoxItem(
                        value: Game.rdr2,
                        child: Text('Red Dead Redemption II'),
                      ),
                    ],
                    onChanged: (selection) {
                      cubit.onFilterSelectionChanged(
                        selection is Game ? selection : null,
                      );
                    },
                    enabled: state.filteringEnabled,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.save),
                    label: const Text('Extract'),
                    onPressed: state.actionButtonsEnabled
                        ? () => cubit.onSaveButtonClicked()
                        : null,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.delete),
                    label: const Text('Delete'),
                    onPressed: state.actionButtonsEnabled
                        ? () => cubit.onDeleteButtonClicked()
                        : null,
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.end,
              ),
            ),
            padding: EdgeInsets.zero,
            content: switch (state.items) {
              null => const Center(child: ProgressRing()),
              List<PhotoGridItem> items when items.isNotEmpty =>
                _buildGridView(items),
              _ => Center(
                  child: Text(
                    'No photos were found. 😟',
                    style: FluentTheme.of(context).typography.bodyLarge,
                  ),
                ),
            },
          );
        },
        listener: (context, state) {
          if (state.deletionConfirmationDialogShown) {
            _showDeletionConfirmationDialog(context);
          }
        },
        listenWhen: (oldState, newState) =>
            newState.deletionConfirmationDialogShown &&
            !oldState.deletionConfirmationDialogShown,
      ),
    );
  }

  static GridView _buildGridView(List<PhotoGridItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 384.0,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 16 / 9,
      ),
      itemBuilder: (context, index) {
        return PhotoTile(
          item: items[index],
          onTap: () {
            context.read<PhotoGridCubit>().onPhotoSelectionStateChanged(index);
          },
        );
      },
      itemCount: items.length,
    );
  }

  static Future<void> _showContentDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String positiveButtonText,
    String? negativeButtonText,
    required void Function(bool) onDialogDismissed,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            Button(
              child: Text(positiveButtonText),
              onPressed: () => Navigator.pop(context, true),
            ),
            if (negativeButtonText != null)
              Button(
                child: Text(negativeButtonText),
                onPressed: () => Navigator.pop(context, false),
              ),
          ],
        );
      },
    );
    onDialogDismissed(result ?? false);
  }

  // TODO: merge with `_showContentDialog`?
  static Future<void> _showDeletionConfirmationDialog(
    BuildContext context,
  ) async {
    return await _showContentDialog(
      context: context,
      title: 'Delete selected photos?',
      message: "If you delete them, you won't be able to recover them."
          ' Are you sure you want to delete them?',
      positiveButtonText: 'Delete',
      negativeButtonText: 'Cancel',
      onDialogDismissed: (result) {
        context
            .read<PhotoGridCubit>()
            .onDeletionConfirmationDialogDismissed(result);
      },
    );
  }
}
