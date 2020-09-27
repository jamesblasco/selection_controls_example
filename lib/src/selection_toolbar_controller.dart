import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:selection_controls_example/src/text_selection_controls.dart';


typedef _TextSelectionToolbarBuilder = Widget Function(
    List<TextSelectionToolbarItem> items);

class TextSelectionToolbarController extends StatelessWidget {
  final TextSelectionDelegate delegate;
  final ClipboardStatusNotifier clipboardStatus;
  final WidgetBuilder builder;

  final VoidCallback cut;
  final VoidCallback copy;
  final VoidCallback paste;
  final VoidCallback selectAll;

  static _DefaultTextSelectionOptionsScope of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_DefaultTextSelectionOptionsScope>();

  const TextSelectionToolbarController({
    Key key,
    this.builder,
    this.delegate,
    this.clipboardStatus,
    this.cut,
    this.copy,
    this.paste,
    this.selectAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ClipboardToolbarItemsHandler(
        clipboardStatus: clipboardStatus,
        handleCopy: copy,
        handleCut: cut,
        handlePaste: paste,
        handleSelectAll: selectAll,
        builder: (defaultItems) {
          return _DefaultTextSelectionOptionsScope(
            clipboardStatus: clipboardStatus,
            delegate: delegate,
            cut: cut,
            copy: copy,
            paste: paste,
            selectAll: selectAll,
            defaultItems: defaultItems,
            child: builder(context),
          );
        });
  }
}

typedef SelectionToolbarCallback =  Function(_DefaultTextSelectionOptionsScope controller);

/// Manages a copy/paste text selection toolbar.
class _ClipboardToolbarItemsHandler extends StatefulWidget {
  const _ClipboardToolbarItemsHandler({
    this.clipboardStatus,
    Key key,
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
    this.builder,
  }) : super(key: key);

  final ClipboardStatusNotifier clipboardStatus;
  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;

  final _TextSelectionToolbarBuilder builder;

  @override
  _ClipboardToolbarItemsHandlerState createState() =>
      _ClipboardToolbarItemsHandlerState();
}

class _ClipboardToolbarItemsHandlerState
    extends State<_ClipboardToolbarItemsHandler> with TickerProviderStateMixin {
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
  void didUpdateWidget(_ClipboardToolbarItemsHandler oldWidget) {
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
    if (widget.handlePaste != null) {
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
    if (widget.handlePaste != null &&
        _clipboardStatus.value == ClipboardStatus.unknown) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<TextSelectionToolbarItem> itemDatas = <TextSelectionToolbarItem>[
      if (widget.handleCut != null)
        TextSelectionToolbarItem(
          onPressed: (_) =>widget.handleCut(),
          title: Text(localizations.cutButtonLabel),
        ),
      if (widget.handleCopy != null)
        TextSelectionToolbarItem(
            onPressed: (_) => widget.handleCopy(),
            title: Text(localizations.copyButtonLabel)),
      if (widget.handlePaste != null &&
          _clipboardStatus.value == ClipboardStatus.pasteable)
        TextSelectionToolbarItem(
            onPressed: (_) => widget.handlePaste(),
            title: Text(localizations.pasteButtonLabel)),
      if (widget.handleSelectAll != null)
        TextSelectionToolbarItem(
            onPressed: (_) => widget.handleSelectAll(),
            title: Text(localizations.selectAllButtonLabel)),
    ];
    return widget.builder(itemDatas);
  }
}

class _DefaultTextSelectionOptionsScope extends InheritedWidget {
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
  final List<TextSelectionToolbarItem> defaultItems;

  _DefaultTextSelectionOptionsScope({
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
      covariant _DefaultTextSelectionOptionsScope oldWidget) {
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
