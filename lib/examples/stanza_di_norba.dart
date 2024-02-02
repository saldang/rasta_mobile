import 'dart:io';

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' as math64;

class StanzaDiNorbaWidget extends StatefulWidget {
  const StanzaDiNorbaWidget({Key? key}) : super(key: key);

  @override
  State<StanzaDiNorbaWidget> createState() => _StanzaDiNorbaWidgetState();
}

class _StanzaDiNorbaWidgetState extends State<StanzaDiNorbaWidget> {
  ARSessionManager? arSessionManager;

  ARObjectManager? arObjectManager;

  //String localObjectReference;
  ARNode? localObjectNode;

  //String webObjectReference;
  ARNode? webObjectNode;

  ARNode? muriNode;

  ARNode? tettoNode;

  ARNode? portaNode;

  ARNode? armadioNode;

  ARNode? triclinioNode;

  HttpClient? httpClient;

  bool muri = false,
      tetto = false,
      porta = false,
      armadio = false,
      triclinio = false;

  @override
  void dispose() {
    super.dispose();
    arSessionManager!.dispose();
  }

  Future<bool> _onNodeTap(bool node, ARNode newNode) async {
    return node
        ? await arObjectManager!.removeNode(newNode)
        : await arObjectManager!.addNode(newNode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stanza di Norba'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Positioned(
            bottom: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    var newNode = ARNode(
                        type: NodeType.fileSystemAppFolderGLB,
                        uri: "muri.glb",
                        scale: math64.Vector3(0.2, 0.2, 0.2));
                    setState(() {
                      muri = !muri;
                      muri ? muriNode = newNode : null;
                    });
                    await _onNodeTap(muri, newNode) ? muriNode = newNode : null;
                  },
                  style: muri
                      ? ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        )
                      : null,
                  child: Text(
                    "Muri",
                    style: muri
                        ? const TextStyle(
                            color: Colors.white,
                          )
                        : const TextStyle(
                            color: Colors.black,
                          ),
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                ElevatedButton(
                  onPressed: () {
                    var newNode = ARNode(
                        type: NodeType.fileSystemAppFolderGLB,
                        uri: "tetto.glb",
                        scale: math64.Vector3(0.2, 0.2, 0.2));
                    setState(() {
                      tetto = !tetto;
                      _onNodeTap(tetto, newNode);
                    });
                  },
                  style: tetto
                      ? ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        )
                      : null,
                  child: Text("Tetto",
                      style: tetto
                          ? const TextStyle(
                              color: Colors.white,
                            )
                          : const TextStyle(
                              color: Colors.black,
                            )),
                ),
                const SizedBox(
                  width: 16,
                ),
                ElevatedButton(
                  onPressed: () {
                    var newNode = ARNode(
                        type: NodeType.fileSystemAppFolderGLB,
                        uri: "porta.glb",
                        scale: math64.Vector3(0.2, 0.2, 0.2));
                    setState(() {
                      porta = !porta;
                      _onNodeTap(porta, newNode);
                    });
                  },
                  style: porta
                      ? ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        )
                      : null,
                  child: Text(
                    "Porta Esterna",
                    style: porta
                        ? const TextStyle(
                            color: Colors.white,
                          )
                        : const TextStyle(
                            color: Colors.black,
                          ),
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                ElevatedButton(
                  onPressed: () {
                    var newNode = ARNode(
                        type: NodeType.fileSystemAppFolderGLB,
                        uri: "armadio.glb",
                        scale: math64.Vector3(0.2, 0.2, 0.2));
                    setState(() {
                      armadio = !armadio;
                      _onNodeTap(armadio, newNode);
                    });
                  },
                  style: armadio
                      ? ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        )
                      : null,
                  child: Text("Armadio",
                      style: armadio
                          ? const TextStyle(
                              color: Colors.white,
                            )
                          : const TextStyle(
                              color: Colors.black,
                            )),
                ),
                const SizedBox(
                  width: 16,
                ),
                ElevatedButton(
                  onPressed: () {
                    var newNode = ARNode(
                        type: NodeType.fileSystemAppFolderGLB,
                        uri: "triclinio.glb",
                        scale: math64.Vector3(0.2, 0.2, 0.2));

                    setState(() {
                      triclinio = !triclinio;
                      _onNodeTap(triclinio, newNode);
                    });
                  },
                  style: triclinio
                      ? ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        )
                      : null,
                  child: Text("Triclinio",
                      style: triclinio
                          ? const TextStyle(
                              color: Colors.white,
                            )
                          : const TextStyle(
                              color: Colors.black,
                            )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          customPlaneTexturePath: "Images/triangle.png",
          showWorldOrigin: true,
          handleTaps: false,
        );
    this.arObjectManager!.onInitialize();

    //Download model to file system
    httpClient = HttpClient();
    _downloadFile(
        "https://github.com/saldang/rasta_glb/raw/main/Stanza%20Norba_Muri.glb",
        "muri.glb");

    _downloadFile(
        "https://github.com/saldang/rasta_glb/raw/main/Stanza%20Norba_Armadio%20fuori%20stanza.glb",
        "armadio.glb");
    _downloadFile(
        "https://github.com/saldang/rasta_glb/raw/main/Stanza%20Norba_Porta%20stanza.glb",
        "porta.glb");
    _downloadFile(
        "https://github.com/saldang/rasta_glb/raw/main/Stanza%20Norba_Tetto.glb",
        "tetto.glb");
    _downloadFile(
        "https://drive.usercontent.google.com/u/0/uc?id=1mWc0bXwJcQRbXhDS51CibILSSHAx7frx&export=download",
        "triclinio.glb");
  }

  Future<File> _downloadFile(String url, String filename) async {
    var request = await httpClient!.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = File('$dir/$filename');
    await file.writeAsBytes(bytes);
    print("Downloading finished, path: " '$dir/$filename');
    return file;
  }
}
