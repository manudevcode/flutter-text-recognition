import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_text_recognition/scanner_utils.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(App());
}


class App extends StatefulWidget {
  App({Key key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReadText(),
    );
  }
}

class ReadText extends StatefulWidget {
  ReadText({Key key}) : super(key: key);

  @override
  _ReadTextState createState() => _ReadTextState();
}

class _ReadTextState extends State<ReadText> {
  CameraLensDirection _direction = CameraLensDirection.back;

  CameraController _camera;
  String _text;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  void _initializeCamera() async {
    _text = '';
    final CameraDescription description = await ScannerUtils.getCamera(_direction);
    print(description.name);
    setState(() {
      _camera = CameraController(
        description,
        ResolutionPreset.high,
      );
    });

    await _camera.initialize();
    print('inited CAMERA');
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _camera?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _camera == null
            ? Container(
                color: Theme.of(context).primaryColor,
              )
            : Container(
                height: MediaQuery.of(context).size.height,
                child: CameraPreview(_camera)
              ),
          if (_text != '')
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Hemos encontrado este texto:', style: TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.w600
                  )),
                  Text(_text, style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ))
                ],
              ),
            ),
          Positioned(
            bottom: 50,
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _text ==  ''
                  ? GestureDetector(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: IconButton(
                        onPressed: () {
                          takePicture();
                        },
                        icon: Icon(Icons.camera, size: 40, color: Colors.white,),
                      ),
                    ),
                  )
                  : Column(
                    children: <Widget>[                     
                      FlatButton(
                        color: Colors.white,
                        onPressed: (){
                          setState(() {
                            _text = '';
                          });
                        }, child: Text('TOMAR OTRA FOTO', style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ))
                      ),
                    ],
                  )
                  ],
              ),
            )
          )
        ],
      ),
    );
  }

  void takePicture() async {
    Directory tempDir = await getTemporaryDirectory();
    bool dirExists = await tempDir.exists();
    String tempPath = tempDir.path+"/"+ DateTime.now().millisecond .toString();
    await _camera.initialize();
    await _camera.takePicture(tempPath);
    
    setState(() {});

    final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    FirebaseVisionImage  preProcessImage = new FirebaseVisionImage.fromFilePath(tempPath);
      
    VisionText textRecognized = await textRecognizer.processImage(preProcessImage);
    String text = textRecognized.text;
    setState(() {
      _text = text;
    });

    // Navigator.of(context).pop(print(text));
  }
}
