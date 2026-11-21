import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/cars.dart';
import '../core/hotels.dart' show HPhoto;
import '../core/settings.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

const _s = <String, Map<String, String>>{
  'tg': {
    'title': 'Иҷораи мошинҳо',
    'lede': 'Мошинҳои ҳамкори Сафо: аксҳо, категория ва тамоси мустақим.',
    'search': 'Ҷустуҷӯ аз рӯи номи мошин',
    'all': 'Ҳама',
    'day': 'шабонарӯз',
    'price_ask': 'Нарх бо дархост',
    'order': 'Фармоиш',
    'about': 'Дар бораи мошин',
    'terms': 'Шартҳои иҷора',
    'age': 'Синну сол: аз 21 боло',
    'docs': 'Ҳуҷҷатҳо: шиноснома + гувоҳномаи ронандагӣ (категорияи B)',
    'exp': 'Таҷрибаи ронандагӣ: на камтар аз 1 сол',
    'deposit': 'Гарав: 1000 сомонӣ',
    'terms_note': 'Санаҳо ва ҷои супоридани мошин бевосита бо ширкат ҳамоҳанг карда мешаванд.',
    'book_title': 'Фармоиши мошин',
    'dates': 'Санаҳо',
    'pick_dates': 'Санаҳоро интихоб кунед',
    'days': '{n} рӯз',
    'about_sum': 'тақрибан {sum}',
    'name': 'Номи шумо',
    'phone': 'Телефон / WhatsApp',
    'comment': 'Хоҳишҳо (ихтиёрӣ)',
    'send': 'Фиристодани дархост',
    'sent_title': 'Дархост фиристода шуд',
    'sent_text': 'Мо бо шумо ба зудӣ тамос мегирем. Барои тезтар метавонед худатон дар WhatsApp нависед.',
    'note': 'Дархост бронкунии тасдиқшуда нест: санаҳо, нарх ва шартҳоро бо ширкат ҳамоҳанг мекунед.',
    'or_now': 'Ё фавран:',
    'call': 'Занг задан',
    'empty': 'Ҳоло мошин нест',
    'nothing': 'Чизе ёфт нашуд',
    'closed': 'Бахш навсозӣ мешавад. Лутфан, баъдтар баргардед.',
    'retry': 'Аз нав',
    'err_network': 'Интернет нест ё сервер ҷавоб намедиҳад.',
    'err_generic': 'Хато шуд. Маълумотро санҷед ва аз нав кӯшиш кунед.',
    'err_rate': 'Хеле зиёд. Каме интизор шавед.',
    'wa_text': 'Салом! Мехоҳам «{car}»-ро иҷора гирам.',
  },
  'ru': {
    'title': 'Аренда авто',
    'lede': 'Машины партнёров Сафо: фото, категория и прямой контакт.',
    'search': 'Поиск по названию авто',
    'all': 'Все',
    'day': 'сутки',
    'price_ask': 'Цена по запросу',
    'order': 'Заказать',
    'about': 'О машине',
    'terms': 'Условия аренды',
    'age': 'Возраст: старше 21 года',
    'docs': 'Документы: паспорт + права категории B',
    'exp': 'Стаж вождения: не менее 1 года',
    'deposit': 'Залог: 1000 сомони',
    'terms_note': 'Даты и место выдачи машины вы согласуете напрямую с компанией.',
    'book_title': 'Заказать машину',
    'dates': 'Даты',
    'pick_dates': 'Выберите даты',
    'days': '{n} дн.',
    'about_sum': 'примерно {sum}',
    'name': 'Ваше имя',
    'phone': 'Телефон / WhatsApp',
    'comment': 'Пожелания (необязательно)',
    'send': 'Отправить заявку',
    'sent_title': 'Заявка отправлена',
    'sent_text': 'Мы свяжемся с вами в ближайшее время. Чтобы быстрее, можете сами написать в WhatsApp.',
    'note': 'Заявка не является подтверждённым бронированием: даты, цену и условия вы согласуете с компанией.',
    'or_now': 'Или сразу:',
    'call': 'Позвонить',
    'empty': 'Машин пока нет',
    'nothing': 'Ничего не найдено',
    'closed': 'Раздел обновляется. Пожалуйста, загляните позже.',
    'retry': 'Повторить',
    'err_network': 'Нет интернета или сервер не отвечает.',
    'err_generic': 'Ошибка. Проверьте данные и попробуйте ещё раз.',
    'err_rate': 'Слишком часто. Немного подождите.',
    'wa_text': 'Здравствуйте! Хочу арендовать «{car}».',
  },
  'en': {
    'title': 'Car rental',
    'lede': 'Safo partner cars: photos, category and direct contact.',
    'search': 'Search by car name',
    'all': 'All',
    'day': 'day',
    'price_ask': 'Price on request',
    'order': 'Book',
    'about': 'About the car',
    'terms': 'Rental terms',
    'age': 'Age: over 21',
    'docs': "Documents: passport + driver's licence (category B)",
    'exp': 'Driving experience: at least 1 year',
    'deposit': 'Deposit: 1000 TJS',
    'terms_note': 'Dates and the pick-up place are agreed directly with the company.',
    'book_title': 'Book this car',
    'dates': 'Dates',
    'pick_dates': 'Choose dates',
    'days': '{n} day(s)',
    'about_sum': 'about {sum}',
    'name': 'Your name',
    'phone': 'Phone / WhatsApp',
    'comment': 'Wishes (optional)',
    'send': 'Send request',
    'sent_title': 'Request sent',
    'sent_text': 'We will contact you shortly. To speed things up, you can message us on WhatsApp.',
    'note': 'A request is not a confirmed booking: you agree the dates, price and terms with the company.',
    'or_now': 'Or right away:',
    'call': 'Call',
    'empty': 'No cars yet',
    'nothing': 'Nothing found',
    'closed': 'This section is being updated. Please come back later.',
    'retry': 'Retry',
    'err_network': 'No internet or the server is not responding.',
    'err_generic': 'Something went wrong. Check the details and try again.',
    'err_rate': 'Too many requests. Please wait a little.',
    'wa_text': 'Hello! I would like to rent the “{car}”.',
  },
};

extension _CX on BuildContext {
  String k(String key, [Map<String, Object>? p]) {
    var s = _s[app.lang]?[key] ?? _s['ru']![key] ?? key;
    p?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }
}

String _money(int n, String lang) {
  final d = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write(' ');
    b.write(d[i]);
  }
  final sym = lang == 'tg' ? 'сомонӣ' : (lang == 'en' ? 'TJS' : 'сомони');
  return lang == 'en' ? '$sym $b' : '$b $sym';
}

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

Future<void> _open(String url) async {
  final u = Uri.parse(url);
  if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
}

String _errText(BuildContext context, Object e) {
  if (e is ApiException) {
    if (e.code == 'network') return context.k('err_network');
    if (e.code == 'rate_limited') return context.k('err_rate');
    if (e.code == 'section_closed') return context.k('closed');
  }
  return context.k('err_generic');
}

// ---------------------------------------------------------------------------
// Список машин
// ---------------------------------------------------------------------------

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  CarsList? _data;
  Object? _error;
  String _q = '';
  String? _cat;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null && _error == null) _load();
  }

  Future<void> _load() async {
    try {
      final d = await CarsApi(context.app, context.store.api).list();
      if (mounted) {
        setState(() {
          _data = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final d = _data;
    final cats = d == null ? <String>[] : {for (final x in d.cars) if (x.category.isNotEmpty) x.category}.toList();
    final needle = _q.trim().toLowerCase();
    final shown = d == null
        ? <Car>[]
        : d.cars.where((x) => (_cat == null || x.category == _cat) && (needle.isEmpty || x.name.toLowerCase().contains(needle))).toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.k('title'), style: context.tt.titleLarge)),
      body: _error != null && d == null
          ? _Message(text: _errText(context, _error!), onRetry: () {
              setState(() => _error = null);
              _load();
            })
          : d == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: c.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Text(context.k('lede'), style: TextStyle(color: c.muted, height: 1.5)),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (v) => setState(() => _q = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: context.k('search')),
                  ),
                  if (cats.length > 1) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _Chip(label: context.k('all'), on: _cat == null, onTap: () => setState(() => _cat = null)),
                          for (final x in cats) _Chip(label: x, on: _cat == x, onTap: () => setState(() => _cat = _cat == x ? null : x)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: Text(context.k(d.cars.isEmpty ? 'empty' : 'nothing'), style: context.tt.titleMedium)),
                    ),
                  for (final car in shown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: CarCard(
                        car: car,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CarDetail(car: car, phone: d.phone, whatsapp: d.whatsapp)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: c.primary,
        labelStyle: TextStyle(color: on ? c.onPrimary : c.text, fontWeight: FontWeight.w600),
        backgroundColor: c.surface,
        side: BorderSide(color: on ? c.primary : c.border),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_rounded, size: 48, color: context.c.accent),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center, style: context.tt.titleMedium),
            const SizedBox(height: 18),
            PrimaryButton(label: context.k('retry'), icon: Icons.refresh_rounded, onTap: onRetry, outlined: true),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Карточка и фото
// ---------------------------------------------------------------------------

class _Photos extends StatefulWidget {
  const _Photos({required this.photos, required this.aspect, this.large = false});
  final List<HPhoto> photos;
  final double aspect;
  final bool large;

  @override
  State<_Photos> createState() => _PhotosState();
}

class _PhotosState extends State<_Photos> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final media = context.store.api.media;
    if (widget.photos.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.aspect,
        child: Container(color: const Color(0xFF0C3B2D), child: const Icon(Icons.directions_car_rounded, size: 56, color: Color(0xFFE3B155))),
      );
    }
    return AspectRatio(
      aspectRatio: widget.aspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: media(widget.large ? widget.photos[i].large : widget.photos[i].medium),
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: c.surface2),
              errorWidget: (_, _, _) => Container(color: c.surface2, child: Icon(Icons.broken_image_rounded, color: c.muted)),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var j = 0; j < widget.photos.length; j++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: j == _i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: j == _i ? .95 : .55), borderRadius: BorderRadius.circular(3)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class CarCard extends StatelessWidget {
  const CarCard({super.key, required this.car, required this.onTap});
  final Car car;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.app.lang;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _Photos(photos: car.photos, aspect: 4 / 3),
                if (car.category.isNotEmpty)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), borderRadius: BorderRadius.circular(99)),
                      child: Text(car.category.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.name, style: context.tt.headlineMedium),
                  if (car.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(car.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, height: 1.45)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: car.pricePerDay != null
                            ? Text.rich(TextSpan(children: [
                                TextSpan(text: _money(car.pricePerDay!, lang), style: context.tt.titleLarge),
                                TextSpan(text: ' / ${context.k('day')}', style: TextStyle(color: c.muted)),
                              ]))
                            : Text(context.k('price_ask'), style: TextStyle(color: c.muted)),
                      ),
                      FilledButton.icon(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary),
                        icon: const Icon(Icons.event_available_rounded, size: 18),
                        label: Text(context.k('order')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Страница машины
// ---------------------------------------------------------------------------

class CarDetail extends StatelessWidget {
  const CarDetail({super.key, required this.car, this.phone, this.whatsapp});
  final Car car;
  final String? phone, whatsapp;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.app.lang;
    final wa = whatsapp == null ? null : 'https://wa.me/${_digits(whatsapp!)}?text=${Uri.encodeComponent(context.k('wa_text', {'car': car.name}))}';
    return Scaffold(
      appBar: AppBar(title: Text(car.name, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          _Photos(photos: car.photos, aspect: 4 / 3, large: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (car.category.isNotEmpty)
                  Text(car.category.toUpperCase(), style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
                const SizedBox(height: 6),
                Text(car.name, style: context.tt.displaySmall),
                const SizedBox(height: 10),
                if (car.pricePerDay != null)
                  Text.rich(TextSpan(children: [
                    TextSpan(text: _money(car.pricePerDay!, lang), style: context.tt.headlineMedium),
                    TextSpan(text: ' / ${context.k('day')}', style: TextStyle(color: c.muted)),
                  ]))
                else
                  Text(context.k('price_ask'), style: TextStyle(color: c.muted)),
                if (car.description.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(context.k('about'), style: context.tt.titleLarge),
                  const SizedBox(height: 8),
                  Text(car.description, style: context.tt.bodyLarge),
                ],
                const SizedBox(height: 22),
                _Terms(),
                if (wa != null || phone != null) ...[
                  const SizedBox(height: 22),
                  Text(context.k('or_now'), style: TextStyle(color: c.muted)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (wa != null) OutlinedButton.icon(onPressed: () => _open(wa), icon: const Icon(Icons.chat_rounded), label: const Text('WhatsApp')),
                      if (phone != null)
                        OutlinedButton.icon(onPressed: () => _open('tel:${phone!.replaceAll(RegExp(r'[^\d+]'), '')}'), icon: const Icon(Icons.call_rounded), label: Text(context.k('call'))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: PrimaryButton(
            label: context.k('book_title'),
            icon: Icons.event_available_rounded,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: c.bg,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              builder: (_) => _BookSheet(car: car, whatsapp: wa),
            ),
          ),
        ),
      ),
    );
  }
}

class _Terms extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget row(IconData i, String key) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: c.accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
            child: Icon(i, size: 18, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(context.k(key), style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.k('terms'), style: context.tt.titleLarge),
          const SizedBox(height: 8),
          row(Icons.person_rounded, 'age'),
          row(Icons.badge_rounded, 'docs'),
          row(Icons.schedule_rounded, 'exp'),
          row(Icons.shield_rounded, 'deposit'),
          const SizedBox(height: 6),
          Text(context.k('terms_note'), style: TextStyle(color: c.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Заявка
// ---------------------------------------------------------------------------

class _BookSheet extends StatefulWidget {
  const _BookSheet({required this.car, this.whatsapp});
  final Car car;
  final String? whatsapp;

  @override
  State<_BookSheet> createState() => _BookSheetState();
}

class _BookSheetState extends State<_BookSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _comment = TextEditingController();
  late DateTimeRange _range;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = DateTime.now();
    final d = DateTime(t.year, t.month, t.day);
    _range = DateTimeRange(start: d.add(const Duration(days: 1)), end: d.add(const Duration(days: 3)));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _comment.dispose();
    super.dispose();
  }

  int get _days => _range.end.difference(_range.start).inDays;

  Future<void> _pick() async {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final r = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _range,
      saveText: context.k('dates'),
    );
    if (r != null && r.end.isAfter(r.start)) setState(() => _range = r);
  }

  Future<void> _send() async {
    if (_name.text.trim().length < 2 || _phone.text.trim().length < 6 || _days < 1) {
      setState(() => _error = context.k('err_generic'));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await CarsApi(context.app, context.store.api).book(
        widget.car.slug,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        from: _range.start,
        to: _range.end,
        comment: _comment.text,
      );
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = _errText(context, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.app.lang;
    String fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final price = widget.car.pricePerDay;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 44, height: 5, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(3))),
            ),
            const SizedBox(height: 16),
            Text(context.k('book_title'), style: context.tt.headlineMedium),
            Text(widget.car.name, style: TextStyle(color: c.muted)),
            const SizedBox(height: 18),
            if (_sent) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: c.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.check_circle_rounded, color: c.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(context.k('sent_title'), style: context.tt.titleLarge)),
                    ]),
                    const SizedBox(height: 8),
                    Text(context.k('sent_text'), style: const TextStyle(height: 1.5)),
                    if (widget.whatsapp != null) ...[
                      const SizedBox(height: 14),
                      PrimaryButton(label: 'WhatsApp', icon: Icons.chat_rounded, onTap: () => _open(widget.whatsapp!)),
                    ],
                  ],
                ),
              ),
            ] else ...[
              InkWell(
                onTap: _pick,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
                  child: Row(
                    children: [
                      Icon(Icons.date_range_rounded, color: c.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text('${fmt(_range.start)} — ${fmt(_range.end)}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(context.k('days', {'n': _days}), style: TextStyle(color: c.muted)),
                    ],
                  ),
                ),
              ),
              if (price != null) ...[
                const SizedBox(height: 8),
                Text(context.k('about_sum', {'sum': _money(price * _days, lang)}), style: TextStyle(color: c.muted)),
              ],
              const SizedBox(height: 12),
              TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(hintText: context.k('name'))),
              const SizedBox(height: 12),
              TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: context.k('phone'))),
              const SizedBox(height: 12),
              TextField(controller: _comment, maxLines: 2, maxLength: 500, decoration: InputDecoration(hintText: context.k('comment'), counterText: '')),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: c.danger, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 16),
              _sending
                  ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                  : PrimaryButton(label: context.k('send'), icon: Icons.send_rounded, onTap: _send),
              const SizedBox(height: 12),
              Text(context.k('note'), style: TextStyle(color: c.muted, fontSize: 12, height: 1.45)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Блок на главной
// ---------------------------------------------------------------------------

class CarsHomeSection extends StatefulWidget {
  const CarsHomeSection({super.key});

  @override
  State<CarsHomeSection> createState() => _CarsHomeSectionState();
}

class _CarsHomeSectionState extends State<CarsHomeSection> {
  CarsList? _data;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    CarsApi(context.app, context.store.api).list().then((d) {
      if (mounted) setState(() => _data = d);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null || d.cars.isEmpty) return const SizedBox.shrink();
    final c = context.c;
    void openAll() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CarsScreen()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          context.k('title'),
          icon: Icons.directions_car_rounded,
          trailing: TextButton(onPressed: openAll, child: Text(context.k('all'), style: TextStyle(color: c.primary, fontWeight: FontWeight.w700))),
        ),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: d.cars.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final car = d.cars[i];
              return SizedBox(
                width: 260,
                child: Material(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CarDetail(car: car, phone: d.phone, whatsapp: d.whatsapp)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Photos(photos: car.photos, aspect: 4 / 3),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (car.category.isNotEmpty)
                                Text(car.category.toUpperCase(),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                              const SizedBox(height: 4),
                              Text(car.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
