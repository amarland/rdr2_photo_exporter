import 'package:fluent_ui/fluent_ui.dart';

import 'home_page.dart';

class App extends StatelessWidget {
  const App({super.key, required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      home: MyHomePage(paths: paths),
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
    );
  }
}
