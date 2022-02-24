import 'package:flutter/material.dart';
import 'package:logk8s/services/auth.dart';
import 'package:graphview/GraphView.dart';
import 'package:logk8s/services/stractures.dart';

// Widget hexWidget(String text) {
//   return InkWell(
//       onTap: () {
//         debugPrint('clicked');
//       },
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         child: HexagonWidget.flat(
//             width: 150,
//             color: Colors.green,
//             padding: 4.0,
//             child: Text(text, textAlign: TextAlign.left, overflow: TextOverflow.ellipsis,)),
//       ));
// }
Widget boxedText(String text, Color color, String type) {
  return Align(
    //alignment: const Alignment(10, 0),
    child: Tooltip(
        height: 50,
        padding: const EdgeInsets.all(8.0),
        preferBelow: false,
        // textStyle: const TextStyle(
        //   fontSize: 16,
        //   color: Colors.brown,
        // ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.amber.shade200
            // gradient:
            //     const LinearGradient(colors: <Color>[Colors.amber, Colors.red]),
            ),
        //message: type + ': ' + text,
        richMessage: TextSpan(
          text: type,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.brown[900]),
          children: <TextSpan>[
            const TextSpan(text: '  '),
            TextSpan(
                text: text,
                style: TextStyle(
                    fontWeight: FontWeight.normal, color: Colors.brown[900])),
          ],
        ),
        child: Text(text,
            textAlign: TextAlign.start, style: TextStyle(color: color))),
  );
}

Widget rectangleWidget(
    String text, Color bkgColor, Color textColor, String type) {
  return InkWell(
    onTap: () {
      debugPrint('clicked');
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: bkgColor, spreadRadius: 1),
        ],
      ),
      child: boxedText(text, textColor, type),
    ),
  );
}

Widget circleWidget(String text, Color bkgColor, Color textColor, String type) {
  return InkWell(
    hoverColor: Colors.amber,
    onTap: () {
      debugPrint('clicked');
    },
    child: Container(
        height: 100,
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(shape: BoxShape.circle, color: bkgColor),
        child: Center(child: boxedText(text, textColor, type))),
  );
}

enum NodeType { root, cluster, namespace, pod, container }

class NodeValueKey {
  final NodeType nodeType;
  final String name;

  NodeValueKey(this.nodeType, this.name);
}

class TreeNode extends NodeValueKey {
  var childrenss = {};
  Node node;

  TreeNode(NodeType nodeType, String name, this.node) : super(nodeType, name);

  add(TreeNode child) {
    childrenss[child.name] = child;
  }

  getChild(String name) {
    return childrenss[name];
  }
}

class StracturesPage extends StatefulWidget {
  const StracturesPage({Key? key}) : super(key: key);

  @override
  StracturesPageState createState() => StracturesPageState();
}

class StracturesPageState extends State<StracturesPage> {
  final AuthService _authService = AuthService();
  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  bool emptyStractures = false;

  StracturesPageState();
  @override
  void initState() {
    super.initState();

    builder
      ..siblingSeparation = (50)
      ..levelSeparation = (50)
      ..subtreeSeparation = (100)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT);
  }

  @override
  Widget build(BuildContext context) {
    Stractures stractures = Stractures.empty();

    buildGraph(Stractures stractures) {
      //final rootNode = Node.Id(NodeValueKey(NodeType.root, 'All Clusters'));
      final clusterNode =
          Node.Id(NodeValueKey(NodeType.cluster, stractures.cluster));

      var nns = stractures.namespaces.length;
      debugPrint('namespace length is $nns');

      //Namespaces
      for (var namespace in stractures.namespaces) {
        var nsNode = Node.Id(NodeValueKey(NodeType.namespace, namespace));
        graph.addEdge(clusterNode, nsNode,
            paint: Paint()..color = Colors.brown.shade700);

        //pods
        for (var pod in stractures.namespace2pods[namespace] ?? []) {
          var podNode = Node.Id(NodeValueKey(NodeType.pod, pod));
          graph.addEdge(nsNode, podNode,
              paint: Paint()..color = Colors.brown.shade800);
          //container
          for (var container in stractures.pod2containers[pod] ?? []) {
            var containerNode =
                Node.Id(NodeValueKey(NodeType.container, container));
            graph.addEdge(podNode, containerNode,
                paint: Paint()..color = Colors.brown.shade900);
          }
        }
      }
    }

    setState(() {
      stractures = ModalRoute.of(context)!.settings.arguments as Stractures;
      if (stractures.cluster == "") {
        emptyStractures = true;
      }else{
        buildGraph(stractures);
      }


    });

    return Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          title: const Text('Clusters stracture'),
          backgroundColor: Colors.brown[400],
          elevation: 0.0,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: TextButton.icon(
                onPressed: () async {
                  await _authService.signOut();
                },
                icon: const Icon(Icons.person),
                label: const Text('Logout'),
                style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
                flex: 2,
                child: Container(
                  color: Colors.brown[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            //iconSize: 36,
                            color: Colors.brown[400],
                            icon: const Icon(Icons.refresh),
                            tooltip: "Refresh Stracture",
                            onPressed: () {},
                          ),
                        ],
                      )
                    ],
                  ),
                )),
            Expanded(
              flex: 20,
              child: Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.brown[50],
                //child: const Text('Body'),
                child: InteractiveViewer(
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(100),
                    minScale: 0.0001,
                    maxScale: 1.5,
                    child: GraphView(
                      graph: graph,
                      algorithm: BuchheimWalkerAlgorithm(
                          builder, TreeEdgeRenderer(builder)),
                      paint: Paint()
                        ..color = Colors.green
                        ..strokeWidth = 1
                        ..style = PaintingStyle.stroke,
                      builder: (Node node) {
                        var nodeKey = node.key?.value as NodeValueKey;
                        if (nodeKey.nodeType == NodeType.namespace) {
                          return rectangleWidget(
                              nodeKey.name,
                              Colors.teal.shade200,
                              Colors.teal.shade900,
                              'Namespace');
                        }
                        if (nodeKey.nodeType == NodeType.pod) {
                          return circleWidget(
                              nodeKey.name,
                              Colors.brown.shade200,
                              Colors.brown.shade900,
                              'Pod');
                        }
                        if (nodeKey.nodeType == NodeType.container) {
                          return rectangleWidget(
                              nodeKey.name,
                              Colors.brown.shade100,
                              Colors.brown.shade800,
                              'Container');
                        }
                        //root elemet
                        return circleWidget(
                            nodeKey.name,
                            Colors.blueGrey.shade400,
                            Colors.blue.shade50,
                            'Cluster');
                      },
                    )),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                  color: Colors.brown[100],
                  child: Center(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [],
                  ))),
            )
          ],
        ));
  }
}
