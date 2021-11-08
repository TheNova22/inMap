// ignore_for_file: prefer_const_constructors_in_immutables, prefer_const_constructors, sized_box_for_whitespace, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart';

import 'image_data.dart';

class ImagePredictor extends StatefulWidget {
  ImagePredictor({Key? key}) : super(key: key);

  @override
  _ImagePredictorState createState() => _ImagePredictorState();
}

class _ImagePredictorState extends State<ImagePredictor> {
  PickedFile? _image;
  bool _loading = false;

  Map<String, String> _outputs = {};
  List<List> labs = [
    ['DES', 0.5],
    ['Apex', 0.5],
    ['LHC', 0.0]
  ];
  int sorter(double a, double b) {
    if (a > b) {
      return -1;
    } else if (a == b) {
      return 0;
    } else {
      return 1;
    }
  }

  @override
  void initState() {
    super.initState();
    _loading = false;
    labs.sort((List a, List b) => sorter(a[1], b[1]));
    // loadModel().then((value) {
    //   setState(() {
    //     _loading = false;
    //   });
    // });
  }

  labelSetter() {
    for (int i = 0; i < labs.length; i++) {
      labs[i][1] = double.parse(_outputs[labs[i][0]]!);
    }
    labs.sort((List a, List b) => sorter(a[1], b[1]));
  }

//Load the Tflite model
  // loadModel() async {
  //   await Tflite.loadModel(
  //     model: "assets/inMap-mobile.tflite",
  //     labels: "assets/labels.txt",
  //   );
  // }

  // classifyImage(PickedFile? image) async {
  //   img.Image? ig = img.decodeImage(File(image!.path).readAsBytesSync());
  //   ig = img.copyRotate(ig!, -90);
  //   img.Image finalPhoto = img.copyResize(ig, width: 224, height: 224);
  //   final Directory dict = await getApplicationDocumentsDirectory();
  //   final path = dict.path;
  //   File('$path/demo.jpg').writeAsBytesSync(img.encodeJpg(finalPhoto));
  //   // var j = 0;
  //   // List<List<List<int>>> arr = [[]];
  //   // while (j < vals.length) {
  //   //   var sub = [];
  //   //   var ct = 0;
  //   //   while (ct < 224) {
  //   //     sub.add([vals[j], vals[j + 1], vals[j + 2]]);
  //   //     j += 3;
  //   //     ct += 1;
  //   //   }
  //   //   arr[0].add(sub);
  //   // }
  //   // print(Uint8List.fromList(arr[0]));
  //   // print(img.decodeImage(Image.file(path)));
  //   var output = await Tflite.runModelOnImage(
  //     path: '$path/demo.jpg',
  //     threshold: 0.0,
  //     imageMean: 0.0,
  //     imageStd: 255.0,
  //     numResults: 2,
  //   );
  //   setState(() {
  //     _loading = false;
  //     //Declare List _outputs in the class which will be used to show the classified classs name and confidence
  //     _outputs = output;
  //     print(output);
  //     labelSetter();
  //   });
  // }

  final ImagePicker _picker = ImagePicker();
  uploadImageToServer(File imageFile) async {
    print('attempting to connect to server……');
    var stream = http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    print(length);
    var uri = Uri.parse('https://inmap-py.herokuapp.com/predict');
    print("connection established.");
    var request = http.MultipartRequest("POST", uri);
    var multipartFile = http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));
    //contentType: new MediaType(‘image’, ‘png’));
    request.files.add(multipartFile);
    var response = await request.send();
    print(response.statusCode);
    if (response.statusCode == 200) {
      // final val = await loadImages();
      var data =
          await http.get(Uri.parse("https://inmap-py.herokuapp.com/predict"));
      var jsondata = json.decode(data.body);
      print(jsondata);
      setState(() {
        _outputs = Map<String, String>.from(jsondata);
        _outputs['LHC'] = '0.0';
        labelSetter();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget displayRow() {
      List<Widget> wids = [];
      print(labs);
      for (int i = 0; i < labs.length; i++) {
        int confidence = (labs[i][1] * 100).round();
        wids.add(Container(
          margin: EdgeInsets.all(10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: i == 0 ? Color(0xffffbd52).withAlpha(170) : Colors.grey[350],
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          height: 75 * math.max(labs[i][1], 0.4),
          width: 150 * math.max(labs[i][1], 0.4),
          child: _loading
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(labs[i][0],
                        style: TextStyle(
                            fontSize: 16 * math.max(labs[i][1], 0.5))),
                    Text(confidence.toString() + '%',
                        style:
                            TextStyle(fontSize: 14 * math.max(labs[i][1], 0.5)))
                  ],
                ),
        ));
      }
      Widget head = wids[0];
      wids.removeAt(0);
      return Column(
        children: [
          head,
          Container(
              width: MediaQuery.of(context).size.width / 2,
              child: GridView.count(
                  childAspectRatio: 1.5,
                  crossAxisCount: 2,
                  children: wids,
                  shrinkWrap: true))
        ],
      );
    }

    Future<void> _optiondialogbox() {
      return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    GestureDetector(
                      child: Text(
                        "Take a Picture",
                        style: TextStyle(fontSize: 16.0),
                      ),
                      onTap: openCamera,
                    ),
                    Padding(padding: EdgeInsets.all(5.0)),
                    Divider(),
                    Padding(padding: EdgeInsets.all(5.0)),
                    GestureDetector(
                      child: Text(
                        "Select from Gallery",
                        style: TextStyle(fontSize: 16.0),
                      ),
                      onTap: openGallery,
                    )
                  ],
                ),
              ),
            );
          });
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('Which Building?'),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)))),
      body: _loading
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Container(
                  margin: EdgeInsets.only(left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _image == null
                          ? Container()
                          : Container(
                              child: Image.file(File(_image!.path)),
                              decoration:
                                  BoxDecoration(border: Border.all(width: 2)),
                            ),
                      SizedBox(
                        height: 20,
                      ),
                      _outputs != null ? displayRow() : Container()
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _optiondialogbox,
        child: Icon(Icons.image),
      ),
    );
  }

  //camera method

  Future openCamera() async {
    var image = await _picker.getImage(source: ImageSource.camera);

    setState(() {
      _image = image;
      _loading = true;
    });
    uploadImageToServer(File(_image!.path));
    // classifyImage(image);
  }

  //camera method
  Future openGallery() async {
    var piture = await _picker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = piture;
      _loading = true;
    });
    uploadImageToServer(File(piture!.path));
    // classifyImage(piture);
  }
}
