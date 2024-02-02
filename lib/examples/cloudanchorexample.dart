import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:rasta_mobile/utils/google.dart';
import 'package:vector_math/vector_math_64.dart';

class CloudAnchorWidget extends StatefulWidget {
  const CloudAnchorWidget({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _CloudAnchorWidgetState();
}

class _CloudAnchorWidgetState extends State<CloudAnchorWidget> {
  // Firebase stuff
  bool _initialized = false;
  bool _error = false;
  FirebaseManager firebaseManager = FirebaseManager();
  Map<String, Map> anchorsInDownloadProgress = <String, Map>{};

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  String lastUploadedAnchor = "";

  bool readyToUpload = false;
  bool readyToDownload = true;

  @override
  void initState() {
    firebaseManager.initializeFlutterFire().then((value) => setState(() {
          _initialized = value;
          _error = !value;
        }));

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    arSessionManager!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if (_error) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Cloud Anchors'),
          ),
          body: Center(
              child: Column(
            children: [
              const Text("Firebase initialization failed"),
              ElevatedButton(
                  child: const Text("Retry"), onPressed: () => {initState()})
            ],
          )));
    }

    // Show a loader until FlutterFire is initialized
    if (!_initialized) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Cloud Anchors'),
          ),
          body: Container(
              child: const Center(
                  child: Column(children: [
            CircularProgressIndicator(),
            Text("Initializing Firebase")
          ]))));
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Anchors'),
        ),
        body: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: onRemoveEverything,
                      child: const Text("Remove Everything")),
                ]),
          ),
          Align(
            alignment: FractionalOffset.topCenter,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Visibility(
                      visible: readyToUpload,
                      child: ElevatedButton(
                          onPressed: onUploadButtonPressed,
                          child: const Text("Upload"))),
                  Visibility(
                      visible: readyToDownload,
                      child: ElevatedButton(
                          onPressed: onDownloadButtonPressed,
                          child: const Text("Download"))),
                ]),
          )
        ]));
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;
    this.arLocationManager = arLocationManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          customPlaneTexturePath: "Images/triangle.png",
          showWorldOrigin: true,
        );
    this.arObjectManager!.onInitialize();
    this.arAnchorManager!.initGoogleCloudAnchorMode();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onNodeTap = onNodeTapped;
    this.arAnchorManager!.onAnchorUploaded = onAnchorUploaded;
    this.arAnchorManager!.onAnchorDownloaded = onAnchorDownloaded;

    this
        .arLocationManager!
        .startLocationUpdates()
        .then((value) => null)
        .onError((error, stackTrace) {
      switch (error.toString()) {
        case 'Location services disabled':
          {
            showAlertDialog(
                context,
                "Action Required",
                "To use cloud anchor functionality, please enable your location services",
                "Settings",
                this.arLocationManager!.openLocationServicesSettings,
                "Cancel");
            break;
          }

        case 'Location permissions denied':
          {
            showAlertDialog(
                context,
                "Action Required",
                "To use cloud anchor functionality, please allow the app to access your device's location",
                "Retry",
                this.arLocationManager!.startLocationUpdates,
                "Cancel");
            break;
          }

        case 'Location permissions permanently denied':
          {
            showAlertDialog(
                context,
                "Action Required",
                "To use cloud anchor functionality, please allow the app to access your device's location",
                "Settings",
                this.arLocationManager!.openAppPermissionSettings,
                "Cancel");
            break;
          }

        default:
          {
            this.arSessionManager!.onError(error.toString());
            break;
          }
      }
      this.arSessionManager!.onError(error.toString());
    });
  }

  Future<void> onRemoveEverything() async {
    for (var anchor in anchors) {
      arAnchorManager!.removeAnchor(anchor);
    }
    anchors = [];
    if (lastUploadedAnchor != "") {
      setState(() {
        readyToDownload = true;
        readyToUpload = false;
      });
    } else {
      setState(() {
        readyToDownload = true;
        readyToUpload = false;
      });
    }
  }

  Future<void> onNodeTapped(List<String> nodeNames) async {
    var foregroundNode =
        nodes.firstWhere((element) => element.name == nodeNames.first);
    arSessionManager!.onError(foregroundNode.data!["onTapText"]);
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);
    var newAnchor = ARPlaneAnchor(
        transformation: singleHitTestResult.worldTransform, ttl: 2);
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);
    if (didAddAnchor ?? false) {
      anchors.add(newAnchor);
      // Add note to anchor
      var newNode = ARNode(
          type: NodeType.webGLB,
          uri:
              "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb",
          scale: Vector3(0.2, 0.2, 0.2),
          position: Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
          data: {"onTapText": "Ouch, that hurt!"});
      bool? didAddNodeToAnchor =
          await arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
      if (didAddNodeToAnchor ?? false) {
        nodes.add(newNode);
        setState(() {
          readyToUpload = true;
        });
      } else {
        arSessionManager!.onError("Adding Node to Anchor failed");
      }
    } else {
      arSessionManager!.onError("Adding Anchor failed");
    }
  }

  Future<void> onUploadButtonPressed() async {
    arAnchorManager!.uploadAnchor(anchors.last);
    setState(() {
      readyToUpload = false;
    });
  }

  onAnchorUploaded(ARAnchor anchor) {
    // Upload anchor information to firebase
    firebaseManager.uploadAnchor(anchor,
        currentLocation: arLocationManager!.currentLocation);
    // Upload child nodes to firebase
    if (anchor is ARPlaneAnchor) {
      for (var nodeName in anchor.childNodes) {
        firebaseManager.uploadObject(
            nodes.firstWhere((element) => element.name == nodeName));
      }
    }
    setState(() {
      readyToDownload = true;
      readyToUpload = false;
    });
    arSessionManager!.onError("Upload successful");
  }

  ARAnchor onAnchorDownloaded(Map<String, dynamic> serializedAnchor) {
    final anchor = ARPlaneAnchor.fromJson(
        anchorsInDownloadProgress[serializedAnchor["cloudanchorid"]]
            as Map<String, dynamic>);
    anchorsInDownloadProgress.remove(anchor.cloudanchorid);
    anchors.add(anchor);

    // Download nodes attached to this anchor
    firebaseManager.getObjectsFromAnchor(anchor, (snapshot) {
      for (var objectDoc in snapshot.docs) {
        ARNode object =
            ARNode.fromMap(objectDoc.data() as Map<String, dynamic>);
        arObjectManager!.addNode(object, planeAnchor: anchor);
        nodes.add(object);
      }
    });

    return anchor;
  }

  Future<void> onDownloadButtonPressed() async {
    //this.arAnchorManager.downloadAnchor(lastUploadedAnchor);
    //firebaseManager.downloadLatestAnchor((snapshot) {
    //  final cloudAnchorId = snapshot.docs.first.get("cloudanchorid");
    //  anchorsInDownloadProgress[cloudAnchorId] = snapshot.docs.first.data();
    //  arAnchorManager.downloadAnchor(cloudAnchorId);
    //});

    // Get anchors within a radius of 100m of the current device's location
    firebaseManager.downloadAnchorsByLocation((snapshot) {
      final cloudAnchorId = snapshot.get("cloudanchorid");
      anchorsInDownloadProgress[cloudAnchorId] =
          snapshot.data() as Map<String, dynamic>;
      arAnchorManager!.downloadAnchor(cloudAnchorId);
    }, arLocationManager!.currentLocation, 0.1);
    setState(() {
      readyToDownload = false;
    });
  }

  void showAlertDialog(BuildContext context, String title, String content,
      String buttonText, Function buttonFunction, String cancelButtonText) {
    // set up the buttons
    Widget cancelButton = ElevatedButton(
      child: Text(cancelButtonText),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget actionButton = ElevatedButton(
      child: Text(buttonText),
      onPressed: () {
        buttonFunction();
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        cancelButton,
        actionButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
