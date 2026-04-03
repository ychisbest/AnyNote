import 'dart:async';

import 'package:anynote/Extension.dart';
import 'package:anynote/GlobalConfig.dart';
import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/MarkdwonShortcutBar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';

import '../AiHelper.dart';

enum SyncStatus { waiting, syncing, completed, error }

class EditNotePage extends StatefulWidget {
  final NoteItem? item;
  const EditNotePage({super.key, this.item});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final MainController controller = Get.find<MainController>();
  late final TextEditingController textController;
  final FocusNode focusNode = FocusNode();
  final FocusNode textFocusNode = FocusNode();
  Timer? _debounce;
  bool _isAdding = false;
  bool _isModifyed = false;
  String _lastChange = "";
  static const Color _editorBackgroundColor = Colors.white;
  NoteItem item = NoteItem(
      createTime: DateTime.now(),
      index: 0,
      id: IDGenerator.generateOfflineId(),
      content: "");
  SyncStatus _syncStatus = SyncStatus.completed;
  List<String> _cachedTags = [];

  bool _firstLineHasTag(String text, String tag) {
    final lines = text.split('\n');
    final firstLine = lines.isNotEmpty ? lines.first : '';
    final pattern = RegExp(r'(^|\s)#' + RegExp.escape(tag) + r'(\s|$)');
    return pattern.hasMatch(firstLine);
  }

  String _removeTagFromLine(String line, String tag) {
    final pattern = RegExp(r'(^|\s)#' + RegExp.escape(tag) + r'(\s|$)');
    final cleaned = line.replaceAll(pattern, ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _insertTagIntoLine(String line, String tag) {
    final trimmed = line.trimLeft();
    if (trimmed.isEmpty) {
      return '#$tag';
    }
    return '#$tag $trimmed';
  }

  void _toggleTag(String tag) {
    final oldText = textController.text;
    final lines = oldText.split('\n');
    final firstLine = lines.isNotEmpty ? lines.first : '';
    final hasTag = _firstLineHasTag(oldText, tag);

    final newFirstLine = hasTag
        ? _removeTagFromLine(firstLine, tag)
        : _insertTagIntoLine(firstLine, tag);

    if (lines.isEmpty) {
      lines.add(newFirstLine);
    } else {
      lines[0] = newFirstLine;
    }

    final newText = lines.join('\n');
    final selection = textController.selection;
    final oldOffset = selection.baseOffset;
    final oldPrefixLen = firstLine.length;
    final newPrefixLen = newFirstLine.length;
    final diff = newPrefixLen - oldPrefixLen;
    int newOffset;
    if (oldOffset < 0) {
      newOffset = newText.length;
    } else {
      newOffset = (oldOffset + diff).clamp(0, newText.length);
    }

    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    textFocusNode.requestFocus();
  }

  Widget _buildTagColumn() {
    final tags = _cachedTags;
    if (tags.isEmpty) {
      return Center(
        child: Text(
          'No tags',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      );
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: textController,
      builder: (context, value, _) {
        final currentText = value.text;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            final isActive = _firstLineHasTag(currentText, tag);
            final bgColor = isActive
                ? const Color(0xFFE8F0FE)
                : const Color(0xFFF3F4F6);
            final borderColor = isActive
                ? const Color(0xFF90CAF9)
                : Colors.black12;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _toggleTag(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          '#$tag',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isActive)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.check, size: 14),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openTagMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _editorBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.only(top: 8),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 320,
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Tags',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildTagColumn()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        FocusScope.of(context).requestFocus(textFocusNode);
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          Future.delayed(const Duration(milliseconds: 80), () {
            if (!mounted) {
              return;
            }
            FocusScope.of(context).requestFocus(textFocusNode);
            SystemChannels.textInput.invokeMethod('TextInput.show');
          });
        }
      });
    } else {
      item = widget.item!;
    }

    textController = MarkdownEditingController();
    textController.text = item.content ?? "";
    _lastChange = textController.text;
    _cachedTags = List<String>.from(controller.tags);

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
    controller.updateEditTextCallback = null;
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

    _isModifyed=true;

    setState(() {
      item.content = textController.text;
    });

    _syncStatus = SyncStatus.waiting;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _executeUpdate);

    TextChangeEx(textController, _lastChange);
    _lastChange = textController.text;
  }

  Future<void> _executeUpdate() async {
    // 如果正在添加中，且使用的是离线 ID，则不进行重复添加
    if (_isAdding && IDGenerator.isOfflineId(item.id!)) {
      return;
    }

    setState(() {
      _syncStatus = SyncStatus.syncing;
    });

    try {
      bool res = false;

      if (IDGenerator.isOfflineId(item.id!)) {
        _isAdding = true; // 标记正在添加
        var note = await controller.addNote(item);
        res = !(note.id == item.id!);
        item.id = note.id;
        _isAdding = false; // 添加完成
      } else {
        res = await controller.updateNote(item.id!, item);
      }

      if (!mounted) return;

      setState(() {
        _syncStatus = res ? SyncStatus.completed : SyncStatus.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncStatus = SyncStatus.error;
      });
      _isAdding = false;
      print('Error updating note: $e');
    }
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

        if(!_isModifyed){
          return true;
        }

        if (IDGenerator.isOfflineId(item.id!) && item.content!.trim().isEmpty) {
          return true;
        }

        Future.microtask(_executeUpdate);

        if ((item.content ?? "").trim().isEmpty) {
          controller.deleteNoteWithoutPrompt(item.id!);
        }

        return true;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: _editorBackgroundColor,
          systemNavigationBarColor: _editorBackgroundColor,
        ),
        child: Scaffold(
          backgroundColor: _editorBackgroundColor,
          appBar: AppBar(
            title: Text(widget.item==null ? "Add New Note" : "Edit Note"),
            backgroundColor: _editorBackgroundColor,
            actions: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Tags',
                    onPressed: _openTagMenu,
                    icon: const Icon(Icons.tag),
                  ),
                  Text(countCharacters(item.content ?? "").toString()),
                  IconButton(
                    onPressed: () {},
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0, end: 1.0)
                              .animate(animation),
                          child: child,
                        );
                      },
                      child: _getSyncIcon(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: EditBody(),
        ),
      ),
    );
  }

  Widget EditBody() {
    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RawKeyboardListener(
                focusNode: focusNode,
                onKey: (event) async {
                  if (event is RawKeyDownEvent) {
                    if (event.isControlPressed &&
                        event.logicalKey == LogicalKeyboardKey.keyJ) {
                      await _callAI();
                    }

                    if (event.isControlPressed &&
                        event.logicalKey == LogicalKeyboardKey.keyL) {
                      final text = textController.text;
                      final selection = textController.selection;
                      final lineStart = text.isEmpty
                          ? 0
                          : text.lastIndexOf('\n', selection.start - 1) + 1;
                      final lineEnd = text.indexOf('\n', selection.end);
                      final line = text.substring(
                        lineStart,
                        lineEnd == -1 ? null : lineEnd,
                      );

                      String newLine;
                      if (line.trimLeft().startsWith('- [ ] ')) {
                        newLine = line.replaceFirst('- [ ] ', '- [x] ');
                      } else if (line.trimLeft().startsWith('- [x] ')) {
                        newLine = line.replaceFirst('- [x] ', '- [ ] ');
                      } else if (line.trimLeft().startsWith('- ')) {
                        newLine = line.replaceFirst('- ', '- [ ] ');
                      } else {
                        newLine = '- [ ] $line';
                      }

                      var newselection = TextSelection(
                        baseOffset: lineStart,
                        extentOffset: lineEnd == -1 ? text.length : lineEnd,
                      );

                      final newValue = TextEditingValue(
                        text: text.replaceRange(
                          newselection.start,
                          newselection.end,
                          newLine,
                        ),
                        selection: TextSelection.collapsed(
                          offset: newselection.start + newLine.length,
                        ),
                      );
                      textController.value = newValue;
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
                    //letterSpacing: 1.2,
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
        ),
        MarkdownShortcutBar(
          controller: textController,
          focusNode: textFocusNode,
          onAiTap: _callAI,
        ),
      ],
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
      await continueTheText(textController);
    } catch (e) {
      print(e);
    } finally {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }
}

bool isChineseCharacter(int codeUnit) {
  return (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||
      (codeUnit >= 0x3400 && codeUnit <= 0x4DBF) || // CJK 扩展 A
      (codeUnit >= 0x20000 && codeUnit <= 0x2A6DF) || // CJK 扩展 B
      (codeUnit >= 0x2A700 && codeUnit <= 0x2B73F) || // CJK 扩展 C
      (codeUnit >= 0x2B740 && codeUnit <= 0x2B81F) || // CJK 扩展 D
      (codeUnit >= 0x2B820 && codeUnit <= 0x2CEAF) || // CJK 扩展 E
      (codeUnit >= 0xF900 && codeUnit <= 0xFAFF) || // CJK 兼容汉字
      (codeUnit >= 0x2F800 && codeUnit <= 0x2FA1F); // CJK 兼容汉字补充
}

bool isLetterOrDigit(int codeUnit) {
  // 使用Unicode范围判断字母和数字
  // 字母：\p{L}, 数字：\p{N}
  // 由于Dart RegExp不支持\p{L}，需要手动定义常见的Unicode范围
  // 这里只列出部分范围，实际可根据需要扩展
  return (codeUnit >= 0x0041 && codeUnit <= 0x005A) || // A-Z
      (codeUnit >= 0x0061 && codeUnit <= 0x007A) || // a-z
      (codeUnit >= 0x00C0 && codeUnit <= 0x00D6) || // À-Ö
      (codeUnit >= 0x00D8 && codeUnit <= 0x00F6) || // Ø-ö
      (codeUnit >= 0x00F8 && codeUnit <= 0x00FF) || // ø-ÿ
      (codeUnit >= 0x0100 && codeUnit <= 0x017F) || // Latin Extended-A
      (codeUnit >= 0x0400 && codeUnit <= 0x04FF) || // Cyrillic
      (codeUnit >= 0x0370 && codeUnit <= 0x03FF) || // Greek and Coptic
      (codeUnit >= 0x0590 && codeUnit <= 0x05FF) || // Hebrew
      (codeUnit >= 0x0600 && codeUnit <= 0x06FF) || // Arabic
      (codeUnit >= 0x0900 && codeUnit <= 0x097F) || // Devanagari
      (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) || // CJK Unified Ideographs
      (codeUnit >= 0x3400 &&
          codeUnit <= 0x4DBF) || // CJK Unified Ideographs Extension A
      (codeUnit >= 0xAC00 && codeUnit <= 0xD7AF) || // Hangul Syllables
      (codeUnit >= 0x3040 && codeUnit <= 0x309F) || // Hiragana
      (codeUnit >= 0x30A0 && codeUnit <= 0x30FF); // Katakana
}

int countCharacters(String input) {
  if (input.isEmpty) return 0;

  int count = 0;
  bool inWord = false;

  // 使用codeUnits来遍历字符串
  for (int i = 0; i < input.length; i++) {
    int codeUnit = input.codeUnitAt(i);

    if (isChineseCharacter(codeUnit)) {
      // 如果是汉字，直接计数
      count += 1;
      inWord = false; // 退出单词状态
    } else if (isLetterOrDigit(codeUnit)) {
      if (!inWord) {
        // 新的单词开始
        count += 1;
        inWord = true;
      }
      // 如果已经在单词中，继续，不计数
    } else {
      // 其他字符（如标点、空格等），退出单词状态
      inWord = false;
    }
  }

  return count;
}
