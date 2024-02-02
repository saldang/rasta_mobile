import 'package:flutter/material.dart';
import 'package:rasta_mobile/model/available_model.dart';
import 'package:rasta_mobile/utils/google.dart';

class ModelSelectionWidget extends StatefulWidget {
  final Function onTap;
  final FirebaseManager firebaseManager;

  const ModelSelectionWidget(
      {super.key, required this.onTap, required this.firebaseManager});

  @override
  _ModelSelectionWidgetState createState() => _ModelSelectionWidgetState();
}

class _ModelSelectionWidgetState extends State<ModelSelectionWidget> {
  List<AvailableModel> models = [];

  String? selected;

  @override
  void initState() {
    super.initState();
    widget.firebaseManager.downloadAvailableModels((snapshot) {
      for (var element in snapshot.docs) {
        setState(() {
          models.add(AvailableModel(element.get("name"), element.get("uri"),
              element.get("image").first["downloadURL"]));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                style: BorderStyle.solid,
                width: 4.0,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              shape: BoxShape.rectangle,
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 10.0,
                  spreadRadius: 4.0,
                )
              ],
            ),
            child: Text('Choose a Model',
                style: DefaultTextStyle.of(context)
                    .style
                    .apply(fontSizeFactor: 2.0)),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.65,
            child: ListView.builder(
              itemCount: models.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    widget.onTap(models[index]);
                  },
                  child: Card(
                    elevation: 4.0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.network(models[index].image)),
                        Text(
                          models[index].name,
                          style: DefaultTextStyle.of(context)
                              .style
                              .apply(fontSizeFactor: 2.0),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ]);
  }
}
