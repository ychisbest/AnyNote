import 'dart:convert';
import 'dart:math';

import 'package:anynote/views/date_view.dart';
import 'package:anynote/views/markdown_render/markdown_render.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../AiHelper.dart';
import '../MainController.dart';

class Aimemo extends StatefulWidget {
  const Aimemo({super.key});

  @override
  State<Aimemo> createState() => _AimemoState();
}


class _AimemoState extends State<Aimemo> {

  TextEditingController? textEditingController= TextEditingController();
  MainController c = Get.find<MainController>();
  DateTime? date;

  @override
  void initState() {
    textEditingController!.addListener(updateText);
    super.initState();
    var items = c.groupMemosByDate(c.notes);
    var randomEntry = items[Random().nextInt(items.length)];
    date= randomEntry.key;
    Future.microtask((){
      ChatWithAI(textEditingController!,jsonEncode(randomEntry.value));
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    textEditingController!.dispose();
    textEditingController=null;
  }

  updateText(){
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recall"),),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Center(child: Text("🤖",style: TextStyle(fontSize: 90), ),),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MarkdownRenderer(data:textEditingController!.text),
            ),
            TextButton(onPressed: (){
              Get.to(()=>Browser(dateTime:date ,));

            }, child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Go to Date"),
            ))
          ],
        ),
      ),
    );
  }
}
