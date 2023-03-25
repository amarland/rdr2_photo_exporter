import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

import 'command_bar_combo_box.dart';
import 'filesytem_utils.dart' as fs_utils;
import 'game.dart';
import 'photo_tile.dart';

class MyHomePage extends StatefulWidget {
  final List<String> paths;

  const MyHomePage({super.key, required this.paths});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final StreamController<List<PhotoGridItem>?> _gridItemsController;

  @override
  void initState() {
    super.initState();
    _gridItemsController = StreamController(
      onListen: () async {
        await Future.delayed(const Duration(milliseconds: 500)); // WTF?
        _gridItemsController.add(await compute(_loadPhotosSync, widget.paths));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PhotoGridItem>?>(
      stream: _gridItemsController.stream,
      builder: (context, snapshot) {
        final photoGridItems = snapshot.data;
        final selectedItems = photoGridItems?.where((item) => item.enabled) ??
            const Iterable.empty();
        final selectedItemCount = selectedItems.length;
        return ScaffoldPage(
          header: CommandBarCard(
            child: CommandBar(
              primaryItems: [
                CommandBarComboBox(
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
                  onChanged: _onFilterChanged,
                ),
                const CommandBarSeparator(),
                CommandBarButton(
                  icon: Icon(
                    selectedItemCount < 2
                        ? FluentIcons.save_as
                        : FluentIcons.save_all,
                  ),
                  label: Text(selectedItemCount < 2 ? 'Save as' : 'Save all'),
                  onPressed: selectedItemCount > 0
                      ? () async => await _savePhotos(selectedItems)
                      : null,
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.delete),
                  label: const Text('Delete'),
                  onPressed: selectedItemCount > 0
                      ? () async => await _deletePhotos(
                            context: context,
                            selectedItems: selectedItems,
                          )
                      : null,
                ),
              ],
              // mainAxisAlignment: MainAxisAlignment.end,
            ),
          ),
          padding: EdgeInsets.zero,
          content: photoGridItems != null
              ? _buildGridView(photoGridItems)
              : const Center(child: ProgressRing()),
        );
      },
    );
  }

  @override
  void dispose() {
    _gridItemsController.close();
    super.dispose();
  }

  GridView _buildGridView(List<PhotoGridItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 384.0,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 16 / 9,
      ),
      itemBuilder: (_, index) {
        return PhotoTile(
          item: items[index],
          onTap: () {
            setState(() {
              final item = items[index];
              items[index] = item.copyWith(enabled: !item.enabled);
              _gridItemsController.add(items);
            });
          },
        );
      },
      itemCount: items.length,
    );
  }

  static List<PhotoGridItem> _loadPhotosSync(Iterable<String> paths) {
    return paths
        .map(fs_utils.parsePhotoFileSync)
        .map((photo) => PhotoGridItem(photo: photo))
        .toList(growable: false)
      ..sort(
        (item2, item1) {
          // descending
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

  void _onFilterChanged(dynamic game) {
    /*_gridItemsController.add(
      (game is Game ? _photos.where((photo) => photo.game == game) : _photos)
          .map((photo) => PhotoGridItem(photo: photo))
          .toList(growable: false),
    );*/
  }

  static Future<void> _savePhotos(Iterable<PhotoGridItem> selectedItems) async {
    await fs_utils.savePhotos(
      selectedItems.map((item) => item.photo),
    ); // TODO: handle result
  }

  static Future<void> _deletePhotos({
    required BuildContext context,
    required Iterable<PhotoGridItem> selectedItems,
  }) async {
    final singular = selectedItems.length == 1;
    final nounWithArticle = singular ? 'this photo' : 'these photos';
    final pronoun = singular ? 'it' : 'them';
    final proceed = await _showContentDialog(
      context: context,
      title: 'Delete $nounWithArticle?',
      message: "If you delete $pronoun, you won't be able to recover $pronoun."
          ' Do you want to delete $nounWithArticle?',
      positiveButtonText: 'Delete',
      negativeButtonText: 'Cancel',
    );
    if (proceed) {
      await fs_utils.deletePhotos(
        selectedItems.map((item) => item.photo),
      ); // TODO: handle result
    }
  }

  static Future<bool> _showContentDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String positiveButtonText,
    String? negativeButtonText,
  }) async {
    final positiveButtonClicked = await showDialog<bool>(
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
    return positiveButtonClicked ?? false;
  }
}
