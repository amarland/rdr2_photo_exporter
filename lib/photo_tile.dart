import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';

import 'photo.dart';

class PhotoTile extends StatelessWidget {
  const PhotoTile({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  static final _dateFormat = DateFormat.yMd()/*.add_jm()*/;

  final PhotoGridItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(2.0),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            _buildTopPart(),
            _buildBottomPart(context),
          ],
        ),
      ),
    );
    // ignore: prefer_function_declarations_over_variables
    final borderedContent = () {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: FluentTheme.of(context).accentColor,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        position: DecorationPosition.foreground,
        child: content,
      );
    };
    return GestureDetector(
      onTap: onTap,
      child: item.enabled ? borderedContent() : content,
    );
  }

  LayoutBuilder _buildTopPart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.ceil();
        return Image.memory(
          item.photo.imageData,
          errorBuilder: (context, _, __) {
            return const AspectRatio(aspectRatio: 16 / 9);
          },
          width: width.toDouble(),
          // filterQuality: FilterQuality.medium,
          cacheWidth: width,
        );
      },
    );
  }

  Widget _buildBottomPart(BuildContext context) {
    final photo = item.photo;
    final theme = FluentTheme.of(context);
    final typography = theme.typography;
    final dateTaken = photo.dateTaken;
    final formattedDate =
        dateTaken != null ? _dateFormat.format(dateTaken) : null;
    return Acrylic(
      tintAlpha: 0.4,
      luminosityAlpha: 0.4,
      blurAmount: 0.0,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 8.0, // compensate for the internal padding of the checkbox
          top: 4.0,
          right: 4.0,
          bottom: 4.0,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 38.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSingleLineText(
                      photo.title,
                      style: typography.bodyStrong,
                    ),
                    if (formattedDate != null) ...[
                      const SizedBox(height: 4.0),
                      _buildSingleLineText(
                        formattedDate,
                        style: typography.caption,
                      ),
                    ],
                  ],
                ),
              ),
              Checkbox(checked: item.enabled, onChanged: (_) => onTap()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleLineText(String data, {TextStyle? style}) {
    return Text(
      data,
      style: style,
      softWrap: false,
      overflow: TextOverflow.fade,
      maxLines: 1,
    );
  }
}

class PhotoGridItem {
  const PhotoGridItem({required this.photo, this.enabled = false});

  final Photo photo;
  final bool enabled;

  PhotoGridItem copyWith({required bool enabled}) =>
      PhotoGridItem(photo: photo, enabled: enabled);
}
