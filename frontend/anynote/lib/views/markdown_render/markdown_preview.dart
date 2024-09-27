import 'package:flutter/material.dart';

import 'markdown_render.dart';

class MarkdownPreview extends StatelessWidget {
  const MarkdownPreview({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: MarkdownRenderer(data: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
