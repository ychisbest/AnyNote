// markdown_parser.dart
import 'package:flutter/material.dart';

class MarkdownNode {
  final String type;
  final dynamic content;

  MarkdownNode({required this.type, required this.content});
}

class ParserState {
  final List<String> lines;
  int index;

  ParserState(this.lines) : index = 0;
}

class MarkdownParser {
  final String data;

  MarkdownParser(this.data);

  List<MarkdownNode> parse() {
    ParserState state = ParserState(data.split('\n'));
    List<MarkdownNode> nodes = [];

    while (state.index < state.lines.length) {
      String line = state.lines[state.index];

      // 忽略空行
      if (line.trim().isEmpty) {
        nodes.add(MarkdownNode(type: 'paragraph', content: ""));
        state.index++;
        continue;
      }

      // 解析分割线
      if (line.trim() == '---') {
        nodes.add(MarkdownNode(type: 'hr', content: null));
        state.index++;
        continue;
      }

      // 解析标题
      RegExp headerExp = RegExp(r'^(#{1,6})\s+(.*)');
      Match? headerMatch = headerExp.firstMatch(line);
      if (headerMatch != null) {
        int level = headerMatch.group(1)!.length;
        String text = headerMatch.group(2)!;
        nodes.add(MarkdownNode(
          type: 'header',
          content: {'level': level, 'text': text},
        ));
        state.index++;
        continue;
      }

      // 解析待办事项（任务列表）
      RegExp todoExp = RegExp(r'^(\s*)-\s+\[( |x)\]\s+(.*)');
      Match? todoMatch = todoExp.firstMatch(line);
      if (todoMatch != null) {
        nodes.add(parseList(state, todoExp, 'todo'));
        continue;
      }

      // 解析无序列表
      RegExp ulExp = RegExp(r'^(\s*)-\s+(.*)');
      Match? ulMatch = ulExp.firstMatch(line);
      if (ulMatch != null) {
        nodes.add(parseList(state, ulExp, 'ul'));
        continue;
      }

      // 解析有序列表
      RegExp olExp = RegExp(r'^(\s*)\d+\.\s+(.*)');
      Match? olMatch = olExp.firstMatch(line);
      if (olMatch != null) {
        nodes.add(parseList(state, olExp, 'ol'));
        continue;
      }

      // 解析代码块
      if (line.trim().startsWith('```')) {
        String language = line.trim().substring(3).trim();
        state.index++;
        String code = '';
        while (state.index < state.lines.length && !state.lines[state.index].trim().startsWith('```')) {
          code += state.lines[state.index] + '\n';
          state.index++;
        }
        state.index++; // 跳过结束的 ```
        nodes.add(MarkdownNode(
          type: 'code',
          content: {'language': language, 'code': code.trim()},
        ));
        continue;
      }

      // 解析图片
      RegExp imageExp = RegExp(r'^!\[(.*?)\]\((.*?)\)');
      Match? imageMatch = imageExp.firstMatch(line.trim());
      if (imageMatch != null) {
        String alt = imageMatch.group(1)!;
        String src = imageMatch.group(2)!;
        nodes.add(MarkdownNode(
          type: 'image',
          content: {'alt': alt, 'src': src},
        ));
        state.index++;
        continue;
      }

      // 解析段落
      nodes.add(MarkdownNode(type: 'paragraph', content: line.trim()));
      state.index++;
    }

    return nodes;
  }

  MarkdownNode parseList(ParserState state, RegExp listExp, String type) {
    List<MarkdownNode> items = [];
    int baseIndent = getIndentLevel(state.lines[state.index], listExp);

    while (state.index < state.lines.length) {
      String line = state.lines[state.index];
      Match? match = listExp.firstMatch(line);
      if (match == null) break;

      int currentIndent = match.group(1)!.length;
      if (currentIndent < baseIndent) break;

      String content;
      bool isTodo = false;
      bool checked = false;

      if (type == 'todo') {
        checked = match.group(2)! == 'x';
        content = match.group(3)!;
        isTodo = true;
      } else {
        content = match.group(2)!;
      }

      state.index++;

      // 检查是否有子列表
      List<MarkdownNode>? children;
      if (state.index < state.lines.length) {
        String nextLine = state.lines[state.index];
        Match? childMatch;
        if (type == 'todo') {
          childMatch = listExp.firstMatch(nextLine);
          // 特殊处理待办事项的子列表
          RegExp subListExp = RegExp(r'^(\s{2,})-\s+\[( |x)\]\s+(.*)');
          Match? subMatch = subListExp.firstMatch(nextLine);
          if (subMatch != null && subMatch.group(1)!.length > currentIndent) {
            children = [parseList(state, subListExp, 'todo')];
          }
        } else {
          childMatch = listExp.firstMatch(nextLine);
          RegExp subListExp;
          if (type == 'ul') {
            subListExp = RegExp(r'^(\s{2,})-\s+(.*)');
          } else {
            subListExp = RegExp(r'^(\s{2,})\d+\.\s+(.*)');
          }
          Match? subMatch = subListExp.firstMatch(nextLine);
          if (subMatch != null && subMatch.group(1)!.length > currentIndent) {
            children = [parseList(state, subListExp, type)];
          }
        }
      }

      if (type == 'todo') {
        items.add(MarkdownNode(
          type: 'todo_item',
          content: {
            'checked': checked,
            'text': content,
            'children': children,
          },
        ));
      } else {
        items.add(MarkdownNode(
          type: '${type}_item',
          content: {
            'text': content,
            'children': children,
          },
        ));
      }
    }

    return MarkdownNode(
      type: type,
      content: items,
    );
  }

  int getIndentLevel(String line, RegExp listExp) {
    Match? match = listExp.firstMatch(line);
    if (match != null) {
      return match.group(1)!.length;
    }
    return 0;
  }
}




class MarkdownRenderer extends StatelessWidget {
  final String data;

  late BuildContext _context;

  MarkdownRenderer({required this.data});

  @override
  Widget build(BuildContext context) {
    _context = context;
    MarkdownParser parser = MarkdownParser(data);
    List<MarkdownNode> nodes = parser.parse();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: nodes.map((node) => _renderNode(node, level: 0)).toList(),
      ),
    );
  }

  Widget _renderNode(MarkdownNode node, {int level = 0}) {
    switch (node.type) {
      case 'header':
        int levelHeader = node.content['level'];
        String text = node.content['text'];
        double fontSize;
        switch (levelHeader) {
          case 1:
            fontSize = 32;
            break;
          case 2:
            fontSize = 28;
            break;
          case 3:
            fontSize = 24;
            break;
          case 4:
            fontSize = 20;
            break;
          case 5:
            fontSize = 16;
            break;
          default:
            fontSize = 14;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _renderStyledText(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'paragraph':
        String text = node.content;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          child: _renderInlineText(text),
        );
      case 'code':
        String code = node.content['code'];
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: EdgeInsets.all(8.0),
          margin: EdgeInsets.symmetric(vertical: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
      case 'image':
        String src = node.content['src'];
        String alt = node.content['alt'];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Image.network(
            src,
            errorBuilder: (context, error, stackTrace) {
              return Text('![${alt}](${src})');
            },
          ),
        );
      case 'ul':
        List<MarkdownNode> items = node.content;
        return Padding(
          padding: EdgeInsets.only(left: level * 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map<Widget>((item) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• '),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _renderInlineText(item.content['text']),
                        if (item.content['children'] != null)
                          ...item.content['children']!
                              .map((child) => _renderNode(child, level: level + 1))
                              .toList(),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      case 'ol':
        List<MarkdownNode> items = node.content;
        return Padding(
          padding: EdgeInsets.only(left: level * 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.asMap().entries.map<Widget>((entry) {
              int idx = entry.key + 1;
              MarkdownNode item = entry.value;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$idx. '),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _renderInlineText(item.content['text']),
                        if (item.content['children'] != null)
                          ...item.content['children']!
                              .map((child) => _renderNode(child, level: level + 1))
                              .toList(),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      case 'todo':
        List<MarkdownNode> items = node.content;
        return Padding(
          padding: EdgeInsets.only(left: level * 16.0),
          child: Column(
            children: items.map<Widget>((item) {
              bool checked = item.content['checked'];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: null, // 禁用点击事件
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6,),
                        _renderInlineText(item.content['text']),
                        if (item.content['children'] != null)
                          ...item.content['children']!
                              .map((child) => _renderNode(child, level: level + 1))
                              .toList(),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      case 'todo_item':
      // 待办事项项在 'todo' 类型中已经处理，无需单独渲染
        return SizedBox.shrink();
      case 'ul_item':
      case 'ol_item':
      // 列表项在 'ul' 和 'ol' 类型中已经处理，无需单独渲染
        return SizedBox.shrink();
      case 'hr':
        return Divider(
          color: Colors.grey[400],
          thickness: 1.0,
          height: 20.0,
        );
      default:
        return SizedBox.shrink();
    }
  }

  // 更新行内文本渲染，支持加粗、斜体、删除线和行内代码
  Widget _renderInlineText(String text) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(_context).style.copyWith(color: Colors.black),
        children: _getInlineSpans(text),
      ),
    );
  }

  // 处理标题中的行内样式
  Widget _renderStyledText(String text, {TextStyle? style}) {
    return RichText(
      text: TextSpan(
        style: style?.copyWith(color: Colors.black),
        children: _getInlineSpans(text),
      ),
    );
  }

  List<TextSpan> _getInlineSpans(String text) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(
        r'(\*\*\*)(.*?)\1|(___)(.*?)\3|(\*\*|__)(.*?)\5|(\*|_)(.*?)\7|(~~)(.*?)\9|(`)(.*?)\11');
    int start = 0;

    Iterable<Match> matches = exp.allMatches(text);
    for (Match match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      if (match.group(1) != null) {
        // ***加粗斜体***
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(3) != null) {
        // ___加粗___
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(5) != null) {
        // **加粗** 或 __加粗__
        spans.add(TextSpan(
          text: match.group(6),
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(7) != null) {
        // *斜体* 或 _斜体_
        spans.add(TextSpan(
          text: match.group(8),
          style: TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(9) != null) {
        // ~~删除线~~
        spans.add(TextSpan(
          text: match.group(10),
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
          ),
        ));
      } else if (match.group(11) != null) {
        // `行内代码`
        spans.add(TextSpan(
          text: match.group(12),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey[200],
          ),
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }
}