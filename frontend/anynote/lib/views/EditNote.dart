import 'dart:ui';

import 'package:anynote/Extension.dart';
import 'package:anynote/GlobalConfig.dart';
import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/MarkdwonShortcutBar.dart';
import 'package:anynote/views/note_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../AiHelper.dart';

enum SyncStatus { waiting, syncing, completed, error }

class EditNotePage extends StatefulWidget {
  NoteItem? item;
  EditNotePage({super.key, this.item});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  MainController c = Get.find<MainController>();
  TextEditingController tc = MarkdownEditingController();
  FocusNode fn = FocusNode();
  FocusNode tfn = FocusNode();
  Timer? _debounce;
  String _lastChange = "";
  NoteItem? item;
  SyncStatus _syncStatus = SyncStatus.completed; // 初始状态为完成

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
    if (widget.item == null) {
      c.addNote().then((res) => item = res);
      tfn.requestFocus();
    } else {
      item = widget.item;
      tc.text = widget.item!.content ?? "";
    }
    tc.addListener(textUpdate);

    c.updateEditTextCallback = updatingEditText;

    super.initState();
  }

  @override
  void dispose() {
    tc.removeListener(textUpdate);
    _debounce?.cancel();
    super.dispose();
  }

  void updatingEditText(String id, String newText) {
    if (item == null || tc == null || id.isEmpty) {
      print('无效的参数或未初始化的对象');
      return;
    }

    if (item!.id.toString() != id || item!.content == newText) {
      return;
    }

    try {
      String oldText = item!.content??"";
      int oldCursorPosition = tc.selection.baseOffset;

      // 计算新的光标位置
      int newCursorPosition = calculateNewCursorPosition(oldText, newText, oldCursorPosition);

      // 更新内容和光标位置
      item!.content = newText;
      tc.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );

      if (tfn != null) {
        tfn.requestFocus();
      }
    } catch (e) {
      print('更新文本时发生错误: $e');
    }
  }

  int calculateNewCursorPosition(String oldText, String newText, int oldCursorPosition) {
    // 如果旧文本为空，将光标放在新文本的开始
    if (oldText.isEmpty) {
      return 0;
    }

    // 如果新文本为空，将光标放在开始位置
    if (newText.isEmpty) {
      return 0;
    }

    // 找到共同前缀长度
    int commonPrefixLength = 0;
    while (commonPrefixLength < oldText.length &&
        commonPrefixLength < newText.length &&
        oldText[commonPrefixLength] == newText[commonPrefixLength]) {
      commonPrefixLength++;
    }

    // 找到共同后缀长度
    int commonSuffixLength = 0;
    while (commonSuffixLength < oldText.length - commonPrefixLength &&
        commonSuffixLength < newText.length - commonPrefixLength &&
        oldText[oldText.length - 1 - commonSuffixLength] == newText[newText.length - 1 - commonSuffixLength]) {
      commonSuffixLength++;
    }

    // 如果光标在共同前缀内，保持原位置
    if (oldCursorPosition <= commonPrefixLength) {
      return oldCursorPosition;
    }

    // 如果光标在共同后缀内，调整位置
    if (oldCursorPosition > oldText.length - commonSuffixLength) {
      return newText.length - (oldText.length - oldCursorPosition);
    }

    // 如果文本完全不匹配或光标在中间变化的部分
    double relativePosition = oldText.isEmpty ? 0 : oldCursorPosition / oldText.length;
    return (relativePosition * newText.length).round();
  }

  void textUpdate() {
    if (item == null) return;
    if (item!.content == tc.text) return;
    item!.content = tc.text;

    setState(() {
      _syncStatus = SyncStatus.waiting; // 设置为等待状态
    });

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _syncStatus = SyncStatus.syncing; // 开始同步
      });
      c.updateNote(item!.id!, item!).then((res) {
        setState(() {
          if (res) {
            _syncStatus = SyncStatus.completed; // 同步完成
          } else {
            _syncStatus = SyncStatus.error; // 同步失败
          }
        });
      });
    });

    TextChangeEx(tc, _lastChange);
    _lastChange = tc.text;
  }

  void _changeNoteColor(Color color) {
    setState(() {
      item?.color = color.value & 0x00FFFFFF;
      _syncStatus = SyncStatus.waiting; // 设置为等待状态
    });
    if (item != null) {
      setState(() {
        _syncStatus = SyncStatus.syncing; // 开始同步
      });
      c.updateNote(item!.id!, item!).then((_) {
        setState(() {
          _syncStatus = SyncStatus.completed; // 同步完成
        });
      });
    }
  }

  Widget _getSyncIcon() {
    switch (_syncStatus) {
      case SyncStatus.waiting:
        return const Icon(Icons.schedule, color: Colors.orange);
      case SyncStatus.syncing:
        return const Icon(Icons.sync, color: Colors.blue);
      case SyncStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (handle) {
        if (item != null && (item!.content ?? "").trim().isEmpty) {
          c.deleteNoteWithoutPrompt(item!.id!);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor:
              item != null ? item!.color.toFullARGB() : Colors.white,
          systemNavigationBarColor:
              item != null ? item!.color.toFullARGB() : Colors.white,
        ),
        child: Scaffold(
          backgroundColor:
              item != null ? item!.color.toFullARGB() : Colors.white,
          appBar: AppBar(
            title: Text(widget.item == null ? "Add New" : "Edit"),
            backgroundColor:
                item != null ? item!.color.toFullARGB() : Colors.white,
            actions: [
              IconButton(
                onPressed: () {},
                icon: _getSyncIcon(),
              )
            ],
          ),
          body: Column(
            children: [
              ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  scrollbars: true,
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: SingleChildScrollView(
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
                                color: item?.color == color.value
                                    ? Colors.black
                                    : Colors.grey,
                                width: item?.color == color.value ? 2 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: RawKeyboardListener(
                  focusNode: fn,
                  onKey: (event) async {
                    if (event is RawKeyDownEvent) {
                      if (event.isControlPressed &&
                          event.logicalKey == LogicalKeyboardKey.keyJ) {
                        await CallAI();
                      }

                      if (event.isShiftPressed &&
                          event.logicalKey == LogicalKeyboardKey.tab) {
                        UnindentText(tc, tfn);
                      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
                        IndentText(tc, tfn);
                      }
                    }
                  },
                  child: TextField(
                    controller: tc,
                    focusNode: tfn,
                    minLines: null,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: GlobalConfig.fontSize.toDouble(),
                        letterSpacing: 1,
                        height: 2),
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(30),
                    ),
                  ),
                ),
              ),
              MarkdownShortcutBar(
                controller: tc,
                focusNode: tfn,
                onAiTap: CallAI,
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> CallAI() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI 生成中...'),
        duration: Duration(seconds: 60), // 设置显示时间
      ),
    );
    await SendMessage(tc);
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
