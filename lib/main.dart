import 'package:bitsdojo_window_windows/bitsdojo_window_windows.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
  final platform = BitsdojoWindowWindows();
  platform.doWhenWindowReady(() {
    platform.appWindow
      ..alignment = Alignment.center
      ..show();
  });
}
