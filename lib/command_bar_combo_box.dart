import 'package:fluent_ui/fluent_ui.dart';

class CommandBarComboBox<T> extends CommandBarItem {
  CommandBarComboBox({
    super.key,
    required this.icon,
    required this.label,
    required this.items,
    required this.onChanged,
    this.selectedIndex = 0,
  }) {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
      throw ArgumentError(
        'Value is not in the range [0..${items.length - 1}]',
        'selectedIndex',
      );
    }
  }

  final IconData icon;
  final String label;
  final List<ComboBoxItem<T>> items;
  final ValueChanged<T?> onChanged;
  final int selectedIndex;

  @override
  Widget build(BuildContext context, CommandBarItemDisplayMode displayMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.0),
        const SizedBox(width: 10.0),
        if (displayMode == CommandBarItemDisplayMode.inPrimary) ...[
          Text(label),
          const SizedBox(width: 10.0),
        ],
        _SelfUpdatingComboBox<T>(
          items: items,
          value: items[selectedIndex].value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SelfUpdatingComboBox<T> extends StatefulWidget {
  const _SelfUpdatingComboBox({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<ComboBoxItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;

  @override
  State<StatefulWidget> createState() => _SelfUpdatingComboBoxState<T>();
}

class _SelfUpdatingComboBoxState<T> extends State<_SelfUpdatingComboBox<T>> {
  T? value;

  @override
  void initState() {
    super.initState();
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return ComboBox<T>(
      items: widget.items,
      value: value,
      onChanged: (value) {
        setState(() {
          this.value = value;
        });
        widget.onChanged(value);
      },
    );
  }
}
