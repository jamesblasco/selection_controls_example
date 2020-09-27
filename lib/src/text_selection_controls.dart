import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:selection_controls_example/src/cupertino/cupertino_selection_handle.dart';
import 'package:selection_controls_example/src/selection_toolbar_controller.dart';
import 'dart:math' as math;

import 'material/material_selection_handle.dart';

@immutable
abstract class TextSelectionHandle {
  const TextSelectionHandle();

  Size getHandleSize(double textLineHeight);

  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight);

  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textHeight,
  );
}

@immutable
abstract class TextSelectionToolbar {
  final List<TextSelectionToolbarItem> items;

  TextSelectionToolbar({@required this.items});

  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
  );
}

typedef TextSelectionToolbarItemBuilder = Widget Function(
  BuildContext context,
  SelectionToolbarCallback onPressed,
  Widget title,
  bool isFirst,
  bool isLast,
);

// Intermediate data used for building menu items with the _getItems method.
@immutable
class TextSelectionToolbarItem {
  final TextSelectionToolbarItemBuilder builder;
  final Widget _child;

  const TextSelectionToolbarItem({
    @required this.onPressed,
    @required this.title,
    this.builder,
  })  : assert(title != null),
        _child = null,
        copy = false,
        paste = false,
        cut = false,
        selectAll = false;

  const TextSelectionToolbarItem.custom({
    @required Widget child,
  })  : _child = child,
        onPressed = null,
        builder = null,
        title = null,
        copy = false,
        paste = false,
        cut = false,
        selectAll = false;

  const TextSelectionToolbarItem.cut({this.builder})
      : onPressed = null,
        title = null,
        _child = null,
        copy = false,
        paste = false,
        cut = true,
        selectAll = false;

  const TextSelectionToolbarItem.copy({this.builder})
      : onPressed = null,
        title = null,
        _child = null,
        copy = true,
        paste = false,
        cut = false,
        selectAll = false;

  const TextSelectionToolbarItem.paste({this.builder})
      : onPressed = null,
        title = null,
        _child = null,
        copy = false,
        paste = true,
        cut = false,
        selectAll = false;

  const TextSelectionToolbarItem.selectAll({this.builder})
      : onPressed = null,
        title = null,
        _child = null,
        copy = false,
        paste = false,
        cut = false,
        selectAll = true;

  final SelectionToolbarCallback onPressed;
  final Widget title;

  final bool copy;
  final bool paste;
  final bool cut;
  final bool selectAll;

  bool enabled(BuildContext context) {
    final defaultController = TextSelectionToolbarController.of(context);
    if (cut)
      return defaultController.canCut;
    else if (copy)
      return defaultController.canCopy;
    else if (paste)
      return defaultController.canPaste;
    else if (selectAll)
      return defaultController.canSelectAll;
    else
      return onPressed != null || _child != null;
  }

  Widget buildItem(BuildContext context, bool isFirst, bool isLast,
      TextSelectionToolbarItemBuilder defaultBuilder) {
    if (_child != null) return _child;

    SelectionToolbarCallback onPressed = this.onPressed;
    Widget label = this.title;
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final defaultController = TextSelectionToolbarController.of(context);

    if (cut) {
      onPressed = (_) => defaultController.cut();
      label = Text(localizations.cutButtonLabel);
    }
    if (copy) {
      onPressed = (_) => defaultController.copy();
      label = Text(localizations.copyButtonLabel);
    }
    if (paste) {
      onPressed = (_) => defaultController.paste();
      label = Text(localizations.pasteButtonLabel);
    }
    if (selectAll) {
      onPressed = (_) => defaultController.selectAll();
      label = Text(localizations.selectAllButtonLabel);
    }
    assert(label != null);
    final builder = this.builder ?? defaultBuilder;
    return builder(context, onPressed, label, isFirst, isLast);
  }

  static TextSelectionToolbarItemBuilder materialBuilder =
      (BuildContext context, SelectionToolbarCallback onPressed, Widget label,
          bool isFirst, bool isLast) {
    return ButtonTheme.fromButtonThemeData(
      data: ButtonTheme.of(context).copyWith(
        height: kMinInteractiveDimension,
        minWidth: kMinInteractiveDimension,
      ),
      child: FlatButton(
        onPressed: onPressed != null
            ? () {
                final controller = TextSelectionToolbarController.of(context);
                controller.hide();
                onPressed(controller);
              }
            : null,
        padding: EdgeInsets.only(
          // These values were eyeballed to match the native text selection menu
          // on a Pixel 2 running Android 10.
          left: 9.5 + (isFirst ? 5.0 : 0.0),
          right: 9.5 + (isLast ? 5.0 : 0.0),
        ),
        shape: Border.all(width: 0.0, color: Colors.transparent),
        child: label,
      ),
    );
  };
}

class DefaultTextSelectionControls extends TextSelectionControls {
  final TextSelectionHandle handle;
  final TextSelectionToolbar toolbar;

  DefaultTextSelectionControls({
    this.toolbar,
    @required this.handle,
  }) : assert(handle != null);

  DefaultTextSelectionControls.material({
    this.toolbar,
    this.handle = const MaterialSelectionHandle(),
  }) : assert(handle != null);

  DefaultTextSelectionControls.cupertino({
    this.toolbar,
    this.handle = const CupertinoTextSelectionHandle(),
  }) : assert(handle != null);

  DefaultTextSelectionControls.withDefaultHandle({
    this.toolbar,
    BuildContext context,
  }) : handle = defaultHandle(context);

  static TextSelectionHandle defaultHandle(BuildContext context) {
    final platform = Theme.of(context).platform;
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoTextSelectionHandle();
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return MaterialSelectionHandle();
    }
    return null;
  }

  /// Returns the size of the Material handle.
  @override
  Size getHandleSize(double textLineHeight) =>
      handle.getHandleSize(textLineHeight);

  /// Builder for material-style text selection handles.
  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textHeight) {
    return handle.buildHandle(context, type, textHeight);
  }

  /// Gets anchor for material-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return handle.getHandleAnchor(type, textLineHeight);
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    // Android allows SelectAll when selection is not collapsed, unless
    // everything has already been selected.
    final TextEditingValue value = delegate.textEditingValue;
    return delegate.selectAllEnabled &&
        value.text.isNotEmpty &&
        !(value.selection.start == 0 &&
            value.selection.end == value.text.length);
  }

  @override
  Widget buildToolbar(
      BuildContext context,
      Rect globalEditableRegion,
      double textLineHeight,
      Offset position,
      List<TextSelectionPoint> endpoints,
      TextSelectionDelegate delegate,
      ClipboardStatusNotifier clipboardStatus) {
    return TextSelectionToolbarController(
      clipboardStatus: clipboardStatus,
      delegate: delegate,
      cut: canCut(delegate) ? () => handleCut(delegate) : null,
      copy: canCopy(delegate)
          ? () => handleCopy(delegate, clipboardStatus)
          : null,
      paste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      selectAll:
          canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      builder: (context) {
        return this.toolbar.buildToolbar(
              context,
              globalEditableRegion,
              textLineHeight,
              position,
              endpoints,
              delegate,
              clipboardStatus,
            );
      },
    );
  }
}
