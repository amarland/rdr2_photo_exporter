import 'package:fluent_ui/fluent_ui.dart';
import 'package:rdr2_photo_exporter/photo.dart';

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
  final _photos = <Photo>[];
  final _gridItems = ValueNotifier<List<PhotoGridItem>?>(null);

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PhotoGridItem>?>(
      valueListenable: _gridItems,
      builder: (context, photoGridItems, _) {
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
                      ? () async => await _deletePhotos(selectedItems)
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
              _gridItems.value = items;
            });
          },
        );
      },
      itemCount: items.length,
    );
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    _photos
      ..clear()
      ..addAll(
        await Future.wait(
          widget.paths.map((path) async => await fs_utils.parsePhotoFile(path)),
        ),
      ) /* ..sort((p1, p2) => p1.dateTaken.compareTo(p2.dateTaken)) */;
    _gridItems.value = _photos
        .map((photo) => PhotoGridItem(photo: photo))
        .toList(growable: false);
  }

  void _onFilterChanged(dynamic game) {
    _gridItems.value =
        (game is Game ? _photos.where((photo) => photo.game == game) : _photos)
            .map((photo) => PhotoGridItem(photo: photo))
            .toList(growable: false);
  }

  Future<void> _savePhotos(Iterable<PhotoGridItem> selectedItems) async {
    await fs_utils.savePhotos(
      selectedItems.map((item) => item.photo),
    ); // TODO: handle result
  }

  Future<void> _deletePhotos(Iterable<PhotoGridItem> selectedItems) async {
    final singular = selectedItems.length == 1;
    final nounWithArticle = singular ? 'this photo' : 'these photos';
    final pronoun = singular ? 'it' : 'them';
    final proceed = await _showContentDialog(
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

  Future<bool> _showContentDialog({
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
