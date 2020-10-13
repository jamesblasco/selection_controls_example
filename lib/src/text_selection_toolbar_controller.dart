import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:selection_controls_example/context_menu.dart';

import 'menu_context_controller.dart';

typedef bool SelectionToolbarCallback(MenuContextController controller);


/// Manages a copy/paste text selection toolbar.
class TextSelectionToolbarController extends StatefulWidget {
  
  static DefaultTextSelectionOptionsScope of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DefaultTextSelectionOptionsScope>();

  const TextSelectionToolbarController({
    this.clipboardStatus,
    Key key,
    this.cut,
    this.copy,
    this.paste,
    this.selectAll,
    @required this.child,
    this.delegate,
  }) : super(key: key);

  final ClipboardStatusNotifier clipboardStatus;
  final TextSelectionDelegate delegate;
  final VoidCallback cut;
  final VoidCallback copy;
  final VoidCallback paste;
  final VoidCallback selectAll;
  final Widget child;

  @override
  _TextSelectionToolbarControllerState createState() =>
      _TextSelectionToolbarControllerState();
}

class _TextSelectionToolbarControllerState
    extends State<TextSelectionToolbarController>
    with TickerProviderStateMixin {
  ClipboardStatusNotifier _clipboardStatus;

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    _clipboardStatus = widget.clipboardStatus ?? ClipboardStatusNotifier();
    _clipboardStatus.addListener(_onChangedClipboardStatus);
    _clipboardStatus.update();
  }

  @override
  void didUpdateWidget(TextSelectionToolbarController oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.clipboardStatus == null && widget.clipboardStatus != null) {
      _clipboardStatus.removeListener(_onChangedClipboardStatus);
      _clipboardStatus.dispose();
      _clipboardStatus = widget.clipboardStatus;
    } else if (oldWidget.clipboardStatus != null) {
      if (widget.clipboardStatus == null) {
        _clipboardStatus = ClipboardStatusNotifier();
        _clipboardStatus.addListener(_onChangedClipboardStatus);
        oldWidget.clipboardStatus.removeListener(_onChangedClipboardStatus);
      } else if (widget.clipboardStatus != oldWidget.clipboardStatus) {
        _clipboardStatus = widget.clipboardStatus;
        _clipboardStatus.addListener(_onChangedClipboardStatus);
        oldWidget.clipboardStatus.removeListener(_onChangedClipboardStatus);
      }
    }
    if (widget.paste != null) {
      _clipboardStatus.update();
    }
  }

  @override
  void dispose() {
    super.dispose();
    // When used in an Overlay, this can be disposed after its creator has
    // already disposed _clipboardStatus.
    if (!_clipboardStatus.disposed) {
      _clipboardStatus.removeListener(_onChangedClipboardStatus);
      if (widget.clipboardStatus == null) {
        _clipboardStatus.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render the menu until the state of the clipboard is known.
    if (widget.paste != null &&
        _clipboardStatus.value == ClipboardStatus.unknown) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<ContextMenuItem> items = <ContextMenuItem>[
      if (widget.cut != null)
        ContextMenuItem(
          onPressed: (_) {
            widget.cut();
            return true;
          },
          title: Text(localizations.cutButtonLabel),
        ),
      if (widget.copy != null)
        ContextMenuItem(
            onPressed: (_) {
              widget.copy();
              return true;
            },
            title: Text(localizations.copyButtonLabel)),
      if (widget.paste != null &&
          _clipboardStatus.value == ClipboardStatus.pasteable)
        ContextMenuItem(
            onPressed: (_) {
              widget.paste();
              return true;
            },
            title: Text(localizations.pasteButtonLabel)),
      if (widget.selectAll != null)
        ContextMenuItem(
            onPressed: (_) {
              widget.selectAll();
              return true;
            },
            title: Text(localizations.selectAllButtonLabel)),
    ];
    return DefaultTextSelectionOptionsScope(
      clipboardStatus: widget.clipboardStatus,
      delegate: widget.delegate,
      cut: widget.cut,
      copy: widget.copy,
      paste: widget.paste,
      selectAll: widget.selectAll,
      defaultItems: items,
      child: widget.child,
    );
  }
}

class DefaultTextSelectionOptionsScope extends InheritedWidget {
  final ClipboardStatusNotifier clipboardStatus;
  final TextSelectionDelegate delegate;

  final VoidCallback cut;
  final VoidCallback copy;
  final VoidCallback paste;
  final VoidCallback selectAll;

  bool get canCut => cut != null;
  bool get canCopy => copy != null;
  bool get canPaste =>
      paste != null && clipboardStatus.value == ClipboardStatus.pasteable;
  bool get canSelectAll => selectAll != null;

  TextSelection get selection => delegate.textEditingValue.selection;

  final Widget child;

  final List<ContextMenuItem> defaultItems;

  DefaultTextSelectionOptionsScope({
    this.clipboardStatus,
    this.delegate,
    this.cut,
    this.copy,
    this.paste,
    this.selectAll,
    this.child,
    this.defaultItems,
  }) : super(child: child);

  @override
  bool updateShouldNotify(
      covariant DefaultTextSelectionOptionsScope oldWidget) {
    return cut != oldWidget.cut ||
        copy != oldWidget.copy ||
        paste != oldWidget.paste ||
        selectAll != oldWidget.selectAll ||
        clipboardStatus != oldWidget.clipboardStatus ||
        defaultItems.length != defaultItems.length;
  }

  void hide() {
    delegate.hideToolbar();
  }
}
