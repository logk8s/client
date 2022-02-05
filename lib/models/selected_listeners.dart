import 'package:flutter/foundation.dart';
import 'package:logk8s/models/selected_listener.dart';

@immutable
class SelectedListeners {
  final List<SelectedListener> listners = [];

  List<SelectedListener> getSelectedListeners() {
    return listners;
  }

  List<SelectedListener> addSelectedListener(SelectedListener listener) {
    if (!listners.contains(listener)) {
      listners.add(listener);
    }
    return listners;
  }

  List<SelectedListener> removeSelectedListener(SelectedListener listener) {
    listners.removeWhere((r) => r.equals(listener));
    return listners;
  }

  bool contains(SelectedListener listener) {
    for (SelectedListener check in listners) {
      if (check.equals(listener)) {
        return true;
      }
    }
    return false;
  }
}
