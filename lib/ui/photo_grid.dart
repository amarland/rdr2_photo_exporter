import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/game.dart';
import '../models/photo_grid_item.dart';
import '../state/photo_grid_bloc.dart';
import '../state/photo_grid_event.dart';
import '../state/photo_grid_state.dart';
import 'command_bar_combo_box.dart';
import 'photo_tile.dart';

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PhotoGridBloc()..add(const Ready()),
      child: BlocConsumer<PhotoGridBloc, PhotoGridState>(
        builder: (context, state) {
          final bloc = context.read<PhotoGridBloc>();
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
                      bloc.add(
                        FilterSelectionChanged(
                          selection is Game ? selection : null,
                        ),
                      );
                    },
                    enabled: state.commandBarButtonsEnabled,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.save_as),
                    label: const Text('Save as'),
                    onPressed: state.commandBarButtonsEnabled
                        ? () => bloc.add(const SaveButtonClicked())
                        : null,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.delete),
                    label: const Text('Delete'),
                    onPressed: state.commandBarButtonsEnabled
                        ? () => bloc.add(const DeleteButtonClicked())
                        : null,
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.end,
              ),
            ),
            padding: EdgeInsets.zero,
            content: state.items.isNotEmpty
                ? _buildGridView(state.items)
                : const Center(child: ProgressRing()),
          );
        },
        listener: (context, state) {
          if (state.deletionConfirmationDialogShown) {
            _showDeletionConfirmationDialog(context);
          } else {
            Navigator.pop(context);
          }
        },
        listenWhen: (oldState, newState) =>
            newState.deletionConfirmationDialogShown !=
            oldState.deletionConfirmationDialogShown,
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
          onTap: () => context.read<PhotoGridBloc>().add(PhotoClicked(index)),
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
    await showDialog<void>(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            Button(
              child: Text(positiveButtonText),
              onPressed: () => onDialogDismissed(true),
            ),
            if (negativeButtonText != null)
              Button(
                child: Text(negativeButtonText),
                onPressed: () => onDialogDismissed(false),
              ),
          ],
        );
      },
    );
  }

  // TODO: merge with `_showContentDialog`?
  static Future<void> _showDeletionConfirmationDialog(
    BuildContext context,
  ) async {
    return await _showContentDialog(
      context: context,
      title: 'Delete the selected photos?',
      message: "If you delete them, you won't be able to recover them."
          ' Are you sure you want to delete them?',
      positiveButtonText: 'Delete',
      negativeButtonText: 'Cancel',
      onDialogDismissed: (result) {
        final bloc = context.read<PhotoGridBloc>();
        return bloc.add(DeletionConfirmationDialogDismissed(result));
      },
    );
  }
}
