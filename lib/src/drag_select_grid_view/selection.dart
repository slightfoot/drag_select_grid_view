import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../misc/utils.dart';

/// Holds and calculates selected indexes based on gestures.
///
/// This class is conceptually tied to UI gestures, so its methods have names
/// that suggest interactions (specifically tap and drag), however it just holds
/// data and makes some calculations.
///
/// This behavior is unusual, but in this situation it helps to keep everything
/// more didactic, since you can easily link the UI action to it's consequence
/// regarding selection.
class SelectionManager {
  /// The index in which the drag started.
  int get dragStartIndex => _dragStartIndex;
  var _dragStartIndex = -1;

  /// The last known index which was dragged by.
  int get dragEndIndex => _dragEndIndex;
  var _dragEndIndex = -1;

  /// Indexes that are currently selected.
  ///
  /// Indexes can be selected by dragging (with [startDrag], [updateDrag] and
  /// [endDrag]), or by tapping (with [tap]).
  Set<int> get selectedIndexes => Set.of(_selectedIndexes);
  final _selectedIndexes = <int>{};

  /// Adds the [index] to [_selectedIndexes], or removes it if it's already there.
  void tap(int index) {
    if (_selectedIndexes.contains(index)) {
      _selectedIndexes.remove(index);
    } else {
      _selectedIndexes.add(index);
    }
  }

  /// Adds the [index] to [_selectedIndexes] and allows [updateDrag] calls.
  void startDrag(int index) {
    _dragStartIndex = _dragEndIndex = index;
    _selectedIndexes.add(index);
  }

  /// Updates the [_selectedIndexes], adding/removing one or more indexes, based
  /// on [index], [dragStartIndex] and [dragEndIndex].
  ///
  /// Does nothing if:
  ///
  ///   * [index] is negative.
  ///   * Drag didn't start.
  void updateDrag(int index) {
    if (index < 0) return;
    if ((_dragStartIndex == -1) || (_dragEndIndex == -1)) return;

    // If the drag is both forward and backward, drag to the start index,
    // and then continue the drag, whether it is forward or backward.
    if ((index < dragStartIndex) && (index < dragEndIndex) ||
        (index > dragStartIndex) && (index > dragEndIndex)) {
      _updateDragForwardOrBackward(_dragStartIndex);
      _dragEndIndex = _dragStartIndex;
    }

    _updateDragForwardOrBackward(index);
    _dragEndIndex = index;
  }

  /// Finishes the current drag.
  void endDrag() {
    _dragStartIndex = -1;
    _dragEndIndex = -1;
  }

  /// Remove all indexes from [_selectedIndexes].
  void clear() => _selectedIndexes.clear();

  /// Updates the [_selectedIndexes], adding/removing one or more indexes, based
  /// on [index], [dragStartIndex] and [dragEndIndex].
  ///
  /// This cannot handle a drag that is both forward and backward (and vice
  /// versa). It's possible to do so by, while dragging, jumping from an index
  /// bigger than the start index to an index smaller that the start index.
  void _updateDragForwardOrBackward(int index) {
    final indexesDraggedBy = intSetFromRange(index, _dragEndIndex);

    void removeIndexesDraggedByExceptTheCurrent() {
      indexesDraggedBy.remove(index);
      _selectedIndexes.removeAll(indexesDraggedBy);
    }

    final isSelectingForward = index > _dragStartIndex;
    final isSelectingBackward = index < _dragStartIndex;

    if (isSelectingForward) {
      final isUnselecting = index < _dragEndIndex;
      if (isUnselecting) {
        removeIndexesDraggedByExceptTheCurrent();
      } else {
        _selectedIndexes.addAll(indexesDraggedBy);
      }
    } else if (isSelectingBackward) {
      final isUnselecting = index > _dragEndIndex;
      if (isUnselecting) {
        removeIndexesDraggedByExceptTheCurrent();
      } else {
        _selectedIndexes.addAll(indexesDraggedBy);
      }
    } else {
      removeIndexesDraggedByExceptTheCurrent();
    }
  }
}

/// Information about the grid selection.
@immutable
class Selection {
  static const empty = Selection({});

  /// Creates a new [Selection].
  const Selection(this.selectedIndexes) : assert(selectedIndexes != null);

  /// Grid indexes that are selected.
  final Set<int> selectedIndexes;

  /// Amount of selected indexes.
  int get amount => selectedIndexes.length;

  /// Whether the grid is currently in select mode.
  bool get isSelecting => amount > 0;

  @override
  String toString() => 'Selection{_selectedIndexes: $selectedIndexes}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Selection &&
          runtimeType == other.runtimeType &&
          SetEquality().equals(selectedIndexes, other.selectedIndexes);

  @override
  int get hashCode => SetEquality().hash(selectedIndexes);
}
