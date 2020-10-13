import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selection_controls_example/src/cascade/cascade_context_menu.dart';
import 'package:selection_controls_example/src/context_menu_button.dart';
import 'package:selection_controls_example/src/cupertino/cupertino_pull_down_menu.dart';
import 'package:selection_controls_example/src/cupertino/cupertino_selection_controllers.dart';
import 'package:selection_controls_example/src/cupertino/cupertino_selection_handle.dart';
import 'package:selection_controls_example/src/material/material_selection_controllers.dart';
import 'package:selection_controls_example/src/text_selection_controls.dart';

import 'context_menu.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Colors.grey[300],
        ),
        accentColor: Colors.amber,

        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.grey,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RichTextEditor(text: text),
    );
  }
}

class RichTextEditor extends StatefulWidget {
  RichTextEditor({Key key, this.text}) : super(key: key);

  final String text;

  @override
  _RichTextEditorState createState() => _RichTextEditorState();
}

class RichTextSection {
  final TextStyle style;
  final TextSelection selection;

  RichTextSection({this.selection, this.style});
}

class RichTextController extends ChangeNotifier {
  final String _sourceText;

  RichTextController(this._sourceText)
      : sections = [
          RichTextSection(
            selection: TextSelection(
              baseOffset: 0,
              extentOffset: _sourceText.length,
            ),
          )
        ];

  List<RichTextSection> sections;

  void setStyle(TextSelection selection, TextStyle style) {
    final previousSelection = RichTextSection(
        selection:
            TextSelection(baseOffset: 0, extentOffset: selection.baseOffset));
    final newSelection = RichTextSection(selection: selection, style: style);
    final endSelection = RichTextSection(
      selection: TextSelection(
          baseOffset: selection.extentOffset, extentOffset: _sourceText.length),
    );
    sections = [
      previousSelection,
      newSelection,
      endSelection,
    ];
    notifyListeners();
  }

  TextSpan get textSpan => TextSpan(
        children: [
          for (final section in sections)
            TextSpan(
              text: section.selection.textInside(_sourceText),
              style: section.style,
            )
        ],
      );
}

enum ToolbarExample { cupertino, material, custom, cascade, cupertinoPullDown }

extension on ToolbarExample {
  String get title {
    return {
      ToolbarExample.cupertino: 'Cupertino',
      ToolbarExample.material: 'Material',
      ToolbarExample.custom: 'Custom',
      ToolbarExample.cascade: 'Cascade',
      ToolbarExample.cupertinoPullDown: 'Cupertino PullDown',
    }[this];
  }
}

class _RichTextEditorState extends State<RichTextEditor> {
  RichTextController controller;

  @override
  void initState() {
    controller = RichTextController(widget.text);
    controller.addListener(updateRichText);
    super.initState();
  }

  updateRichText() {
    setState(() {
      // Notify rich text changes
    });
  }

  @override
  void didUpdateWidget(RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text) {
      controller.removeListener(updateRichText);
      controller.dispose();
      controller = RichTextController(widget.text);
      controller.addListener(updateRichText);
    }
  }

  @override
  void dispose() {
    controller.removeListener(updateRichText);
    controller.dispose();
    super.dispose();
  }

  ToolbarExample example = ToolbarExample.material;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ContextMenuButton(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu),
              SizedBox(width: 20),
              Text('Menus'),
            ],
          ),
          tooltip: 'This is tooltip',
          menu: menu(textSelection: false),
        ),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 40),
          child: Padding(
            padding: EdgeInsets.all(6),
            child: CupertinoSlidingSegmentedControl(
              backgroundColor: Colors.grey[100],
              groupValue: example,
              onValueChanged: (value) {
                setState(() {
                  example = value;
                });
              },
              children: Map.fromEntries(
                ToolbarExample.values.map(
                  (example) => MapEntry(example, Text(example.title)),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SelectableText.rich(
          controller.textSpan,
          cursorColor: Colors.black,
          style: TextStyle(color: Colors.grey[700], fontSize: 16),
          toolbarOptions: ToolbarOptions(copy: true),
          textSelectionControls: DefaultTextSelectionControls(
            handle: CupertinoTextSelectionHandle(color: Colors.black),
            toolbar: menu(textSelection: true),
          ),
        ),
      ),
    );
  }

  List<ContextMenuItem> items({bool textSelection = false}) {
    return [
      ContextMenuItem(
        title: Icon(Icons.brush, size: 18),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(
              backgroundColor: Color(0xffd4ff32),
              color: Colors.black,
            ),
          );
          return true;
        },
      ),
      ContextMenuItem(
        title: Icon(
          Icons.format_bold,
          size: 18,
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontWeight: FontWeight.bold),
          );
          return true;
        },
      ),
      ContextMenuItem(
        title: Icon(
          Icons.format_italic,
          size: 18,
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontStyle: FontStyle.italic),
          );
          return true;
        },
      ),
      if (textSelection) TextSelectionContextMenuItem.copy(),
      //  TextSelectionToolbarItem.paste()
    ];
  }

  ContextMenu menu({bool textSelection = false}) {
    switch (example) {
      case ToolbarExample.cupertino:
        return CupertinoSelectionToolbar(
          actions: [
            ContextMenuItem.sublist(title: Text('Format'), children: [
              ContextMenuItem(
                title: Icon(Icons.brush, size: 18),
                onPressed: (menuController) {
                  final selection =
                      menuController.textSelectionController?.selection;
                  if (selection == null) return true;
                  controller.setStyle(
                    selection,
                    TextStyle(
                      backgroundColor: Color(0xffd4ff32),
                      color: Colors.black,
                    ),
                  );
                  return true;
                },
              ),
              ContextMenuItem(
                title: Icon(
                  Icons.format_bold,
                  size: 18,
                ),
                onPressed: (menuController) {
                  final selection =
                      menuController.textSelectionController?.selection;
                  if (selection == null) return true;
                  controller.setStyle(
                    selection,
                    TextStyle(fontWeight: FontWeight.bold),
                  );
                  return true;
                },
              ),
              ContextMenuItem(
                title: Icon(
                  Icons.format_italic,
                  size: 18,
                ),
                onPressed: (menuController) {
                  final selection =
                      menuController.textSelectionController?.selection;
                  if (selection == null) return true;
                  controller.setStyle(
                    selection,
                    TextStyle(fontStyle: FontStyle.italic),
                  );
                  return true;
                },
              ),
            ]),
            if (textSelection) TextSelectionContextMenuItem.copy(),
            if (textSelection) TextSelectionContextMenuItem.selectAll(),
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
          theme: CupertinoThemeData(),
        );

      case ToolbarExample.material:
        return MaterialSelectionToolbar(
          actions: items(textSelection: textSelection),
        );

      case ToolbarExample.custom:
        return MaterialSelectionToolbar(
          backgroundColor: Colors.black,
          shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(12), side: BorderSide()),
          theme: ThemeData.dark(),
          actions: items(textSelection: textSelection),
        );
      case ToolbarExample.cascade:
        return CascadeContextMenu(elevation: 12, actions: nestedItems());
      case ToolbarExample.material:
        return MaterialSelectionToolbar(
          actions: items(textSelection: textSelection),
        );
      case ToolbarExample.cupertinoPullDown:
        return CupertinoPullDownMenu(
          actions: cupertinoNestedItems(),
        );
    }
    return null;
  }

  List<ContextMenuItem> nestedItems() {
    return [
      ContextMenuItem(
        title: Row(
          children: [
            Icon(Icons.brush, size: 16),
            SizedBox(width: 10),
            Text('Highlight'),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(
              backgroundColor: Color(0xffd4ff32),
              color: Colors.black,
            ),
          );
          return true;
        },
      ),
      ContextMenuItem(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.ideographic,
          //mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              Icons.format_bold_rounded,
              size: 16,
            ),
            SizedBox(
              width: 10,
            ),
            Text('Bold'),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontWeight: FontWeight.bold),
          );
          return true;
        },
      ),
      ContextMenuItem(
        title: Row(
          children: [
            Icon(Icons.format_italic, size: 16),
            SizedBox(width: 10),
            Text('Italic'),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontStyle: FontStyle.italic),
          );
          return true;
        },
      ),
      ContextMenuItem.custom(
        child: Divider(height: 1),
      ),
      ContextMenuItem(
        title: Row(
          children: [
            Icon(Icons.copy, size: 16),
            SizedBox(width: 10),
            Text('Copy'),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontStyle: FontStyle.italic),
          );
          return true;
        },
      ),
      ContextMenuItem(
        title: Row(
          children: [
            Icon(Icons.paste, size: 16),
            SizedBox(width: 10),
            Text('Paste'),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontStyle: FontStyle.italic),
          );
          return true;
        },
      ),
      ContextMenuItem.custom(
        child: Divider(height: 1),
      ),
      ContextMenuItem(
        title: Row(
          children: [
            Icon(Icons.edit, size: 16),
            SizedBox(width: 10),
            Text('Rename'),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontStyle: FontStyle.italic),
          );
          return true;
        },
      ),
      ContextMenuItem.sublist(
          title: Row(
            children: [
              Icon(Icons.more_vert, size: 16),
              SizedBox(width: 10),
              Text('More'),
              Spacer(),
              Icon(Icons.arrow_right_rounded, size: 16),
            ],
          ),
          children: [
            ContextMenuItem(
              title: Row(
                children: [
                  Icon(Icons.arrow_left_rounded, size: 16),
                  SizedBox(width: 10),
                  Text(
                    'More',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
              onPressed: (menuController) {
                menuController.pop();
                return false;
              },
            ),
            ContextMenuItem(
              title: Row(
                children: [
                  Icon(Icons.brush, size: 16),
                  SizedBox(width: 10),
                  Text('Highlight'),
                ],
              ),
              onPressed: (c) {
                final selection = c.textSelectionController?.selection;
                if (selection == null) return true;
                controller.setStyle(
                  selection,
                  TextStyle(
                    backgroundColor: Color(0xffd4ff32),
                    color: Colors.black,
                  ),
                );
                return true;
              },
            ),
            ContextMenuItem(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.ideographic,
                //mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(
                    Icons.format_bold_rounded,
                    size: 16,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text('Bold'),
                ],
              ),
              onPressed: (menuController) {
                final selection =
                    menuController.textSelectionController?.selection;
                if (selection == null) return true;
                controller.setStyle(
                  selection,
                  TextStyle(fontWeight: FontWeight.bold),
                );
                return true;
              },
            ),
            ContextMenuItem(
              title: Row(
                children: [
                  Icon(Icons.format_italic, size: 16),
                  SizedBox(width: 10),
                  Text('Italic'),
                ],
              ),
              onPressed: (menuController) {
                final selection =
                    menuController.textSelectionController?.selection;
                if (selection == null) return true;
                controller.setStyle(
                  selection,
                  TextStyle(fontStyle: FontStyle.italic),
                );
                return true;
              },
            ),
          ]),
    ];
  }

  List<ContextMenuItem> cupertinoNestedItems() {
    return [
      ContextMenuItem(
        title: Row(
          children: [
            Text('Highlight'),
            Spacer(),
            Icon(Icons.brush, size: 16),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(
              backgroundColor: Color(0xffd4ff32),
              color: Colors.black,
            ),
          );
          return true;
        },
      ),
      ContextMenuItem(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.ideographic,
          //mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text('Bold'),
            Spacer(),
            Icon(Icons.format_bold_rounded, size: 16),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontWeight: FontWeight.bold),
          );
          return true;
        },
      ),
      ContextMenuItem(
        title: Row(
          children: [
            Text('Italic'),
            Spacer(),
            Icon(Icons.format_italic, size: 16),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontStyle: FontStyle.italic),
          );
          return true;
        },
      ),
      ContextMenuItem.custom(
        child: Divider(height: 1),
      ),
      ContextMenuItem(
        title: Row(
          children: [
            Text('Copy'),
            Spacer(),
            Icon(Icons.copy, size: 16),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontStyle: FontStyle.italic),
          );
          return true;
        },
      ),
      ContextMenuItem(
        title: Row(
          children: [
            Text('Paste'),
            Spacer(),
            Icon(Icons.paste, size: 16),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontStyle: FontStyle.italic),
          );
          return true;
        },
      ),
      ContextMenuItem.custom(
        child: Divider(height: 1),
      ),
      ContextMenuItem(
        title: Row(
          children: [
            Text('Rename'),
            Spacer(),
            Icon(Icons.edit, size: 16),
          ],
        ),
        onPressed: (menuController) {
          final selection = menuController.textSelectionController?.selection;
          if (selection == null) return true;
          controller.setStyle(
            selection,
            TextStyle(fontStyle: FontStyle.italic),
          );
          return true;
        },
      ),
      ContextMenuItem.sublist(
          title: Row(
            children: [
              Text('More'),
              Spacer(),
              Icon(Icons.arrow_right_rounded, size: 16),
            ],
          ),
          children: [
            ContextMenuItem(
              title: Row(
                children: [
                  Icon(Icons.arrow_left_rounded, size: 16),
                  SizedBox(width: 10),
                  Text(
                    'More',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
              onPressed: (menuController) {
                menuController.pop();
                return false;
              },
            ),
            ContextMenuItem(
              title: Row(
                children: [
                  Icon(Icons.brush, size: 16),
                  SizedBox(width: 10),
                  Text('Highlight'),
                ],
              ),
              onPressed: (c) {
                final selection = c.textSelectionController?.selection;
                if (selection == null) return true;
                controller.setStyle(
                  selection,
                  TextStyle(
                    backgroundColor: Color(0xffd4ff32),
                    color: Colors.black,
                  ),
                );
                return true;
              },
            ),
            ContextMenuItem(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.ideographic,
                //mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(
                    Icons.format_bold_rounded,
                    size: 16,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text('Bold'),
                ],
              ),
              onPressed: (menuController) {
                final selection =
                    menuController.textSelectionController?.selection;
                if (selection == null) return true;
                controller.setStyle(
                  selection,
                  TextStyle(fontWeight: FontWeight.bold),
                );
                return true;
              },
            ),
            ContextMenuItem(
              title: Row(
                children: [
                  Icon(Icons.format_italic, size: 16),
                  SizedBox(width: 10),
                  Text('Italic'),
                ],
              ),
              onPressed: (menuController) {
                final selection =
                    menuController.textSelectionController?.selection;
                if (selection == null) return true;
                controller.setStyle(
                  selection,
                  TextStyle(fontStyle: FontStyle.italic),
                );
                return true;
              },
            ),
          ]),
    ];
  }
}

final text = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce sit amet semper leo, sed consequat ante. Etiam eu elit fermentum, pulvinar velit ut, lobortis velit. Cras et tellus vestibulum, tincidunt dui eu, pretium est. Aliquam erat volutpat. Suspendisse dictum diam purus, nec dapibus urna vestibulum vitae. Sed vitae ultricies ligula. Aliquam hendrerit lorem ultricies, pulvinar elit sit amet, semper sapien. Morbi non pellentesque libero. Ut vehicula nisl in enim maximus elementum. Integer scelerisque nisl quis sapien dignissim aliquam.

Proin a tincidunt metus. Ut scelerisque hendrerit leo, at eleifend elit ornare in. Morbi tristique neque ipsum, nec consectetur neque auctor nec. Fusce tellus elit, molestie sed urna sed, placerat sagittis magna. Donec non semper enim. Aenean sollicitudin blandit diam, sit amet ullamcorper nulla consequat nec. Etiam in hendrerit ex. Mauris semper nulla id sollicitudin porttitor.

Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Cras suscipit vel mi sollicitudin tempus. Sed quis libero dapibus urna condimentum porta. Aenean id enim at nisi consequat pulvinar. Mauris vel ex non diam auctor venenatis id a ante. Cras molestie sagittis ex ut finibus. Mauris efficitur, velit eleifend ultricies pharetra, enim lacus scelerisque metus, eget auctor ipsum turpis eu sapien. Duis varius vulputate sem, sed porta neque. Sed gravida congue orci ut hendrerit. Donec ligula tellus, aliquet aliquam lectus et, sodales molestie justo.

Nullam iaculis dolor a enim pulvinar iaculis. Fusce in tempor odio. Quisque fringilla mattis tellus. Nulla tincidunt sodales diam ornare lobortis. Morbi ac dolor lacus. Vivamus pellentesque, nisl sed finibus tempus, neque magna hendrerit eros, ac sodales ligula libero quis magna. Nulla facilisi. Duis tristique ullamcorper nisi, sed congue est aliquam sit amet. Morbi sem eros, consequat ac metus ut, vehicula mollis lectus. Donec non velit sit amet elit fringilla varius quis quis magna. Nullam felis magna, varius nec luctus vel, lobortis ac quam. Nulla aliquet risus non orci auctor, gravida tristique nunc tempus. Aenean ultrices sapien tortor.

In eget ipsum blandit dui consectetur sodales. Integer dignissim libero at eleifend semper. Cras non viverra leo. Vestibulum elit tortor, malesuada eget tempor vel, sodales nec ipsum. Integer accumsan sapien vel tortor efficitur venenatis. Vivamus ultrices mauris eu odio dignissim, quis facilisis nulla semper. Curabitur congue molestie ante. Nulla facilisi. Nunc quis posuere lectus, non iaculis nulla. Vestibulum dignissim, odio id venenatis placerat, ante est posuere erat, non interdum eros justo at mi. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
''';
