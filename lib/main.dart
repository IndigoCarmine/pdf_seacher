import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Text Extraction',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'PDF Text Extraction'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  @override
  void initState() async {
    final SharedPreferences prefs = await _prefs;
    final List<String> recentlyPath =
        prefs.getStringList('recentlySearched') ?? [];
    for (String path in recentlyPath) {
      appendRecentlySearched(path);
    }
    super.initState();
  }

  List<Widget> recentlySearched = [];
  void appendRecentlySearched(String path) {
    recentlySearched.add(ListTile(
      title: Text(path),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path),
          ),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        drawer: Drawer(
          child: Container(
            margin: const EdgeInsets.all(8),
            child: ListView(
              children: <Widget>[
                    const DrawerHeader(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                      ),
                      child: Text(
                        'recently searched',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ] +
                  recentlySearched,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  TextField(
                    autofillHints: ["input keywword"],
                  )
                ],
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final SharedPreferences prefs = await _prefs;
            final List<String> recentlyPath =
                prefs.getStringList('recentlySearched') ?? [];

            //pick directory
            String? path = await FilePicker.platform
                .getDirectoryPath(initialDirectory: recentlyPath.last);
            if (path != null) {
              //save path
              recentlyPath.add(path);
              prefs.setStringList('recentlySearched', recentlyPath);
              appendRecentlySearched(path);
            }
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ));
  }
}
