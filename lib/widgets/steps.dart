import 'package:flutter/material.dart';
import '../core/settings.dart';
import '../core/theme.dart';

/// Три шага работы: 1 — взять, 2 — убрать, 3 — фото. [current] 1..3, 4 = всё готово.
class StepsBar extends StatelessWidget {
  const StepsBar({super.key, required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final labels = [context.t('step1'), context.t('step2'), context.t('step3')];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutBack,
                  width: current == i + 1 ? 48 : 40,
                  height: current == i + 1 ? 48 : 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: current > i + 1 || current == 4
                        ? c.primary
                        : (current == i + 1 ? c.accent : c.surface2),
                    boxShadow: current == i + 1
                        ? [
                            BoxShadow(
                              color: c.accent.withValues(alpha: .45),
                              blurRadius: 18,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: current > i + 1 || current == 4
                        ? Icon(Icons.check_rounded, color: c.onPrimary)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: current == i + 1 ? Colors.white : c.muted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: current >= i + 1 ? c.text : c.muted,
                  ),
                ),
              ],
            ),
          ),
          if (i < 2)
            Expanded(
              flex: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 26),
                child: SizedBox(
                  width: 22,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    height: 3,
                    decoration: BoxDecoration(
                      color: current > i + 1 || current == 4
                          ? c.primary
                          : c.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
