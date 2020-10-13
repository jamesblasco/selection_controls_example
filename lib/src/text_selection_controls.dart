import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:selection_controls_example/src/cupertino/cupertino_selection_handle.dart';
import 'package:selection_controls_example/src/menu_context_controller.dart';
import 'package:selection_controls_example/src/text_selection_toolbar_controller.dart';
import 'dart:math' as math;

import '../context_menu.dart';
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

class DefaultTextSelectionControls extends TextSelectionControls {
  final TextSelectionHandle handle;
  final ContextMenu toolbar;

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

  DefaultTextSelectionControls.withPlatformHandle({
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
      child: Builder(
        builder: (context) {
          return DefaultMenuContextController(
            hide: () => delegate.hideToolbar(),
            textSelectionController: TextSelectionToolbarController.of(context),
            child: Builder(
              builder: (context) {
                return this.toolbar.buildToolbar(
                      context,
                      globalEditableRegion,
                      textLineHeight,
                      position,
                      endpoints,
                    );
              },
            ),
          );
        },
      ),
    );
  }
}
