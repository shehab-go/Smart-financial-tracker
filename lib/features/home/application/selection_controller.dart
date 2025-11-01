class SelectionController {
  final Set<int> _ids = <int>{};

  Set<int> get ids => _ids;
  bool get isActive => _ids.isNotEmpty;
  int get count => _ids.length;

  bool contains(int? id) => id != null && _ids.contains(id);

  void clear() => _ids.clear();

  void toggle(int? id) {
    if (id == null) return;
    if (!_ids.remove(id)) {
      _ids.add(id);
    }
  }

  void selectAll(Iterable<int> idsToSelect) {
    _ids
      ..clear()
      ..addAll(idsToSelect);
  }

  void toggleSelectAll(Iterable<int> idsToSelect) {
    final all = idsToSelect.toSet();
    if (_ids.length == all.length && _ids.containsAll(all)) {
      _ids.clear();
    } else {
      _ids
        ..clear()
        ..addAll(all);
    }
  }
}
