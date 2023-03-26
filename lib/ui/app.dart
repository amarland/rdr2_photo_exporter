import 'package:fluent_ui/fluent_ui.dart';

import 'photo_grid.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      home: const PhotoGrid(),
      debugShowCheckedModeBanner: false,
      darkTheme: FluentThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
    );
  }
}
