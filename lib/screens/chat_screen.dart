import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/models_social.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

/// Чат махалли: те же сообщения, что и на сайте. Обновляется каждые 4 секунды.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ChatData? _data;
  String? _error;
  bool _sending = false;
  Timer? _timer;
  int _lastCount = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && context.auth.canChat) {
      _started = true;
      _refresh();
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final auth = context.auth;
    try {
      final d = await auth.api.chat();
      if (!mounted) return;
      final grew = d.messages.length != _lastCount;
      setState(() {
        _data = d;
        _error = null;
        _lastCount = d.messages.length;
      });
      if (grew) _toBottom();
    } on ApiException catch (e) {
      if (mounted && _data == null) setState(() => _error = e.code);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final auth = context.auth;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.api.sendChat(text);
      _input.clear();
      await _refresh();
      _toBottom();
    } on ApiException catch (e) {
      final k = 'err_${e.code}';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.t(k) == k ? context.t('err_generic') : context.t(k),
          ),
        ),
      );
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.auth;
    final top = MediaQuery.of(context).padding.top;

    if (!auth.canChat) {
      return EmptyState(
        icon: Icons.forum_outlined,
        title: context.t('login_needed_title'),
        hint: context.t('login_needed_text'),
        action: PrimaryButton(
          label: context.t('sign_in'),
          icon: Icons.login_rounded,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      );
    }
    final d = _data;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: c.brand,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.forum_rounded, color: c.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.t('chat_title'),
                  style: context.tt.headlineMedium?.copyWith(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
        if (d?.pinned != null)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.push_pin_rounded, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d!.pinned!.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: d == null
              ? (_error != null
                    ? EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: context.t('err_network'),
                        action: PrimaryButton(
                          label: context.t('retry'),
                          icon: Icons.refresh_rounded,
                          onTap: _refresh,
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()))
              : d.messages.isEmpty
              ? EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: context.t('chat_empty'),
                )
              : ListView.builder(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: d.messages.length,
                  itemBuilder: (_, i) => _Bubble(
                    m: d.messages[i],
                    mine: d.messages[i].authorId == d.meId,
                  ),
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            6,
            16,
            MediaQuery.of(context).padding.bottom + 96,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: context.t('chat_hint'),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Pressable(
                onTap: _send,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: c.brand,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: .35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _sending
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: c.onPrimary,
                          ),
                        )
                      : Icon(Icons.send_rounded, color: c.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m, required this.mine});
  final ChatMsg m;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final chairman = m.role == 'CHAIRMAN';
    final time =
        '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          gradient: mine ? c.brand : null,
          color: mine ? null : c.surface,
          border: mine
              ? null
              : Border.all(
                  color: chairman
                      ? c.accent.withValues(alpha: .6)
                      : c.border.withValues(alpha: .7),
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 6),
            bottomRight: Radius.circular(mine ? 6 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chairman)
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: c.accent,
                    ),
                  if (chairman) const SizedBox(width: 4),
                  Text(
                    chairman
                        ? '${context.t('chat_chairman')}${(m.name ?? '').isEmpty ? '' : ' · ${m.name}'}'
                        : m.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: chairman ? c.accent : c.primary,
                    ),
                  ),
                ],
              ),
            if (!mine) const SizedBox(height: 3),
            Text(
              m.deleted ? '—' : m.body,
              style: TextStyle(
                height: 1.35,
                color: mine ? c.onPrimary : c.text,
                fontStyle: m.deleted ? FontStyle.italic : null,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: mine ? c.onPrimary.withValues(alpha: .75) : c.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
