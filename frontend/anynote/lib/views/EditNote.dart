import 'dart:async';
import 'dart:ui';

import 'package:anynote/Extension.dart';
import 'package:anynote/GlobalConfig.dart';
import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/MarkdwonShortcutBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';

import '../AiHelper.dart';

enum SyncStatus { waiting, syncing, completed, error }

class EditNotePage extends StatefulWidget {
  final NoteItem? item;
  const EditNotePage({Key? key, this.item}) : super(key: key);

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final MainController controller = Get.find<MainController>();
  late final TextEditingController textController;
  final FocusNode focusNode = FocusNode();
  final FocusNode textFocusNode = FocusNode();
  Timer? _debounce;
  String _lastChange = "";
  late NoteItem item;
  SyncStatus _syncStatus = SyncStatus.completed;

  final List<Color> _colors = [
    Colors.white,
    Colors.red[50]!,
    Colors.orange[50]!,
    Colors.yellow[50]!,
    Colors.green[50]!,
    Colors.blue[50]!,
    Colors.purple[50]!,
    Colors.pink[50]!,
    Colors.indigo[50]!,
    Colors.teal[50]!,
    Colors.cyan[50]!,
    Colors.deepPurple[50]!,
    Colors.grey[100]!,
  ];

  @override
  void initState() {
    super.initState();

    if (widget.item == null) {
      item = NoteItem(
        createTime: DateTime.now(),
        index: 0,
        id: IDGenerator.generateOfflineId(),
      );
      Future.microtask(() {
        controller.addNote(item).then((res) {
          item.id = res.id;
        });
      });

      textFocusNode.requestFocus();
    } else {
      item = widget.item!;
    }

    textController = MarkdownEditingController();
    textController.text = item.content ?? "";
    _lastChange = textController.text;

    textController.addListener(_textUpdate);
    controller.updateEditTextCallback = _updatingEditText;

    KeyboardVisibilityController().onChange.listen((bool visible) {
      if (!visible) {
        textFocusNode.unfocus();
        textController.selection = const TextSelection.collapsed(offset: -1);
      }
    });
  }

  @override
  void dispose() {
    textController.removeListener(_textUpdate);
    _debounce?.cancel();
    textController.dispose();
    textFocusNode.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _updatingEditText(String id, String newText) {
    if (item.id.toString() != id || item.content == newText) {
      return;
    }

    if (newText == "_%_delete_%_") {
      Get.back();
      return;
    }

    try {
      String oldText = item.content ?? "";
      int oldCursorPosition = textController.selection.baseOffset;

      int newCursorPosition = _calculateNewCursorPosition(
        oldText,
        newText,
        oldCursorPosition,
      );

      item.content = newText;
      textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );

      textFocusNode.requestFocus();
    } catch (e) {
      print('Error occurred while updating text: $e');
    }
  }

  int _calculateNewCursorPosition(
      String oldText, String newText, int oldCursorPosition) {
    if (oldText.isEmpty || newText.isEmpty) {
      return 0;
    }

    int commonPrefixLength = 0;
    while (commonPrefixLength < oldText.length &&
        commonPrefixLength < newText.length &&
        oldText[commonPrefixLength] == newText[commonPrefixLength]) {
      commonPrefixLength++;
    }

    int commonSuffixLength = 0;
    while (commonSuffixLength < oldText.length - commonPrefixLength &&
        commonSuffixLength < newText.length - commonPrefixLength &&
        oldText[oldText.length - 1 - commonSuffixLength] ==
            newText[newText.length - 1 - commonSuffixLength]) {
      commonSuffixLength++;
    }

    if (oldCursorPosition <= commonPrefixLength) {
      return oldCursorPosition;
    }

    if (oldCursorPosition > oldText.length - commonSuffixLength) {
      return newText.length - (oldText.length - oldCursorPosition);
    }

    double relativePosition =
        oldText.isEmpty ? 0 : oldCursorPosition / oldText.length;
    return (relativePosition * newText.length).round();
  }

  void _textUpdate() {
    if (item.content == textController.text) return;
    item.content = textController.text;

    _syncStatus = SyncStatus.waiting;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _executeUpdate);

    TextChangeEx(textController, _lastChange);
    _lastChange = textController.text;
  }

  Future<void> _executeUpdate() async {
    setState(() {
      _syncStatus = SyncStatus.syncing;
    });

    try {
      bool res = await controller.updateNote(item.id!, item);
      if (!mounted) return;

      setState(() {
        _syncStatus = res ? SyncStatus.completed : SyncStatus.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncStatus = SyncStatus.error;
      });
      print('Error updating note: $e');
    }
  }

  void _changeNoteColor(Color color) {
    setState(() {
      item.color = color.value & 0x00FFFFFF;
      _syncStatus = SyncStatus.waiting;
    });
    _executeUpdate();
  }

  Widget _getSyncIcon() {
    switch (_syncStatus) {
      case SyncStatus.waiting:
        return const Icon(Icons.schedule,
            color: Colors.orange, key: ValueKey(1));
      case SyncStatus.syncing:
        return const Icon(Icons.sync, color: Colors.blue, key: ValueKey(2));
      case SyncStatus.completed:
        return const Icon(Icons.check_circle,
            color: Colors.green, key: ValueKey(3));
      case SyncStatus.error:
        return const Icon(Icons.error, color: Colors.red, key: ValueKey(4));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _debounce?.cancel();

        Future.microtask(_executeUpdate);

        if ((item.content ?? "").trim().isEmpty) {
          controller.deleteNoteWithoutPrompt(item.id!);
        }
        return true;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: item.color.toFullARGB(),
          systemNavigationBarColor: item.color.toFullARGB(),
        ),
        child: Scaffold(
          backgroundColor: item.color.toFullARGB(),
          appBar: AppBar(
            title: Text(widget.item == null ? "Add New" : "Edit"),
            backgroundColor: item.color.toFullARGB(),
            actions: [
              IconButton(
                onPressed: () {},
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale:
                          Tween<double>(begin: 0, end: 1.0).animate(animation),
                      child: child,
                    );
                  },
                  child: _getSyncIcon(),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _colors.map((color) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () => _changeNoteColor(color),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.color == color.value
                                  ? Colors.black
                                  : Colors.grey,
                              width: item.color == color.value ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: RawKeyboardListener(
                    focusNode: focusNode,
                    onKey: (event) async {
                      if (event is RawKeyDownEvent) {
                        if (event.isControlPressed &&
                            event.logicalKey == LogicalKeyboardKey.keyJ) {
                          await _callAI();
                        }

                        if (event.isShiftPressed &&
                            event.logicalKey == LogicalKeyboardKey.tab) {
                          UnindentText(textController, textFocusNode);
                        } else if (event.logicalKey == LogicalKeyboardKey.tab) {
                          IndentText(textController, textFocusNode);
                        }
                      }
                    },
                    child: TextField(
                      controller: textController,
                      focusNode: textFocusNode,
                      minLines: null,
                      maxLines: null,
                      expands: true,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: GlobalConfig.fontSize.toDouble(),
                        letterSpacing: 1.2,
                        height: 1.8,
                      ),
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ),
              ),
              MarkdownShortcutBar(
                controller: textController,
                focusNode: textFocusNode,
                onAiTap: _callAI,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callAI() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI Generating 🚀...'),
        duration: Duration(seconds: 60),
      ),
    );
    try {
      await SendMessage(textController);
    } catch (e) {
      print(e);
    } finally {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }
}
