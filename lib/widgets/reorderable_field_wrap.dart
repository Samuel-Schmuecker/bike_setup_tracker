import 'package:flutter/material.dart';

typedef _FieldDrag = ({String category, String field});
typedef _Insertion = ({String anchor, bool before, Rect marker});

/// Stable field IDs keep ordering independent of labels and enabled fields.
class ReorderableFieldWrap extends StatefulWidget {
  const ReorderableFieldWrap({
    super.key,
    required this.categoryId,
    required this.children,
    required this.order,
    required this.editing,
    required this.onReorder,
    required this.dragLabel,
  });

  final String categoryId;
  final List<Widget> children;
  final List<String> order;
  final bool editing;
  final ValueChanged<List<String>> onReorder;
  final String dragLabel;

  @override
  State<ReorderableFieldWrap> createState() => _ReorderableFieldWrapState();
}

class _ReorderableFieldWrapState extends State<ReorderableFieldWrap> {
  final _layoutKey = GlobalKey();
  final Map<String, GlobalKey> _tileKeys = {};
  _Insertion? _insertion;

  String _id(Widget child) => (child.key! as ValueKey<String>).value;

  _Insertion? _locate(Offset globalPosition) {
    final layout = _layoutKey.currentContext?.findRenderObject() as RenderBox?;
    if (layout == null) return null;
    final point = layout.globalToLocal(globalPosition);
    _Insertion? nearest;
    var distance = double.infinity;
    for (final child in widget.children) {
      final id = _id(child);
      final box =
          _tileKeys[id]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final rect = box.localToGlobal(Offset.zero, ancestor: layout) & box.size;
      final fullRow = rect.width > layout.size.width * 0.8;
      for (final before in [true, false]) {
        final edge = fullRow
            ? (before ? rect.top - 6 : rect.bottom + 6)
            : (before ? rect.left - 6 : rect.right + 6);
        final nearestPoint = fullRow
            ? Offset(point.dx.clamp(rect.left, rect.right), edge)
            : Offset(edge, point.dy.clamp(rect.top, rect.bottom));
        final candidateDistance = (nearestPoint - point).distanceSquared;
        if (candidateDistance < distance) {
          distance = candidateDistance;
          nearest = (
            anchor: id,
            before: before,
            marker: fullRow
                ? Rect.fromLTWH(rect.left, edge - 2, rect.width, 4)
                : Rect.fromLTWH(edge - 2, rect.top, 4, rect.height),
          );
        }
      }
    }
    return nearest;
  }

  void _preview(Offset position) {
    final insertion = _locate(position);
    if (insertion != _insertion) setState(() => _insertion = insertion);
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final child in widget.children) _id(child): child};
    final ids = <String>{
      ...widget.order.where(byId.containsKey),
      ...byId.keys,
    }.toList();
    if (!widget.editing) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: ids.map((id) => byId[id]!).toList(),
      );
    }
    return DragTarget<_FieldDrag>(
      hitTestBehavior: HitTestBehavior.opaque,
      onWillAcceptWithDetails: (details) {
        if (details.data.category != widget.categoryId) return false;
        _preview(details.offset);
        return true;
      },
      onMove: (details) {
        if (details.data.category == widget.categoryId) {
          _preview(details.offset);
        }
      },
      onLeave: (_) => setState(() => _insertion = null),
      onAcceptWithDetails: (details) {
        final insertion = _locate(details.offset);
        setState(() => _insertion = null);
        if (insertion == null || insertion.anchor == details.data.field) return;
        // Resolve the anchor after removal, preserving disabled field IDs.
        final updated = <String>{...widget.order, ...ids}.toList()
          ..remove(details.data.field);
        final index = updated.indexOf(insertion.anchor);
        updated.insert(index + (insertion.before ? 0 : 1), details.data.field);
        widget.onReorder(updated);
      },
      builder: (context, candidates, rejected) => Stack(
        key: _layoutKey,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ids.map((id) {
                final child = byId[id]!;
                final tile = Stack(
                  children: [
                    IgnorePointer(child: child),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Tooltip(
                        message: widget.dragLabel,
                        child: Icon(
                          Icons.drag_indicator,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                );
                return SizedBox(
                  key: _tileKeys.putIfAbsent(id, GlobalKey.new),
                  child: LongPressDraggable<_FieldDrag>(
                    data: (category: widget.categoryId, field: id),
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    delay: const Duration(milliseconds: 150),
                    maxSimultaneousDrags: 1,
                    onDragEnd: (_) {
                      if (mounted) setState(() => _insertion = null);
                    },
                    onDragUpdate: (details) {
                      final position = Scrollable.maybeOf(context)?.position;
                      if (position == null) return;
                      final height = MediaQuery.sizeOf(context).height;
                      final y = details.globalPosition.dy;
                      final delta = y < 140
                          ? -12.0
                          : (y > height - 100 ? 12.0 : 0.0);
                      if (delta != 0) {
                        position.jumpTo(
                          (position.pixels + delta).clamp(
                            position.minScrollExtent,
                            position.maxScrollExtent,
                          ),
                        );
                      }
                    },
                    feedback: FractionalTranslation(
                      translation: const Offset(-0.5, -1.1),
                      child: Material(
                        color: Colors.transparent,
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: child is SizedBox
                              ? child.width
                              : child is Container
                              ? child.constraints?.maxWidth
                              : 85,
                          child: tile,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: 0.25, child: tile),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: tile,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_insertion case final insertion?)
            Positioned.fromRect(
              rect: insertion.marker,
              child: IgnorePointer(
                child: DecoratedBox(
                  key: ValueKey('insertion-${widget.categoryId}'),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
