import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:pdf_seacher/pdf.dart';
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
      title: 'PDF Text Extractor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'PDF Text Extractor'),
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
  void initState() {
    super.initState();
    _prefs.then((SharedPreferences prefs) {
      final List<String> recentlyPath =
          (prefs.getStringList('recentlySearched') ?? []).toSet().toList();
      for (String path in recentlyPath) {
        appendRecentlySearched(path);
      }
      prefs.setStringList('recentlySearched', recentlyPath);
      setState(() {});
    });
  }

  Future loadPdfs(String path) async {
    //search all pdfs in directory
    pdfs = (await Directory(path).list(recursive: true).toList())
        .where((element) => element.path.endsWith('.pdf'))
        .map((e) => readPDF(e.path).then((value) {
              return PDF(e.toString(), value);
            }))
        .toList();

    setState(() {});
  }

  List<Widget> recentlySearched = [];
  void appendRecentlySearched(String path) {
    recentlySearched.add(ListTile(
      title: Text(path),
      onTap: () async {
        loadPdfs(path);
      },
    ));
  }

  String seachingTerm = '';
  List<Future<PDF>> pdfs = [];
  bool? allSelected = false;

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
          children: [
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  const Text("Select All"),
                  Checkbox(
                      tristate: true,
                      value: allSelected,
                      onChanged: (value) {
                        allSelected = value;
                        if (value == null) {
                          setState(() {});
                          return;
                        }
                        if (value == true) {
                          for (Future<PDF> pdf in pdfs) {
                            pdf.then((value) {
                              value.isSelected = true;
                            });
                          }
                        } else {
                          for (Future<PDF> pdf in pdfs) {
                            pdf.then((value) {
                              value.isSelected = false;
                            });
                          }
                        }
                        setState(() {});
                      }),
                  const Spacer(),
                  FilledButton(
                      child: const Text("Select All Hits"),
                      onPressed: () {
                        for (Future<PDF> pdf in pdfs) {
                          pdf.then((value) async {
                            if (await value.seachTerm(seachingTerm) > 0) {
                              value.isSelected = true;
                            } else {
                              value.isSelected = false;
                            }
                          });
                        }
                        setState(() {});
                      }),
                  const Spacer(),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      onChanged: (value) {
                        seachingTerm = value;
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Search',
                        hintText: 'Enter some terms to search',
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                      onPressed: () async {
                        final SharedPreferences prefs = await _prefs;
                        final List<String> recentlyPath =
                            prefs.getStringList('recentlySearched') ?? [];

                        //pick directory
                        String? path = await FilePicker.platform
                            .getDirectoryPath(
                                initialDirectory: recentlyPath.isEmpty
                                    ? null
                                    : recentlyPath.last);
                        if (path != null) {
                          //save path
                          recentlyPath.add(path);
                          prefs.setStringList('recentlySearched', recentlyPath);
                          appendRecentlySearched(path);

                          loadPdfs(path);
                        }
                        setState(() {});
                      },
                      child: const Text("Select Directory")),
                  const Spacer(),
                  FilledButton(
                      onPressed: () async {
                        SharedPreferences prefs = await _prefs;
                        String extractPath =
                            prefs.getString('extractPath') ?? '';
                        // if (extractPath.isEmpty) {
                        extractPath = await FilePicker.platform
                                .getDirectoryPath(
                                    dialogTitle: "Select extract directry") ??
                            '';
                        prefs.setString('extractPath', extractPath);
                        // }
                        if (seachingTerm == "") {
                          seachingTerm == Random().nextInt(1000).toString();
                        }
                        int count = 0;
                        for (var value in (await Future.wait(pdfs))) {
                          if (value.isSelected) {
                            Directory(p.join(extractPath, seachingTerm))
                                .createSync(recursive: true);
                            //file copy to new directory
                            String sourcePath =
                                value.path.split(RegExp(r"'*'"))[1];
                            File(sourcePath).copy(p.join(extractPath,
                                seachingTerm, p.basename(sourcePath)));
                            count++;
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Extracted $count files to $extractPath')));
                      },
                      child: const Text("Extract")),
                  const Spacer()
                ],
              ),
            ),
            const Divider(height: 10),
            Expanded(
              child: Builder(builder: (context) {
                if (pdfs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Click Select Directory to load pdfs in it",
                      style: TextStyle(fontSize: 40),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: pdfs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return FutureBuilder(
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const ListTile(
                            title: Text("loading"),
                            subtitle: Text("loading"),
                            leading: CircularProgressIndicator(),
                          );
                        } else if (!snapshot.hasData) {
                          return const ListTile(
                              title: Text("Error"),
                              subtitle: Text("Error"),
                              leading: Icon(Icons.error));
                        }
                        return CheckboxListTile(
                          value: snapshot.data!.isSelected,
                          onChanged: (value) {
                            setState(() {
                              snapshot.data!.isSelected = value!;
                            });
                            if (allSelected != null) {
                              allSelected = null;
                            }
                          },
                          title: Text(snapshot.data!.path),
                          subtitle: Text(
                            snapshot.data!.abstract,
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondary: FutureBuilder(
                              builder: (context, snapshot) {
                                if (snapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const CircularProgressIndicator();
                                }
                                return Column(children: [
                                  Text(
                                    snapshot.data!.toString(),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const Text("hits")
                                ]);
                              },
                              future: snapshot.data!.seachTerm(seachingTerm)),
                        );
                      },
                      future: pdfs[index],
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const Divider(height: 1);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
