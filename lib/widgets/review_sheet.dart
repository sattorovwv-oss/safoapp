import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../screens/login_screen.dart';
import 'common.dart';

/// Лист «Написать отзыв»: звёзды + текст. Для гостя сначала предлагает войти.
Future<bool> showReviewSheet(BuildContext context, Place place) async {
  if (context.auth.user == null) {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (!context.mounted || context.auth.user == null) return false;
  }
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewSheet(place: place),
  );
  return ok == true;
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.place});
  final Place place;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.auth;
    try {
      await auth.api.postReview(widget.place.id, _rating, _text.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('review_thanks'))));
      Navigator.of(context).pop(true);
      return;
    } on ApiException catch (e) {
      final k = 'err_${e.code}';
      if (mounted)
        setState(
          () => _error = context.t(k) == k
              ? context.t('err_generic')
              : context.t(k),
        );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.place.nameOf(context.app.lang),
            style: context.tt.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            context.t('your_rating'),
            style: TextStyle(color: c.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _rating = i),
                  child: AnimatedScale(
                    scale: i <= _rating ? 1.12 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        i <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 46,
                        color: i <= _rating ? c.accent : c.border,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(hintText: context.t('review_hint')),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: c.danger, fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _busy ? '…' : context.t('review_send'),
              icon: Icons.send_rounded,
              onTap: () => _busy ? null : _send(),
            ),
          ),
        ],
      ),
    );
  }
}
