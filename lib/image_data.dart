// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'dart:async';

// class ImageData {
//   String uri;
//   String prediction;
//   ImageData(this.uri, this.prediction);
// }

// Future<List<ImageData>> loadImages() async {
  // var data =
  //     await http.get(Uri.parse("http://5abd-49-206-5-110.ngrok.io/api/"));
  // print(data.body);
  // var jsondata = json.decode(data.body);
//   List<ImageData> list = [];
//   for (var data in jsondata) {
//     ImageData n = ImageData(data['url'], data['prediction']);
//     list.add(n);
//   }
//   return list;
// }
