import 'dart:convert';
import 'dart:async';
import 'package:anynote/GlobalConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

Future<void> SendMessage(TextEditingController controller) async {
  try {
    String fullText = controller.text;
    String todo = '';
    String apiKey = GlobalConfig.aiApiKey;
    var selection = controller.selection;
    int insertPosition = selection.end;

    // 获取选中的文本
    if (selection.start != selection.end) {
      todo = controller.text.substring(selection.start, selection.end);
    } else {
      // 获取光标当前行的文本
      int currentLineStart =
          controller.text.lastIndexOf('\n', selection.start - 1) + 1;
      int currentLineEnd = controller.text.indexOf('\n', selection.start);
      if (currentLineEnd == -1) {
        currentLineEnd = controller.text.length;
      }
      todo = controller.text.substring(currentLineStart, currentLineEnd).trim();

      // 如果当前行为空，则使用上一行的文本
      if (todo.isEmpty && currentLineStart > 0) {
        int previousLineStart =
            controller.text.lastIndexOf('\n', currentLineStart - 2) + 1;
        int previousLineEnd = currentLineStart - 1;
        todo = controller.text
            .substring(previousLineStart, previousLineEnd)
            .trim();
      }
    }

    // 找到当前行的结束位置
    int currentLineEnd = controller.text.indexOf('\n', insertPosition);
    if (currentLineEnd == -1) {
      currentLineEnd = controller.text.length;
    }

    // 在当前行末尾插入换行符
    String newText =
        '${controller.text.substring(0, currentLineEnd)}\n${controller.text.substring(currentLineEnd)}';
    controller.text = newText;
    insertPosition = currentLineEnd + 1;

    final client = http.Client();
    final request = http.Request('POST', Uri.parse(GlobalConfig.aiUrl))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..body = jsonEncode({
        "model": GlobalConfig.aiModel,
        "messages": [
          {
            "content": """你是我嵌入笔记软件中的ai助手，我会把笔记内容当作附件发送给你作为参考。回复请按照以下规则。
        - 不需要多余的礼貌性用语和废话，我的精力很宝贵。
        - 使用中文回复。
        - 回答技术细节请尽量详细，我喜欢深度思考。
        """,
            "role": "system"
          },
          {
            "role": "user",
            "content": """
          附件:
          ```
          $fullText
          ```
          现在回答我的问题：
          $todo
          """
          }
        ],
        "stream": true
      });

    final streamedResponse = await client.send(request).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('The request timed out');
      },
    );

    if (streamedResponse.statusCode == 200) {
      final stream = streamedResponse.stream;
      final lines =
          stream.transform(utf8.decoder).transform(const LineSplitter());

      await for (var line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;
          final jsonData = jsonDecode(data);
          final text = jsonData['choices'][0]['delta']['content'];
          if (text != null) {
            newText = controller.text.substring(0, insertPosition) +
                text +
                controller.text.substring(insertPosition);
            controller.text = newText;
            insertPosition += text.toString().length;
            controller.selection =
                TextSelection.collapsed(offset: insertPosition);
          }
        }
      }
    } else {
      // 处理请求失败的情况
    }
  } catch (e) {
    Get.snackbar('错误', e.toString());
    return;
  }
}
