import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:selection_controls_example/src/menu_context_controller.dart';
import 'dart:math' as math;

import '../../context_menu.dart';
import '../text_selection_controls.dart';

const double _kHandleSize = 22.0;

// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kToolbarWidth = 140.0;
// Padding when positioning toolbar below selection.
const double _kToolbarContentDistanceBelow = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;

const double _kToolbarDefaultWidth = 140.0;

/// Manages a copy/paste text selection toolbar.
class _CascadeContextMenu extends StatefulWidget {
  const _CascadeContextMenu({
    Key key,

    this.items = const [],
    this.backgroundColor,
    this.elevation,
    this.clipBehavior,
    this.shape,
    this.theme,
    this.width = _kToolbarDefaultWidth,
    this.controller,
  })  : assert(width != null),
        super(key: key);

  final List<ContextMenuItem> items;

  // When true, the toolbar fits above its anchor and will be positioned there.


  final double width;

  final MenuContextController controller;

  final Color backgroundColor;
  final double elevation;

  final Clip clipBehavior;
  final ShapeBorder shape;
  final ThemeData theme;

  @override
  _CascadeContextMenuState createState() => _CascadeContextMenuState();
}

class CascadeTextSelectionToolbarItemBuilder extends ContextMenuItemBuilder {
  @override
  Widget buildItem(BuildContext context, ContextMenuItem item) {
    return ButtonTheme.fromButtonThemeData(
      data: ButtonTheme.of(context).copyWith(
          height: kMinInteractiveDimension,
          minWidth: kMinInteractiveDimension,
          padding: EdgeInsets.symmetric(horizontal: 20)),
      child: FlatButton(
          onPressed: item.onPressed != null
              ? () {
                  final controller = DefaultMenuContextController.of(context);

                  final shouldHide = item.onPressed(controller);
                  if (shouldHide) controller.hide();
                }
              : null,
          padding: EdgeInsets.only(
            // These values were eyeballed to match the native text selection menu
            // on a Pixel 2 running Android 10.
            top: 9.5,
            bottom: 9.5,
            left: 20,
            right: 20,
          ),
          shape: Border.all(width: 0.0, color: Colors.transparent),
          child: item.title),
    );
  }
}

class _CascadeContextMenuState extends State<_CascadeContextMenu>
    with TickerProviderStateMixin {
  // Whether or not the overflow menu is open. When it is closed, the menu
  // items that don't overflow are shown. When it is open, only the overflowing
  // menu items are shown.
  bool _overflowOpen = false;

  // The key for _TextSelectionToolbarContainer.
  UniqueKey _containerKey = UniqueKey();

  // Close the menu and reset layout calculations, as in when the menu has
  // changed and saved values are no longer relevant. This should be called in
  // setState or another context where a rebuild is happening.
  void _reset() {
    // Change _TextSelectionToolbarContainer's key when the menu changes in
    // order to cause it to rebuild. This lets it recalculate its
    // saved width for the new set of children, and it prevents AnimatedSize
    // from animating the size change.
    _containerKey = UniqueKey();
    // If the menu items change, make sure the overflow menu is closed. This
    // prevents an empty overflow menu.
    _overflowOpen = false;
  }

  @override
  void initState() {
    widget.controller.addListener(update);
    super.initState();
  }

  update() {
    setState(() {
      _reset();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(update);

    super.dispose();
  }

  @override
  void didUpdateWidget(_CascadeContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(update);
      widget.controller.addListener(update);
    }
    if (widget.items != oldWidget.items) {
      _reset();
    }
  }

  Widget _getItem(ContextMenuItem itemData, bool isFirst, bool isLast) {
    assert(isFirst != null);
    assert(isLast != null);

    return itemData.buildItem(
        context, CascadeTextSelectionToolbarItemBuilder());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return AnimatedSize(
      alignment: Alignment.topCenter,
      vsync: this,
      // This duration was eyeballed on a Pixel 2 emulator running Android
      // API 28.
      duration: const Duration(milliseconds: 140),
      child: _TextSelectionToolbarContainer(
        key: _containerKey,
        overflowOpen: _overflowOpen,
        child: Material(
          // This value was eyeballed to match the native text selection menu on
          // a Pixel 2 running Android 10.
          borderRadius: widget.shape == null
              ? const BorderRadius.all(Radius.circular(7.0))
              : null,
          shape: widget.shape,
          clipBehavior: widget.clipBehavior ?? Clip.antiAlias,
          elevation: widget.elevation ?? 1.0,
          color: widget.backgroundColor,
          type: MaterialType.card,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              //   isAbove: widget.isAbove,
              children: <Widget>[
                if (DefaultMenuContextController.of(context).isNested)
                  for (final item
                      in DefaultMenuContextController.of(context).currentItems)
                    SizedBox(
                      width: widget.width,
                      child: _getItem(item, false, false),
                    )
                else
                  for (int i = 0; i < widget.items.length; i++)
                    SizedBox(
                      width: widget.width,
                      child: _getItem(widget.items[i], i == 0,
                          i == widget.items.length - 1),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// When the overflow menu is open, it tries to align its right edge to the right
// edge of the closed menu. This widget handles this effect by measuring and
// maintaining the width of the closed menu and aligning the child to the right.
class _TextSelectionToolbarContainer extends SingleChildRenderObjectWidget {
  const _TextSelectionToolbarContainer({
    Key key,
    @required Widget child,
    @required this.overflowOpen,
  })  : assert(child != null),
        assert(overflowOpen != null),
        super(key: key, child: child);

  final bool overflowOpen;

  @override
  _TextSelectionToolbarContainerRenderBox createRenderObject(
      BuildContext context) {
    return _TextSelectionToolbarContainerRenderBox(overflowOpen: overflowOpen);
  }

  @override
  void updateRenderObject(BuildContext context,
      _TextSelectionToolbarContainerRenderBox renderObject) {
    renderObject.overflowOpen = overflowOpen;
  }
}

class _TextSelectionToolbarContainerRenderBox extends RenderProxyBox {
  _TextSelectionToolbarContainerRenderBox({
    @required bool overflowOpen,
  })  : assert(overflowOpen != null),
        _overflowOpen = overflowOpen,
        super();

  // The width of the menu when it was closed. This is used to achieve the
  // behavior where the open menu aligns its right edge to the closed menu's
  // right edge.
  double _closedHeight;

  bool _overflowOpen;
  bool get overflowOpen => _overflowOpen;
  set overflowOpen(bool value) {
    if (value == overflowOpen) {
      return;
    }
    _overflowOpen = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child.layout(constraints.loosen(), parentUsesSize: true);

    // Save the width when the menu is closed. If the menu changes, this width
    // is invalid, so it's important that this RenderBox be recreated in that
    // case. Currently, this is achieved by providing a new key to
    // _TextSelectionToolbarContainer.
    if (!overflowOpen && _closedHeight == null) {
      _closedHeight = child.size.height;
    }

    size = constraints.constrain(Size(
      child.size.width,
      // If the open menu is wider than the closed menu, just use its own width
      // and don't worry about aligning the right edges.
      // _closedWidth is used even when the menu is closed to allow it to
      // animate its size while keeping the same right alignment.
      _closedHeight == null || child.size.height > _closedHeight
          ? child.size.height
          : _closedHeight,
    ));

    final ToolbarItemsParentData childParentData =
        child.parentData as ToolbarItemsParentData;
    childParentData.offset = Offset(
      0.0,
      size.height - child.size.height,
    );
  }

  // Paint at the offset set in the parent data.
  @override
  void paint(PaintingContext context, Offset offset) {
    final ToolbarItemsParentData childParentData =
        child.parentData as ToolbarItemsParentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  // Include the parent data offset in the hit test.
  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    // The x, y parameters have the top left of the node's box as the origin.
    final ToolbarItemsParentData childParentData =
        child.parentData as ToolbarItemsParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - childParentData.offset);
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToolbarItemsParentData) {
      child.parentData = ToolbarItemsParentData();
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final ToolbarItemsParentData childParentData =
        child.parentData as ToolbarItemsParentData;
    transform.translate(childParentData.offset.dx, childParentData.offset.dy);
    super.applyPaintTransform(child, transform);
  }
}

// Renders the menu items in the correct positions in the menu and its overflow
// submenu based on calculating which item would first overflow.
class _TextSelectionToolbarItems extends MultiChildRenderObjectWidget {
  _TextSelectionToolbarItems({
    Key key,
    @required this.isAbove,
    @required List<Widget> children,
  })  : assert(children != null),
        assert(isAbove != null),
        super(key: key, children: children);

  final bool isAbove;

  @override
  _TextSelectionToolbarItemsRenderBox createRenderObject(BuildContext context) {
    return _TextSelectionToolbarItemsRenderBox(
      isAbove: isAbove,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _TextSelectionToolbarItemsRenderBox renderObject) {
    renderObject..isAbove = isAbove;
  }

  @override
  _TextSelectionToolbarItemsElement createElement() =>
      _TextSelectionToolbarItemsElement(this);
}

class _TextSelectionToolbarItemsElement extends MultiChildRenderObjectElement {
  _TextSelectionToolbarItemsElement(
    MultiChildRenderObjectWidget widget,
  ) : super(widget);

  static bool _shouldPaint(Element child) {
    return (child.renderObject.parentData as ToolbarItemsParentData)
        .shouldPaint;
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where(_shouldPaint).forEach(visitor);
  }
}

class _TextSelectionToolbarItemsRenderBox extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ToolbarItemsParentData> {
  _TextSelectionToolbarItemsRenderBox({
    @required bool isAbove,
  })  : assert(isAbove != null),
        _isAbove = isAbove,
        super();

  // The index of the last item that doesn't overflow.
  int _lastIndexThatFits = -1;

  bool _isAbove;
  bool get isAbove => _isAbove;
  set isAbove(bool value) {
    if (value == isAbove) {
      return;
    }
    _isAbove = value;
    markNeedsLayout();
  }

  // Layout the necessary children, and figure out where the children first
  // overflow, if at all.
  void _layoutChildren() {
    // When overflow is not open, the toolbar is always a specific height.
    final BoxConstraints sizedConstraints = BoxConstraints.loose(Size(
      constraints.maxWidth,
      constraints.maxHeight,
    ));

    int i = -1;
    double height = 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      final RenderBox child = renderObjectChild as RenderBox;
      child.layout(sizedConstraints.loosen(), parentUsesSize: true);
      height += child.size.width;

      if (height > sizedConstraints.maxHeight && _lastIndexThatFits == -1) {
        _lastIndexThatFits = i - 1;
      }
    });

    // If the last child overflows, but only because of the width of the
    // overflow button, then just show it and hide the overflow button.
    final RenderBox navButton = firstChild;
    if (_lastIndexThatFits != -1 &&
        _lastIndexThatFits == childCount - 2 &&
        height - navButton.size.height <= sizedConstraints.maxHeight) {
      _lastIndexThatFits = -1;
    }
  }

  // Decide which children will be pained and set their shouldPaint, and set the
  // offset that painted children will be placed at.
  void _placeChildren() {
    int i = -1;
    Size nextSize = const Size(0.0, 0.0);
    double fitHeight = 0.0;
    final RenderBox navButton = firstChild;

    visitChildren((RenderObject renderObjectChild) {
      i++;

      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData =
          child.parentData as ToolbarItemsParentData;

      // Handle placing the navigation button after iterating all children.
      if (renderObjectChild == navButton) {
        return;
      }

      childParentData.shouldPaint = true;

      childParentData.offset = Offset(0.0, fitHeight);
      fitHeight += child.size.height;
      nextSize = Size(
        math.max(child.size.width, nextSize.width),
        fitHeight,
      );
    });

    // Place the navigation button if needed.
    final ToolbarItemsParentData navButtonParentData =
        navButton.parentData as ToolbarItemsParentData;

    navButtonParentData.shouldPaint = false;

    size = nextSize;
  }

  @override
  void performLayout() {
    _lastIndexThatFits = -1;
    if (firstChild == null) {
      performResize();
      return;
    }

    _layoutChildren();
    _placeChildren();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData =
          child.parentData as ToolbarItemsParentData;
      if (!childParentData.shouldPaint) {
        return;
      }

      context.paintChild(child, childParentData.offset + offset);
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToolbarItemsParentData) {
      child.parentData = ToolbarItemsParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    // The x, y parameters have the top left of the node's box as the origin.
    RenderBox child = lastChild;
    while (child != null) {
      final ToolbarItemsParentData childParentData =
          child.parentData as ToolbarItemsParentData;

      // Don't hit test children aren't shown.
      if (!childParentData.shouldPaint) {
        child = childParentData.previousSibling;
        continue;
      }

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
      child = childParentData.previousSibling;
    }
    return false;
  }

  // Visit only the children that should be painted.
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData =
          child.parentData as ToolbarItemsParentData;
      if (childParentData.shouldPaint) {
        visitor(renderObjectChild);
      }
    });
  }
}

/// Centers the toolbar around the given anchor, ensuring that it remains on
/// screen.
class _TextSelectionToolbarLayout extends SingleChildLayoutDelegate {
  _TextSelectionToolbarLayout(this.anchor, this.upperBounds, this.fitsRight);

  /// Anchor position of the toolbar in global coordinates.
  final Offset anchor;

  /// The upper-most valid y value for the anchor.
  final double upperBounds;

  /// Whether the closed toolbar fits above the anchor position.
  ///
  /// If the closed toolbar doesn't fit, then the menu is rendered below the
  /// anchor position. It should never happen that the toolbar extends below the
  /// padded bottom of the screen.
  ///
  /// If the closed toolbar does fit but it doesn't fit when the overflow menu
  /// is open, then the toolbar is still rendered above the anchor position. It
  /// then grows downward, overlapping the selection.
  final bool fitsRight;

  // Return the value that centers width as closely as possible to position
  // while fitting inside of min and max.
  static double _fitOn(double position, double height, double min, double max) {
    // If it overflows on the right, put it as far right as possible.
    if (position + height > max) {
      return max - height;
    }

    // Otherwise it fits while perfectly centered.
    return position;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(
      fitsRight
          ? anchor.dx
          : math.max(upperBounds, anchor.dx - childSize.width),
      _fitOn(
        anchor.dy,
        childSize.height,
        _kToolbarScreenPadding,
        size.height - _kToolbarScreenPadding,
      ),
    );
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return anchor != oldDelegate.anchor;
  }
}

class CascadeContextMenu extends ContextMenu {
  final List<ContextMenuItem> actions;

  final Color backgroundColor;
  final double elevation;

  final Clip clipBehavior;
  final ShapeBorder shape;
  final ThemeData theme;

  final double width;

  CascadeContextMenu({
    @required this.actions,
    this.backgroundColor,
    this.elevation,
    this.clipBehavior,
    this.shape,
    this.theme,
    this.width = _kToolbarDefaultWidth,
  })  : assert(actions != null),
        super(actions: actions);

  /// Builder for material-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
  ) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // The toolbar should appear below the TextField when there is not enough
    // space above the TextField to show it.

    final toolbarScreenPadding = _kToolbarScreenPadding;
    final toolbarWidth = _kToolbarWidth;
    final toolbarContentDistance = _kToolbarContentDistance;
    final toolbarContentDistanceBelow = _kToolbarContentDistanceBelow;

    final Offset startTextSelectionPoint = endpoints.first.point;
    final Offset endTextSelectionPoint = endpoints.last.point;

    final double closedToolbarWidthNeeded =
        toolbarScreenPadding + toolbarWidth + toolbarContentDistance;

    final double availableWidth = globalEditableRegion.right -
        endTextSelectionPoint.dx -
        - toolbarContentDistance -
        mediaQuery.padding.right;

    final bool fitsRight = closedToolbarWidthNeeded <= availableWidth;
    final Offset anchor = Offset(
      fitsRight
          ? globalEditableRegion.left +
              endTextSelectionPoint.dx +
              toolbarContentDistance
          : globalEditableRegion.left +
              startTextSelectionPoint.dx -
              toolbarContentDistance,
      globalEditableRegion.top + selectionMidpoint.dy,
    );

    return Stack(
      children: <Widget>[
        CustomSingleChildLayout(
          delegate: _TextSelectionToolbarLayout(
            anchor,
            toolbarScreenPadding + mediaQuery.padding.right,
            fitsRight,
          ),
          child: buildContextMenu(context),
        )
      ],
    );
  }

  @override
  Widget buildContextMenu(BuildContext context) {
    final child = _CascadeContextMenu(
      items: actions,
      width: width,
      shape: shape,
      backgroundColor: backgroundColor,
      elevation: elevation,
      clipBehavior: clipBehavior,
      controller: DefaultMenuContextController.of(context),
    );

    if (theme != null) {
      return Theme(data: theme, child: child);
    } else {
      return child;
    }
  }
}
