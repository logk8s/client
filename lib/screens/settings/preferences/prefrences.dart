import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logk8s/screens/clusters/cluster.dart';
import 'package:logk8s/services/auth.dart';

class Prefrences extends StatefulWidget {
  const Prefrences({Key? key}) : super(key: key);

  @override
  PrefrencesState createState() => PrefrencesState();
}

class PrefrencesState extends State<Prefrences> {
  final AuthService _authService = AuthService();
  bool visibleUser = false;
  bool visibleOrganization = false;
  bool visibleAccount = false;
  bool visibleUsage = false;
  bool visibleClusters = false;
  final clusterAddformKey = GlobalKey<FormState>();
  Cluster cluster = Cluster();
  List<Cluster> clusters = [];

  late bool loading;
  late String error;

  PrefrencesState() {
    loading = false;
    error = '';
    for (int i = 0; i < 10; i++) {
      Cluster newCluster = Cluster();
      newCluster.domain = 'domain' + i.toString();
      newCluster.name = 'name' + i.toString();
      newCluster.port = i + 1000;
      newCluster.secret = 'secret' + i.toString();
      clusters.add(newCluster);
    }
  }

  printState() {}

  preferencesVisabilityChanged(String visible) {
    setState(() {
      visibleUser = false;
      visibleOrganization = false;
      visibleAccount = false;
      visibleUsage = false;
      visibleClusters = false;

      switch (visible) {
        case "User":
          visibleUser = true;
          break;
        case "Organization":
          visibleOrganization = true;
          break;
        case "Account":
          visibleAccount = true;
          break;
        case "Usage":
          visibleUsage = true;
          break;
        case "Clusters":
          visibleClusters = true;
          break;
      }
    });
  }

  Widget prefrenceTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
      child: Text(title,
          style: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.brown)),
    );
  }

  Widget ipPortStr(String ip, int port) {
    return RichText(
      text: TextSpan(
        text: ip,
        style: const TextStyle(color: Colors.brown),
        children: <TextSpan>[
          const TextSpan(
            text: ':',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: port.toString(),
            style: const TextStyle(color: Colors.brown),
          ),
        ],
      ),
    );
  }

  _crudClusterList() => Expanded(
        child: Card(
          margin: const EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: Scrollbar(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                return Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(
                        Icons.dns_rounded,
                        color: Colors.brown,
                        size: 40.0,
                      ),
                      title: Text(
                        clusters[index].name,
                        style: const TextStyle(
                            color: Colors.brown, fontWeight: FontWeight.bold
                          ),
                      ),
                      subtitle: ipPortStr(
                          clusters[index].domain, clusters[index].port),
                      trailing:
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 20.0,
                                color: Colors.brown[900],
                              ),
                              onPressed: () {
                                debugPrint('index:' + index.toString());
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20.0,
                                color: Colors.brown[900],
                              ),
                              onPressed: () {
                                debugPrint('index:' + index.toString());

                                //   _onDeleteItemPressed(index);
                              },
                            ),
                          ],
                        ),
                      onTap: () {
                        debugPrint('ontap');
                      },
                    ),
                    const Divider(
                      height: 5.0,
                    )
                  ],
                );
              },
              itemCount: clusters.length,
            ),
          ),
        ),
      );

  _addClusterForm() => Container(
        color: Colors.brown[50],
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        child: Form(
          key: clusterAddformKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Cluster Name'),
                validator: (val) => val!.isEmpty
                    ? 'Name can not be empty'
                    : val.length < 3
                        ? 'Name should be at least 3 charecters long'
                        : null,
                onSaved: (val) => setState(() => cluster.name = val!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'IP/Domain'),
                validator: (val) => val!.isEmpty
                    ? 'IP/Domain can not be empty'
                    : val.length < 3
                        ? 'IP/Domain should be at least 3 charecters long'
                        : null,
                onSaved: (val) => setState(() => cluster.domain = val!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Port'),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                validator: (val) =>
                    int.parse(val!) < 0 || int.parse(val) > 65535
                        ? 'Should be between 0 and 65535'
                        : null,
                onSaved: (val) =>
                    setState(() => cluster.port = int.parse(val!)),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Secret'),
                validator: (val) => val!.isEmpty
                    ? 'Secret can not be empty'
                    : val.length < 3
                        ? 'Secret should be at least 3 charecters long'
                        : null,
                onSaved: (val) => setState(() => cluster.secret = val!),
              ),
              Container(
                margin: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () async {
                    var form = clusterAddformKey.currentState;
                    if (form!.validate()) {
                      form.save();

                      setState(() {
                        loading = true;
                      });
                      var result = await _authService.addCluster();
                      if (result == null) {
                        setState(() {
                          error = 'Failed to register';
                          loading = false;
                        });
                      }
                      clusters.add(cluster);
                      form.reset();
                      cluster = Cluster();
                    }
                  },
                  child: const Text('Add cluster'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.brown[900], // background
                    onPrimary: Colors.white, // foreground
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget buildPrefrence(String title, List<Widget> children) {
    return Container(
        color: Colors.brown[50],
        child: Column(children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [prefrenceTitle(title)]),
          ...children
        ]));
  }

  Widget getUserPreference() {
    return buildPrefrence("User Prefrences", []);
  }

  Widget getOrganizationPreference() {
    return buildPrefrence("Organization Prefrences", []);
  }

  Widget getAccountPreference() {
    return buildPrefrence("Account Prefrences", []);
  }

  Widget getUsagePreference() {
    return buildPrefrence("Usage Prefrences", []);
  }

  Widget getClustersPreference() {
    return buildPrefrence(
        "Clusters Prefrences", [_addClusterForm(), _crudClusterList()]);
  }

  Widget getVisiblePreferences() {
    if (visibleUser) {
      return getUserPreference();
    }
    if (visibleOrganization) {
      return getOrganizationPreference();
    }
    if (visibleAccount) {
      return getAccountPreference();
    }
    if (visibleUsage) {
      return getUsagePreference();
    }
    if (visibleClusters) {
      return getClustersPreference();
    }

    return Container(
        color: Colors.brown[50],
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                iconSize: 40,
                color: Colors.brown[400],
                icon: const Icon(Icons.post_add),
                tooltip: 'Add to track logs',
                onPressed: () {},
              ),
              IconButton(
                iconSize: 40,
                color: Colors.brown[400],
                icon: const Icon(Icons.delete),
                tooltip: "Remove tracking",
                onPressed: () {},
              ),
            ]));
  }

  prefrencesMenuButton(Icon icon, String text, onPressed) {
    return Column(children: [
      IconButton(
        iconSize: 40,
        color: Colors.brown[400],
        icon: icon,
        tooltip: text,
        onPressed: onPressed,
      ),
      Text(
        text,
        style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    //final ScrollController _scrollController = ScrollController();
    return Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          title: const Text('Prefrences'),
          backgroundColor: Colors.brown[400],
          elevation: 0.0,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                onPressed: () async {
                  await _authService.signOut();
                },
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            )
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black26,
          ),
          child: Column(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              prefrencesMenuButton(
                                  const Icon(Icons.group_add), "User", () {
                                debugPrint('Display User Prefrences');
                                preferencesVisabilityChanged("User");
                              }),
                              prefrencesMenuButton(
                                  const Icon(Icons.business), "Organization",
                                  () {
                                debugPrint('Display Organization Prefrences');
                                preferencesVisabilityChanged("Organization");
                              }),
                              prefrencesMenuButton(
                                  const Icon(Icons.manage_accounts), "Account",
                                  () {
                                debugPrint('Display Account Prefrences');
                                preferencesVisabilityChanged("Account");
                              }),
                              prefrencesMenuButton(
                                  const Icon(Icons.analytics), "Usage", () {
                                debugPrint('Display Usage Prefrences');
                                preferencesVisabilityChanged("Usage");
                              }),
                              prefrencesMenuButton(
                                  const Icon(Icons.dns), "Clusters", () {
                                debugPrint('Display Clusters Prefrences');
                                preferencesVisabilityChanged("Clusters");
                              }),
                            ])
                      ],
                    ),
                  )),
              Expanded(flex: 20, child: getVisiblePreferences()),
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
          ),
        ));
  }
}

