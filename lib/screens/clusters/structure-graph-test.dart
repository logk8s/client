import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:hexagon/hexagon.dart';
import 'package:logk8s/services/structures.dart';

class StructuresViewPage extends StatefulWidget {
  static const routeName = '/graph';
  Structures structures = Structures.empty();

  @override
  _StructuresViewPageState createState() => _StructuresViewPageState();
}

class _StructuresViewPageState extends State<StructuresViewPage> {
  @override
  Widget build(BuildContext context) {
    setState(() {
      widget.structures = ModalRoute.of(context)!.settings.arguments as Structures;
    });

    return Scaffold(
        body: Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Wrap(
          children: [
            Container(
              width: 100,
              child: TextFormField(
                initialValue: builder.siblingSeparation.toString(),
                decoration:
                    const InputDecoration(labelText: "Sibling Separation"),
                onChanged: (text) {
                  builder.siblingSeparation = int.tryParse(text) ?? 100;
                  this.setState(() {});
                },
              ),
            ),
            Container(
              width: 100,
              child: TextFormField(
                initialValue: builder.levelSeparation.toString(),
                decoration:
                    const InputDecoration(labelText: "Level Separation"),
                onChanged: (text) {
                  builder.levelSeparation = int.tryParse(text) ?? 100;
                  this.setState(() {});
                },
              ),
            ),
            Container(
              width: 100,
              child: TextFormField(
                initialValue: builder.subtreeSeparation.toString(),
                decoration:
                    const InputDecoration(labelText: "Subtree separation"),
                onChanged: (text) {
                  builder.subtreeSeparation = int.tryParse(text) ?? 100;
                  this.setState(() {});
                },
              ),
            ),
            Container(
              width: 100,
              child: TextFormField(
                initialValue: builder.orientation.toString(),
                decoration: const InputDecoration(labelText: "Orientation"),
                onChanged: (text) {
                  builder.orientation = int.tryParse(text) ?? 100;
                  this.setState(() {});
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final node12 = Node.Id(r.nextInt(100));
                var edge =
                    graph.getNodeAtPosition(r.nextInt(graph.nodeCount()));
                print(edge);
                graph.addEdge(edge, node12);
                setState(() {});
              },
              child: const Text("Add"),
            )
          ],
        ),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.0001,
            maxScale: 3,
            child: GraphView(
              graph: graph,
              algorithm:
                  BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
              paint: Paint()
                ..color = Colors.green
                ..strokeWidth = 1
                ..style = PaintingStyle.stroke,
              builder: (Node node) {
                // I can decide what widget should be shown here based on the id
                var a = node.key?.value as int;
                if (a == 1) {
                  return rectangleWidget(a.toString());
                } else if (a % 2 == 0) {
                  return circleWidget(a);
                }
                return MyHexagonWidget(a);
              },
            )
          ),
        ),
      ],
    ));
  }

  Random r = Random();

  Widget MyHexagonWidget(int a) {
    return InkWell(
        onTap: () {
          print('clicked');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: HexagonWidget.flat(
              width: 100,
              color: Colors.green,
              padding: 4.0,
              child: Text('Node $a')),
        ));
  }

  Widget rectangleWidget(String a) {
    return InkWell(
      onTap: () {
        print('clicked');
      },
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.blue, spreadRadius: 1),
            ],
          ),
          child: Text('Node $a')),
    );
  }

  Widget circleWidget(int a) {
    return InkWell(
      onTap: () {
        print('clicked');
      },
      child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration:
              const BoxDecoration(shape: BoxShape.circle, color: Colors.orange),
          child: Center(
              child: Text(
            'Node $a',
            textAlign: TextAlign.center,
          ))),
    );
  }

  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    super.initState();
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node8 = Node.Id(7);
    final node7 = Node.Id(8);
    final node9 = Node.Id(9);
    final node10 = Node.Id(10);
    final node11 = Node.Id(11);
    final node12 = Node.Id(12);

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3, paint: Paint()..color = Colors.red);
    graph.addEdge(node1, node4, paint: Paint()..color = Colors.blue);
    graph.addEdge(node2, node5);
    graph.addEdge(node2, node6);
    graph.addEdge(node6, node7, paint: Paint()..color = Colors.red);
    graph.addEdge(node6, node8, paint: Paint()..color = Colors.red);
    graph.addEdge(node4, node9);
    graph.addEdge(node4, node10, paint: Paint()..color = Colors.black);
    graph.addEdge(node4, node11, paint: Paint()..color = Colors.red);
    graph.addEdge(node11, node12);

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }
}
