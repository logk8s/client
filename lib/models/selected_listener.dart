import 'package:flutter/foundation.dart';

@immutable
class SelectedListener {
  const SelectedListener({
    required this.cluster,
    required this.namespace,
    required this.pod,
    required this.container,
  });

  final String cluster;
  final String namespace;
  final String pod;
  final String container;

  SelectedListener.fromJson(Map<String, dynamic> json)
      : cluster = json['cluster'],
        namespace = json['namespace'],
        pod = json['pod'],
        container = json['container'];

  Map<String, dynamic> toJson() => {
        'cluster': cluster,
        'namespace': namespace,
        'pod': pod,
        'container': container,
      };

  bool equals(SelectedListener listener) {
    if (cluster == listener.cluster &&
        namespace == listener.namespace &&
        pod == listener.pod &&
        container == listener.container) return true;
    return false;
  }
}
