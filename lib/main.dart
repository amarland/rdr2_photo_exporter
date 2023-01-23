import 'package:bitsdojo_window_windows/bitsdojo_window_windows.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'app.dart';
import 'filesytem_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(paths: await getPhotoPaths().toList()));
  final platform = BitsdojoWindowWindows();
  platform.doWhenWindowReady(() {
    platform.appWindow
      ..alignment = Alignment.center
      ..show();
  });
}
