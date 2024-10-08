import 'dart:convert';
import 'dart:async';
import 'package:anynote/GlobalConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

Future<void> continueTheText(TextEditingController controller) async {
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
            "content": """
You are an AI assistant embedded in my note-taking software. I will send you the note content as an attachment for reference. Please respond according to the following rules:
- No unnecessary polite language or filler words; my time is valuable.
- Determine the language of your response based on the language of my question and the attachment.
- Provide detailed technical answers; I enjoy deep thinking.
        """,
            "role": "system"
          },
          {
            "role": "user",
            "content": """
          attachment:
          ```
          $fullText
          ```
          here is my question,reply me in my question's language：
          $todo
          """
          }
        ],
        "stream": true
      });


    final streamedResponse = await client.send(request).timeout(
      const Duration(seconds: 5),
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
    Get.snackbar('Error', e.toString());
    return;
  }
}


Future<void> ChatWithAI(TextEditingController controller,String content) async {
  try {

    print(content);

    String apiKey = GlobalConfig.aiApiKey;

    final client = http.Client();

    final request = http.Request('POST', Uri.parse(GlobalConfig.aiUrl))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..body = jsonEncode({
        "model": GlobalConfig.aiModel,
        "messages": [
          {
            "content": """
> **角色设定：**
>
> 你是一位贴心的回忆助手，擅长通过有限的信息帮助我回想起过去的日记内容。你的目标是引导我重新体验当时的情绪、思考和细节。
>
> **任务说明：**
>
> - 我将提供一篇随机的日记。
> - 不要告诉我日记的日期。
> - 基于这些信息，请你**详细描述**我可能在日记中记录的事件、情感和反思。
> - 提供**丰富的细节**，包括可能的环境描写、人物互动和内心感受。
> - **提出引导性问题**，帮助我更深入地回忆和思考。
> - 使用**温暖而富有同理心的语言**，使回忆过程更加愉悦和有启发性。
> - 最后为我揭示日记的日期，日期为json的createtime字段。并告诉我距今多久了，今天是${DateTime.now()}。
> - 使用生动而富有感染力的语言，使回忆过程更加深刻和有启发性。
>
> **注意事项：**
>
> - 不要引入与提供信息无关的内容。
> - 尊重我的隐私，不涉及可能引起不适的主题。

        """,
            "role": "system"
          },
          {
            "role": "user",
            "content": """
attachment
---
$content
---
          """
          }
        ],
        "stream": true
      });


    final streamedResponse = await client.send(request).timeout(
      const Duration(seconds: 5),
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
          if(controller==null){
            return;
          }
          if (text != null) {
            controller.text += text;
          }
        }
      }
    } else {
      // 处理请求失败的情况
    }
  } catch (e) {
    Get.snackbar('Error', e.toString());
    return;
  }
}