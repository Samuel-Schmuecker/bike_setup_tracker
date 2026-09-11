import 'package:flutter/material.dart';

/// Animate wrap layout changes without forcing equal-sized field cards.
class _AnimatedFieldPosition extends StatefulWidget {
  const _AnimatedFieldPosition({
    super.key,
    required this.orderVersion,
    required this.animate,
    required this.child,
  });

  final int orderVersion;
  final bool animate;
  final Widget child;

  @override
  State<_AnimatedFieldPosition> createState() => _AnimatedFieldPositionState();
}

class _AnimatedFieldPositionState extends State<_AnimatedFieldPosition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1,
  );
  Offset _from = Offset.zero;

  Offset get _offset => Offset.lerp(
    _from,
    Offset.zero,
    Curves.easeInOut.transform(_controller.value),
  )!;

  @override
  void didUpdateWidget(_AnimatedFieldPosition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate || oldWidget.orderVersion == widget.orderVersion) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final previous = box.localToGlobal(Offset.zero) + _offset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.animate) return;
      final box = context.findRenderObject() as RenderBox;
      _from = previous - box.localToGlobal(Offset.zero);
      _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) =>
        Transform.translate(offset: _offset, child: child),
    child: widget.child,
  );
}

typedef _FieldDrag = ({String category, String field});
typedef _Insertion = ({String anchor, bool before});

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
  List<String>? _previewOrder;
  String? _draggingField;

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
        final candidateDistance =
            (nearestPoint - point).distanceSquared -
            (rect.contains(point) ? 0.01 : 0);
        if (candidateDistance < distance) {
          distance = candidateDistance;
          nearest = (anchor: id, before: before);
        }
      }
    }
    return nearest;
  }

  void _preview(Offset position, String field) {
    final layout = _layoutKey.currentContext?.findRenderObject() as RenderBox?;
    final slot =
        _tileKeys[field]?.currentContext?.findRenderObject() as RenderBox?;
    if (layout == null) return;
    // Keep the preview stable while the pointer remains in its new slot.
    if (_previewOrder != null && slot != null) {
      final rect =
          slot.localToGlobal(Offset.zero, ancestor: layout) & slot.size;
      if (rect.inflate(6).contains(layout.globalToLocal(position))) return;
    }
    final insertion = _locate(position);
    if (insertion == null || insertion.anchor == field) return;
    final updated = <String>{
      ...(_previewOrder ?? widget.order),
      for (final child in widget.children) _id(child),
    }.toList()..remove(field);
    final index = updated.indexOf(insertion.anchor);
    updated.insert(index + (insertion.before ? 0 : 1), field);
    setState(() => _previewOrder = updated);
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final child in widget.children) _id(child): child};
    final ids = <String>{
      ...(_previewOrder ?? widget.order).where(byId.containsKey),
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
        _preview(details.offset, details.data.field);
        return true;
      },
      onMove: (details) {
        if (details.data.category == widget.categoryId) {
          _preview(details.offset, details.data.field);
        }
      },
      onLeave: (_) => setState(() => _previewOrder = null),
      onAcceptWithDetails: (details) {
        final updated = _previewOrder;
        if (updated != null) widget.onReorder(List.of(updated));
        setState(() => _previewOrder = null);
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
                return _AnimatedFieldPosition(
                  key: _tileKeys.putIfAbsent(id, GlobalKey.new),
                  orderVersion: Object.hashAll(ids),
                  animate: id != _draggingField,
                  child: LongPressDraggable<_FieldDrag>(
                    data: (category: widget.categoryId, field: id),
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    delay: const Duration(milliseconds: 150),
                    maxSimultaneousDrags: 1,
                    onDragStarted: () => setState(() => _draggingField = id),
                    onDragEnd: (_) {
                      if (mounted) {
                        setState(() {
                          _previewOrder = null;
                          _draggingField = null;
                        });
                      }
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
                      translation: const Offset(-0.5, -0.5),
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
                    childWhenDragging: Opacity(opacity: 0, child: tile),
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
        ],
      ),
    );
  }
}
