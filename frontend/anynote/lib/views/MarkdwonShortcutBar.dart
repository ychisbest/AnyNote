import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MarkdownShortcutBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function? onAiTap;

  const MarkdownShortcutBar({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.onAiTap,
  }) : super(key: key);

  @override
  _MarkdownShortcutBarState createState() => _MarkdownShortcutBarState();
}

class _MarkdownShortcutBarState extends State<MarkdownShortcutBar> {
  final List<String> _undoHistory = [];
  final List<String> _redoHistory = [];
  bool _canUndo = false;
  bool _canRedo = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    final currentText = widget.controller.text;
    if (_undoHistory.isEmpty || _undoHistory.last != currentText) {
      _undoHistory.add(currentText);
      _redoHistory.clear();
      _updateUndoRedoState();
    }
  }

  void _updateUndoRedoState() {
    setState(() {
      _canUndo = _undoHistory.length > 1;
      _canRedo = _redoHistory.isNotEmpty;
    });
  }

  void _undo() {
    if (_undoHistory.length > 1) {
      _redoHistory.add(_undoHistory.removeLast());
      final previousText = _undoHistory.last;
      widget.controller.value = TextEditingValue(
        text: previousText,
        selection: TextSelection.collapsed(offset: previousText.length),
      );
      _updateUndoRedoState();
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      final nextText = _redoHistory.removeLast();
      _undoHistory.add(nextText);
      widget.controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
      _updateUndoRedoState();
    }
  }

  void _toggleMarkdown(String opening, String closing) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final selectedText = selection.textInside(text);

    String newText;
    int newSelectionStart = selection.start;
    int newSelectionEnd = selection.end;

    if (selectedText.isEmpty) {
      newText = '$opening$closing';
      newSelectionStart += opening.length;
      newSelectionEnd = newSelectionStart;
    } else if (selectedText.startsWith(opening) &&
        selectedText.endsWith(closing)) {
      newText = selectedText.substring(
          opening.length, selectedText.length - closing.length);
      newSelectionEnd = newSelectionStart + newText.length;
    } else {
      newText = '$opening$selectedText$closing';
      newSelectionEnd = newSelectionStart + newText.length;
    }

    _replaceTextWithNewSelection(
        newText, selection, newSelectionStart, newSelectionEnd);
  }

  void _replaceTextWithNewSelection(String newText, TextSelection selection,
      int newSelectionStart, int newSelectionEnd) {
    final text = widget.controller.text;
    final newValue = TextEditingValue(
      text: text.replaceRange(selection.start, selection.end, newText),
      selection: TextSelection(
        baseOffset: newSelectionStart,
        extentOffset: newSelectionEnd,
      ),
    );
    widget.controller.value = newValue;
    widget.focusNode.requestFocus();
  }

  void _replaceText(String newText, TextSelection selection) {
    final text = widget.controller.text;
    final newValue = TextEditingValue(
      text: text.replaceRange(selection.start, selection.end, newText),
      selection:
          TextSelection.collapsed(offset: selection.start + newText.length),
    );
    widget.controller.value = newValue;
    widget.focusNode.requestFocus();
  }

  void _toggleList() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final lineStart =
        text.isEmpty ? 0 : text.lastIndexOf('\n', selection.start - 1) + 1;
    final lineEnd = text.indexOf('\n', selection.end);
    final line = text.substring(lineStart, lineEnd == -1 ? null : lineEnd);

    String newLine;

    var res = line.trimLeft().replaceFirst(RegExp(r'^- \[([ x])\] '), '');

    if (res.startsWith('- ')) {
      newLine = line.substring(2);
    } else {
      newLine = '- $res';
    }

    _replaceText(
        newLine,
        TextSelection(
            baseOffset: lineStart,
            extentOffset: lineEnd == -1 ? text.length : lineEnd));
  }

  void _toggleCheckbox() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final lineStart =
        text.isEmpty ? 0 : text.lastIndexOf('\n', selection.start - 1) + 1;
    final lineEnd = text.indexOf('\n', selection.end);
    final line = text.substring(lineStart, lineEnd == -1 ? null : lineEnd);

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

    _replaceText(
        newLine,
        TextSelection(
            baseOffset: lineStart,
            extentOffset: lineEnd == -1 ? text.length : lineEnd));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(
          height: 1,
          color: Colors.black12,
        ),
        SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconButton(Icons.undo, _undo, isEnable: _canUndo),
                _buildIconButton(Icons.redo, _redo, isEnable: _canRedo),
                _buildIconButton(
                    Icons.format_bold, () => _toggleMarkdown('**', '**')),
                _buildIconButton(
                    Icons.format_italic, () => _toggleMarkdown('*', '*')),
                _buildIconButton(Icons.format_strikethrough,
                    () => _toggleMarkdown('~~', '~~')),
                // _buildIconButton(Icons.code, () => _toggleMarkdown('`', '`')),
                _buildIconButton(Icons.format_list_bulleted, _toggleList),
                _buildIconButton(Icons.check_box_outlined, _toggleCheckbox),
                if (widget.onAiTap != null)
                  _buildIconButton(Icons.generating_tokens_outlined, () {
                    widget.onAiTap!.call();
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed,
      {bool isEnable = true}) {
    return IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: isEnable ? Colors.black : Colors.black12,
      ),
      onPressed: isEnable ? onPressed : null,
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
