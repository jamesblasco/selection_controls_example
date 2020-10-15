# selection_controls_example

A repo that experiments with the missing features related to the text selection controls and context menus

```dart
final menu = CupertinoSelectionToolbar(
  theme: CupertinoThemeData(),
  actions: [
    ContextMenuItem.sublist(title: Text('Format'), children: [
      ContextMenuItem(
        title: Icon(Icons.brush, size: 18),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          highlightSelection(selection);
          return true; // Return true to close the menu when pressed
        },
      ),
      ContextMenuItem(
        title: Icon(Icons.format_bold, size: 18),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          boldSelection(selection);
          return true;
        },
      ),
    ]),
    TextSelectionContextMenuItem.copy(), // Default text selection items
    TextSelectionContextMenuItem.selectAll(),
    ContextMenuItem(
      title: Text('Search'),
      onPressed: (menuController) {
        return true;
      },
    ),
    ContextMenuItem(
      title: Text('Share'),
      onPressed: (menuController) {
        return true;
      },
    ),
  ],
);
```

To use for text inside a TextField, SelectableText, TextFormField, CupertinoTextField:
```dart
TextField(
  selectionControls: DefaultTextSelectionControls(
    handle: CupertinoTextSelectionHandle(color: Colors.black),
    toolbar: menu,
  ),
),
```

To display it when tapped on any widget.

```dart
ContextMenuButton(
  child: Icon(Icons.menu),
  menu: menu,
);
```

Custom items in text selection toolbar

![](https://user-images.githubusercontent.com/19904063/94375942-7d1f2200-0117-11eb-8e87-e5ca6e07b613.gif)

Submenus

![](https://user-images.githubusercontent.com/19904063/95842879-5f70d000-0d47-11eb-9ce4-a2d3466ca050.gif)

Context menus usable in text selection or any widget

![](https://user-images.githubusercontent.com/19904063/96102386-c375ce80-0ed6-11eb-9078-539e079dc3cd.gif)
