// markdown_parser.dart
import 'package:anynote/GlobalConfig.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

      // 解析列表（包括待办事项、无序列表和有序列表）
      RegExp listExp =
          RegExp(r'^(\s*)(?:(-\s+\[( |x)\]\s+.*)|(-\s+.*)|(\d+\.\s+.*))');
      Match? listMatch = listExp.firstMatch(line);
      if (listMatch != null) {
        nodes.add(parseList(state, listExp));
        continue;
      }

      // 解析代码块
      if (line.trim().startsWith('```')) {
        String language = line.trim().substring(3).trim();
        state.index++;
        String code = '';
        while (state.index < state.lines.length &&
            !state.lines[state.index].trim().startsWith('```')) {
          code += '${state.lines[state.index]}\n';
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

  MarkdownNode parseList(ParserState state, RegExp listExp) {
    List<MarkdownNode> items = [];
    int baseIndent = getIndentLevel(state.lines[state.index], listExp);
    String? listType;

    while (state.index < state.lines.length) {
      String line = state.lines[state.index];
      Match? match = listExp.firstMatch(line);
      if (match == null) break;

      int currentIndent = match.group(1)!.length;
      if (currentIndent < baseIndent) break;

      String content;
      String type;
      bool? checked;
      String? numberStr;

      if (match.group(2) != null) {
        // Todo list item
        type = 'todo';
        checked = match.group(3) == 'x';
        content = match.group(2)!.substring(5).trim();
      } else if (match.group(4) != null) {
        // Unordered list item
        type = 'ul';
        content = match.group(4)!.substring(2).trim();
      } else if (match.group(5) != null) {
        // Ordered list item
        type = 'ol';
        String fullMatch = match.group(5)!; // e.g., '1. item text'
        int dotIndex = fullMatch.indexOf('.');
        numberStr = fullMatch.substring(0, dotIndex).trim(); // 提取序号
        content = fullMatch.substring(dotIndex + 1).trim(); // 提取内容
      } else {
        break;
      }

      // Set listType only once
      if (listType == null) {
        listType = type == 'todo' ? 'todo' : type;
      } else if (listType != (type == 'todo' ? 'todo' : type)) {
        // Different type detected, break to start a new list
        break;
      }

      state.index++;

      // Check for sublist
      List<MarkdownNode>? children;
      if (state.index < state.lines.length) {
        String nextLine = state.lines[state.index];
        Match? childMatch = listExp.firstMatch(nextLine);
        if (childMatch != null && childMatch.group(1)!.length > currentIndent) {
          children = [parseList(state, listExp)];
        }
      }

      items.add(MarkdownNode(
        type: '${type}_item', // Use item's own type
        content: {
          'text': content,
          'number': numberStr, // 将序号存储在内容中
          'children': children,
          if (type == 'todo') 'checked': checked,
        },
      ));
    }

    return MarkdownNode(
      type: listType ?? '',
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
  final int fontsize;
  late BuildContext _context;

  MarkdownRenderer({required this.data, this.fontsize = 12});

  @override
  Widget build(BuildContext context) {
    _context = context;
    MarkdownParser parser = MarkdownParser(data);
    List<MarkdownNode> nodes = parser.parse();

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        return _renderNode(nodes[index], level: 0);
      },
    );
  }

  Widget _renderNode(MarkdownNode node, {int level = 0}) {
    switch (node.type) {
      case 'header':
        int levelHeader = node.content['level'];
        String text = node.content['text'];
        Color color;
        switch (levelHeader) {
          case 1:
            color = Colors.red;
            break;
          case 2:
            color = Colors.orange;
            break;
          case 3:
            color = Colors.blue;
            break;
          case 4:
            color = Colors.blueAccent;
            break;
          default:
            color = Colors.black;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _renderStyledText(text,
              style: TextStyle(
                  fontSize: 9 * (2 - 0.1 * levelHeader),
                  fontWeight: FontWeight.bold,
                  color: color)),
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
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
      case 'image':
        String src = node.content['src'];
        String alt = node.content['alt'];
        return Align(
          alignment: Alignment.topLeft,
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
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        top: GlobalConfig.fontSize.toDouble() - 4, right: 5),
                    child: const Icon(
                      Icons.circle,
                      size: 5,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _renderInlineText(item.content['text']),
                        if (item.content['children'] != null)
                          ...item.content['children']!
                              .map((child) =>
                                  _renderNode(child, level: level + 1))
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
            children: items.map<Widget>((item) {
              String number = item.content['number'] ?? '1'; // 使用存储的序号
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.only(top: fontsize.toDouble(), right: 5),
                    child: Text(
                      '$number. ',
                      style: TextStyle(fontSize: fontsize.toDouble()),
                    ),
                  ), // 显示序号
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _renderInlineText(item.content['text']),
                        if (item.content['children'] != null)
                          ...item.content['children']!
                              .map((child) =>
                                  _renderNode(child, level: level + 1))
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
              bool checked = item.content['checked'] ?? false;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.only(top: fontsize.toDouble() - 4, right: 5),
                    child: Icon(
                      size: 16,
                      checked
                          ? Icons.check
                          : Icons.check_box_outline_blank_outlined,
                      color: checked ? Colors.green : Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 6,
                        ),
                        _renderInlineText(item.content['text']),
                        if (item.content['children'] != null)
                          ...item.content['children']!
                              .map((child) =>
                                  _renderNode(child, level: level + 1))
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
        return const SizedBox.shrink();
      case 'ul_item':
      case 'ol_item':
        // 列表项在 'ul' 和 'ol' 类型中已经处理，无需单独渲染
        return const SizedBox.shrink();
      case 'hr':
        return Divider(
          color: Colors.grey[400],
          thickness: 1.0,
          height: 20.0,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // 更新行内文本渲染，支持加粗、斜体、删除线和行内代码
  Widget _renderInlineText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(_context)
              .style
              .copyWith(color: Colors.grey[800], fontSize: fontsize.toDouble()),
          children: _getInlineSpans(text),
        ),
      ),
    );
  }

  // 处理标题中的行内样式
  Widget _renderStyledText(String text, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: RichText(
        text: TextSpan(
          style: style,
          children: _getInlineSpans(text),
        ),
      ),
    );
  }

  List<TextSpan> _getInlineSpans(String text) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(
        r'(\*\*\*)(.*?)\1|(___)(.*?)\3|(\*\*|__)(.*?)\5|(\*|_)(.*?)\7|(~~)(.*?)\9|(`)(.*?)\11|(#)([\u4e00-\u9fa5a-zA-Z0-9]+)');
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(3) != null) {
        // ___加粗___
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(5) != null) {
        // **加粗** 或 __加粗__
        spans.add(TextSpan(
          text: match.group(6),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(7) != null) {
        // *斜体* 或 _斜体_
        spans.add(TextSpan(
          text: match.group(8),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(9) != null) {
        // ~~删除线~~
        spans.add(TextSpan(
          text: match.group(10),
          style: const TextStyle(
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
      } else if (match.group(13) != null) {
        spans.add(TextSpan(children: [
          WidgetSpan(
              child: Container(
            decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: (BorderRadius.all(Radius.circular(5)))),
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bookmark_outline_outlined,
                  size: 15,
                  color: Colors.white,
                ),
                Text(
                  match.group(14) ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                )
              ],
            ),
          )),
        ]));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }
}
