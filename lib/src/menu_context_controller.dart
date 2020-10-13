import 'package:flutter/material.dart';
import 'package:selection_controls_example/context_menu.dart';
import 'package:selection_controls_example/src/text_selection_toolbar_controller.dart';
import 'package:selection_controls_example/src/text_selection_controls.dart';

class MenuContextController extends ChangeNotifier {
  final VoidCallback hide;
  final DefaultTextSelectionOptionsScope textSelectionController; //optional

  MenuContextController({@required this.hide, this.textSelectionController});

  int get depth => _depth.length;

  final List<List<ContextMenuItem>> _depth = [];

  void push(List<ContextMenuItem> children) {
    assert(children != null, 'Only items with children can be nested');
    _depth.add(children);
    notifyListeners();
  }

  void pop() {
    if (_depth.isNotEmpty)
      _depth.removeLast();
    else
      hide();

    notifyListeners();
  }

  bool get isNested => _depth.isNotEmpty;
  List<ContextMenuItem> get currentItems => _depth.last;
}

class DefaultMenuContextController extends StatefulWidget {
  final VoidCallback hide;
  final Widget child;
  final DefaultTextSelectionOptionsScope textSelectionController;

  const DefaultMenuContextController(
      {Key key, this.hide, this.textSelectionController, this.child})
      : super(key: key);
  @override
  _DefaultMenuContextControllerState createState() =>
      _DefaultMenuContextControllerState();

  static MenuContextController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ContextControllerScope>()
      .controller;
}

class _DefaultMenuContextControllerState
    extends State<DefaultMenuContextController> {
  MenuContextController controller;

  @override
  void initState() {
    controller = MenuContextController(
        hide: widget.hide,
        textSelectionController: widget.textSelectionController);
    controller.addListener(update);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _ContextControllerScope(
      controller: controller,
      child: widget.child,
    );
  }

  update() {
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(update);
    controller.dispose();
    super.dispose();
  }
}

class _ContextControllerScope extends InheritedWidget {
  final MenuContextController controller;

  _ContextControllerScope({this.controller, Widget child})
      : super(child: child);

  @override
  bool updateShouldNotify(covariant _ContextControllerScope oldWidget) {
    return oldWidget.controller.depth != oldWidget.controller.depth;
  }
}
