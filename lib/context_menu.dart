import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:selection_controls_example/src/menu_context_controller.dart';
import 'package:selection_controls_example/src/text_selection_toolbar_controller.dart';

@immutable
abstract class ContextMenu {
  final List<ContextMenuItem> actions;

  ContextMenu({@required this.actions});

  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
  );

  Widget buildContextMenu(BuildContext context);
}



@immutable
abstract class ContextMenuItemBuilder {
  Widget buildItem(BuildContext context, ContextMenuItem item);
}

// Intermediate data used for building menu items with the _getItems method.
@immutable
class ContextMenuItem {
  final ContextMenuItemBuilder builder;
  final SelectionToolbarCallback onPressed;
  final Widget title;
  final Widget _child;
  final List<ContextMenuItem> children;

  const ContextMenuItem({
    @required this.onPressed,
    @required this.title,
    this.builder,
  })  : _child = null,
        this.children = null;

  const ContextMenuItem.custom({
    @required Widget child,
  })  : _child = child,
        onPressed = null,
        builder = null,
        title = null,
        this.children = null;

  bool enabled(BuildContext context) {
    return onPressed != null || _child != null;
  }

  ContextMenuItem.sublist({this.children, this.title, this.builder})
      : onPressed = sublistCallback(children),
        _child = null;

  static sublistCallback(List<ContextMenuItem> children) {
    return (MenuContextController controller) {
      controller.push(children);
      return false;
    };
  }

  ContextMenuItem copyWith({
    Widget title,
    SelectionToolbarCallback onPressed,
    ContextMenuItemBuilder builder,
  }) {
    return ContextMenuItem(
        onPressed: onPressed ?? this.onPressed,
        title: title ?? this.title,
        builder: builder ?? this.builder);
  }

  Widget buildItem(
      BuildContext context, ContextMenuItemBuilder defaultBuilder) {
    if (_child != null) return _child;
    assert(onPressed != null);
    assert(title != null);
    final builder = this.builder ?? defaultBuilder;
    return builder.buildItem(context, this);
  }
}

@immutable
class TextSelectionContextMenuItem extends ContextMenuItem {
  final ContextMenuItemBuilder builder;

  const TextSelectionContextMenuItem.cut({this.builder})
      : copy = false,
        paste = false,
        cut = true,
        selectAll = false;

  const TextSelectionContextMenuItem.copy({this.builder})
      : copy = true,
        paste = false,
        cut = false,
        selectAll = false;

  const TextSelectionContextMenuItem.paste({this.builder})
      : copy = false,
        paste = true,
        cut = false,
        selectAll = false;

  const TextSelectionContextMenuItem.selectAll({this.builder})
      : copy = false,
        paste = false,
        cut = false,
        selectAll = true;

  final bool copy;
  final bool paste;
  final bool cut;
  final bool selectAll;

  bool enabled(BuildContext context) {
    final defaultController =
        DefaultMenuContextController.of(context).textSelectionController;
    if (cut)
      return defaultController.canCut;
    else if (copy)
      return defaultController.canCopy;
    else if (paste)
      return defaultController.canPaste;
    else if (selectAll) return defaultController.canSelectAll;
    return false;
  }

  @override
  Widget buildItem(
      BuildContext context, ContextMenuItemBuilder defaultBuilder) {
    if (_child != null) return _child;

    ContextMenuItem item;
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final defaultController =
        DefaultMenuContextController.of(context).textSelectionController;

    if (cut) {
      item = this.copyWith(
        onPressed: (_) {
          defaultController.cut();
          return true;
        },
        title: Text(localizations.cutButtonLabel),
      );
    }
    if (copy) {
      item = this.copyWith(
        onPressed: (_) {
          defaultController.copy();
          return true;
        },
        title: Text(localizations.copyButtonLabel),
      );
    }
    if (paste) {
      item = this.copyWith(
        onPressed: (_) {
          defaultController.paste();
          return true;
        },
        title: Text(localizations.pasteButtonLabel),
      );
    }
    if (selectAll) {
      item = this.copyWith(
        onPressed: (_) {
          defaultController.selectAll();
          return true;
        },
        title: Text(localizations.selectAllButtonLabel),
      );
    }

    assert(item != null);
    final builder = this.builder ?? defaultBuilder;
    return builder.buildItem(context, item);
  }
}
