import 'photo.dart';

class PhotoGridItem {
  const PhotoGridItem({required this.photo, this.selected = false});

  final Photo photo;
  final bool selected;

  PhotoGridItem copyWith({required bool selected}) =>
      PhotoGridItem(photo: photo, selected: selected);
}
