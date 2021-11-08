import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:in_map/image_predictor.dart';

import 'examples/debugoptionsexample.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  static const String _title = 'AR Plugin Demo';
  String tag = 'Nothing';
  stream() {
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        tag = position.latitude.toString() +
            ', ' +
            position.longitude.toString() +
            ' ' +
            position.altitude.toString();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    stream();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ArFlutterPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
        ),
        body: Column(children: [
          Text('Running on: $_platformVersion\n'),
          Text(tag),
          Expanded(
            child: ExampleList(
              key: const Key("Hello"),
            ),
          ),
        ]),
      ),
    );
  }
}

class ExampleList extends StatelessWidget {
  ExampleList({required Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final examples = [
      Example(
          'Debug Options',
          'Visualize feature points, planes and world coordinate system',
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DebugOptionsWidget(
                        key: const Key("Hello"),
                      )))),
      Example(
          'Classify Image',
          'Know which floor you are in',
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => ImagePredictor())))
    ];
    return ListView(
      children: examples
          .map((example) =>
              ExampleCard(key: const Key("Hello"), example: example))
          .toList(),
    );
  }
}

class ExampleCard extends StatelessWidget {
  ExampleCard({required Key key, required this.example}) : super(key: key);
  final Example example;

  @override
  build(BuildContext context) {
    return Card(
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          example.onTap();
        },
        child: ListTile(
          title: Text(example.name),
          subtitle: Text(example.description),
        ),
      ),
    );
  }
}

class Example {
  const Example(this.name, this.description, this.onTap);
  final String name;
  final String description;
  final Function onTap;
}
