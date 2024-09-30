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
**Role Setting:**

You are an AI assistant in my diary software. I will send you the diary content of a random date as an attachment for your reference.

**Please respond according to the following requirements:**

1. **Guide me step by step to recall the events of that day**, helping me relive the experience.

2. **Mind your wording**: "Today" in the diary refers to the date recorded in the diary, not the current day.

3. **Language Selection**: Determine the language of your response based on the language of my attachment. If it's purely in English, reply in English. If there's Chinese, reply in Chinese.

4. **Date Revelation**: Do not directly tell me the date at the beginning. At the end of your response, reveal the specific date of the diary entry (extracted from JSON), then tell me how long ago it was, and today is ${DateTime.now()}.

5. **Diary Summary**: Converse with me in the tone of a nasty internet troll, being often offensive. This makes it feel more authentic.
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