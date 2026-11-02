import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import 'common.dart';

/// Выбор до [max] фото: «Камера» (снимок за снимком) или «Галерея» (несколько сразу).
/// Фото сжимаются на телефоне (до 1920 px, JPEG 85), чтобы не нагружать сервер.
class PhotoField extends StatefulWidget {
  const PhotoField({
    super.key,
    required this.files,
    required this.onChanged,
    this.max = 4,
  });
  final List<XFile> files;
  final ValueChanged<List<XFile>> onChanged;
  final int max;

  @override
  State<PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends State<PhotoField> {
  final _picker = ImagePicker();
  final _bytes = <String, Uint8List>{};
  bool _busy = false;

  int get _left => widget.max - widget.files.length;

  Future<void> _camera() async {
    if (_left <= 0) return;
    setState(() => _busy = true);
    try {
      final f = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (f != null) await _add([f]);
    } catch (_) {
      // отказ в доступе к камере и т.п. — молча возвращаемся
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _gallery() async {
    if (_left <= 0) return;
    setState(() => _busy = true);
    try {
      final list = await _picker.pickMultiImage(
        maxWidth: 1920,
        imageQuality: 85,
        limit: _left < 2 ? 2 : _left,
      );
      if (list.isNotEmpty) await _add(list.take(_left).toList());
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _add(List<XFile> list) async {
    for (final f in list) {
      _bytes[f.path] = await f.readAsBytes();
    }
    widget.onChanged([...widget.files, ...list]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SourceButton(
                icon: Icons.photo_camera_rounded,
                label: context.t('camera'),
                primary: true,
                enabled: _left > 0 && !_busy,
                onTap: _camera,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceButton(
                icon: Icons.photo_library_rounded,
                label: context.t('gallery'),
                primary: false,
                enabled: _left > 0 && !_busy,
                onTap: _gallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              context.t('photos_n', {
                'n': widget.files.length,
                'max': widget.max,
              }),
              style: TextStyle(
                color: c.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            if (_busy)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.primary,
                ),
              ),
            if (!_busy && _left <= 0)
              Text(
                context.t('photo_max'),
                style: TextStyle(
                  color: c.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
          ],
        ),
        if (widget.files.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.files.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final f = widget.files[i];
                final data = _bytes[f.path];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: data == null
                            ? Container(color: c.surface2)
                            : Image.memory(data, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          final l = [...widget.files]..removeAt(i);
                          _bytes.remove(f.path);
                          widget.onChanged(l);
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool primary, enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Pressable(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            gradient: primary ? c.brand : null,
            color: primary ? null : c.surface,
            borderRadius: BorderRadius.circular(22),
            border: primary ? null : Border.all(color: c.border),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: c.primary.withValues(alpha: .3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: primary ? c.onPrimary : c.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: primary ? c.onPrimary : c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
