import 'package:flutter/foundation.dart';
import 'package:logk8s/models/selected_listener.dart';


@immutable
class SelectedListeners {
  final List<SelectedListener> listners = [];

  List<SelectedListener> getSelectedListeners() {
    return listners;
  }

  List<SelectedListener> addSelectedListener(SelectedListener listener) {
    listners.add(listener);
    return listners;
  }

  List<SelectedListener> removeSelectedListener(SelectedListener listener) {
    listners.remove(listener);
    return listners;
  }
}
