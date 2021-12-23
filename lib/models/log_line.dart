import 'package:flutter/foundation.dart';

@immutable
class LogLine {
  const LogLine({
    //required this.viewers,
    required this.timestamp,
    required this.cluster,
    required this.namespace,
    required this.pod,
    required this.ip,
    required this.port,
    required this.line,
    required this.level,
  });

  LogLine.fromJson(Map<String, Object?> json)
      : this(
          //viewers: (json['viewers']! as List).cast<String>(),
          timestamp: json['timestamp']! as int,
          cluster: json['cluster']! as String,
          namespace: json['namespace']! as String,
          pod: json['pod']! as String,
          ip: json['ip']! as String,
          port: json['port']! as int,
          line: json['line']! as String,
          level: json['level']! as String,
        );

  final String line;
  final String level;
  final String cluster;
  final int timestamp;
  final String ip;
  final int port;
  final String pod;
  final String namespace;
  //final List<String> viewers;

  Map<String, Object?> toJson() {
    return {
      //'viewer': viewers,
      'timestamp': timestamp,
      'cluster': cluster,
      'namespace': namespace,
      'pod': pod,
      'ip': ip,
      'port': port,
      'line': line,
      'level': level,
    };
  }
}