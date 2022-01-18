import 'package:flutter/foundation.dart';

@immutable
class SelectedListener {
  const SelectedListener({
    required this.namespace,
    required this.pod,
    required this.container,
  });

  final String namespace;
  final String pod;
  final String container;

  SelectedListener.fromJson(Map<String, dynamic> json)
      : namespace = json['namespace'],
        pod = json['pod'],
        container = json['container'];

  Map<String, dynamic> toJson() => {
        'namespace': namespace,
        'pod': pod,
        'container': container,
      };

  bool equals(SelectedListener listener) {
    if (namespace == listener.namespace &&
        pod == listener.pod &&
        container == listener.container) return true;
    return false;
  }
}
