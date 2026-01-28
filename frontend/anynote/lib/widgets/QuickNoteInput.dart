import 'package:anynote/Extension.dart';
import 'package:anynote/GlobalConfig.dart';
import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/route_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class QuickNoteInput extends StatefulWidget {
  const QuickNoteInput({super.key, this.expand = false});

  final bool expand;

  @override
  State<QuickNoteInput> createState() => _QuickNoteInputState();
}

class _QuickNoteInputState extends State<QuickNoteInput>
    with WidgetsBindingObserver, RouteAware {
  final MainController c = Get.find<MainController>();
  final FocusNode _focusNode = FocusNode();
  late final MarkdownEditingController _controller;
  String _lastDraft = "";
  bool _canSend = false;
  bool _isSending = false;
  bool _hasText = false;
  bool _showKeyboardOnResume = false;
  bool _isRouteSubscribed = false;

  bool get _needsDelayedFocus =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _controller = MarkdownEditingController();
    _lastDraft = GlobalConfig.quickNoteDraft;
    _controller.text = _lastDraft;
    _canSend = _lastDraft.trim().isNotEmpty;
    _hasText = _lastDraft.isNotEmpty;
    _controller.addListener(_handleDraftChange);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_isRouteSubscribed && route is PageRoute) {
      routeObserver.subscribe(this, route);
      _isRouteSubscribed = true;
    }
  }

  @override
  void dispose() {
    if (_isRouteSubscribed) {
      routeObserver.unsubscribe(this);
      _isRouteSubscribed = false;
    }
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleDraftChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDraftChange() {
    final text = _controller.text;
    if (text != _lastDraft) {
      GlobalConfig.quickNoteDraft = text;
      _lastDraft = text;
    }

    final canSend = text.trim().isNotEmpty;
    final hasText = text.isNotEmpty;
    if ((canSend != _canSend || hasText != _hasText) && mounted) {
      setState(() {
        _canSend = canSend;
        _hasText = hasText;
      });
    }
  }

  Future<void> _send() async {
    if (!_canSend || _isSending) {
      return;
    }

    final content = _controller.text.trim();
    if (content.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });
    c.exitSelectionMode();

    final newNote = NoteItem(
      content: content,
      createTime: DateTime.now(),
      index: 0,
    );
    final addedNote = await c.addNote(newNote);

    if (!mounted) return;
    if (addedNote.id == null) {
      setState(() {
        _isSending = false;
      });
      return;
    }
    _controller.clear();
    GlobalConfig.quickNoteDraft = "";
    _lastDraft = "";
    setState(() {
      _canSend = false;
      _isSending = false;
      _hasText = false;
    });
    _requestFocus();
  }

  void _clear() {
    _controller.clear();
    GlobalConfig.quickNoteDraft = "";
    _lastDraft = "";
    if (mounted) {
      setState(() {
        _canSend = false;
        _hasText = false;
      });
    }
    _requestFocus();
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) {
        return;
      }

      FocusScope.of(context).requestFocus(_focusNode);
      if (_needsDelayedFocus) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (!mounted) {
            return;
          }
          FocusScope.of(context).requestFocus(_focusNode);
          SystemChannels.textInput.invokeMethod('TextInput.show');
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _showKeyboardOnResume = _focusNode.hasFocus;
      return;
    }
    if (state == AppLifecycleState.resumed && _showKeyboardOnResume) {
      _showKeyboardOnResume = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        FocusScope.of(context).requestFocus(_focusNode);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      });
    }
  }

  @override
  void didPushNext() {
    _showKeyboardOnResume = false;
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool enableCtrlEnter =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final Map<LogicalKeySet, Intent> shortcuts = enableCtrlEnter
        ? <LogicalKeySet, Intent>{
            LogicalKeySet(
              LogicalKeyboardKey.control,
              LogicalKeyboardKey.enter,
            ): const ActivateIntent(),
            LogicalKeySet(
              LogicalKeyboardKey.control,
              LogicalKeyboardKey.numpadEnter,
            ): const ActivateIntent(),
          }
        : const <LogicalKeySet, Intent>{};
    return Container(
      margin: widget.expand?null:EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE6DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(builder: (context) {
            final inputField = Shortcuts(
              shortcuts: shortcuts,
              child: Actions(
                actions: <Type, Action<Intent>>{
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (intent) {
                      _send();
                      return null;
                    },
                  ),
                },
                child: widget.expand
                    ? TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        expands: true,
                        maxLines: null,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: GlobalConfig.fontSize.toDouble(),
                          height: 1.8,
                        ),
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                      )
                    : TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 3,
                        maxLines: 8,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: GlobalConfig.fontSize.toDouble(),
                          height: 1.8,
                        ),
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                      ),
              ),
            );
            return widget.expand ? Expanded(child: inputField) : inputField;
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _hasText ? _clear : null,
                child: const Text("Clear"),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _canSend ? _send : null,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text("Send"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
