import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/hotels.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

const _s = <String, Map<String, String>>{
  'tg': {
    'title': 'Меҳмонхонаҳо',
    'partner': 'Ҳамкори Сафо',
    'from': 'аз',
    'night': 'шаб',
    'call': 'Занг задан',
    'book_title': 'Нархҳоро санҷед ва бронкунӣ',
    'dates': 'Санаҳо',
    'pick_dates': 'Санаҳоро интихоб кунед',
    'adults': 'Калонсолон',
    'children': 'Кӯдакон',
    'show_prices': 'Нархҳоро нишон диҳед',
    'nights': '{n} шаб',
    'free_rooms': 'Ҳуҷраҳои холӣ',
    'no_rooms': 'Дар ин санаҳо ҳуҷраи холӣ нест. Санаҳои дигарро интихоб кунед.',
    'busy': 'Дар ин санаҳо дастрас нест',
    'total': 'ҳамагӣ',
    'book_hotel': 'Дар меҳмонхона бронкунӣ',
    'request': 'Дархост фиристед',
    'request_hint':
        'Дархост ба меҳмонхона мерасад. Бронкуниро худи меҳмонхона тасдиқ мекунад.',
    'prices_note':
        'Нархҳо аз системаи бронкунии меҳмонхона гирифта шудаанд ва метавонанд тағйир ёбанд.',
    'name': 'Номи шумо',
    'phone': 'Телефон / WhatsApp',
    'comment': 'Хоҳишҳо (ихтиёрӣ)',
    'send': 'Фиристодан',
    'sent_title': 'Дархост фиристода шуд',
    'sent_text': 'Меҳмонхона бо шумо тамос мегирад.',
    'close': 'Пӯшидан',
    'err_fill': 'Ном ва телефонро нависед',
    'err_dates': 'Аввал санаҳоро интихоб кунед',
    'err_net': 'Пайваст нашуд. Бори дигар кӯшиш кунед',
    'about': 'Дар бораи меҳмонхона',
    'features': 'Чӣ дорад',
    'rooms': 'Ҳуҷраҳо ва нархҳо',
    'services': 'Хизматрасонӣ',
    'contacts': 'Тамос',
    'checkin': 'Ворид шудан',
    'checkout': 'Баромадан',
    'route': 'Роҳ дар харита',
    'sqm': '{n} м²',
    'guests': 'то {n} меҳмон',
    'amenities': 'Дар ҳуҷра',
    'retry': 'Бори дигар',
    'empty': 'Меҳмонхона ёфт нашуд',
    'photos': '{n} акс',
  },
  'ru': {
    'title': 'Отели',
    'partner': 'Партнёр Сафо',
    'from': 'от',
    'night': 'ночь',
    'call': 'Позвонить',
    'book_title': 'Проверить цены и забронировать',
    'dates': 'Даты',
    'pick_dates': 'Выберите даты',
    'adults': 'Взрослые',
    'children': 'Дети',
    'show_prices': 'Показать цены',
    'nights': '{n} н.',
    'free_rooms': 'Свободные номера',
    'no_rooms': 'На эти даты свободных номеров нет. Выберите другие даты.',
    'busy': 'На эти даты недоступны',
    'total': 'всего',
    'book_hotel': 'Забронировать в отеле',
    'request': 'Оставить запрос',
    'request_hint':
        'Запрос уйдёт в отель. Бронь подтверждает сам отель.',
    'prices_note':
        'Цены берутся из системы бронирования отеля и могут измениться.',
    'name': 'Ваше имя',
    'phone': 'Телефон / WhatsApp',
    'comment': 'Пожелания (необязательно)',
    'send': 'Отправить',
    'sent_title': 'Запрос отправлен',
    'sent_text': 'Отель свяжется с вами.',
    'close': 'Закрыть',
    'err_fill': 'Укажите имя и телефон',
    'err_dates': 'Сначала выберите даты',
    'err_net': 'Нет связи. Попробуйте ещё раз',
    'about': 'Об отеле',
    'features': 'Что есть',
    'rooms': 'Номера и цены',
    'services': 'Услуги',
    'contacts': 'Контакты',
    'checkin': 'Заезд',
    'checkout': 'Выезд',
    'route': 'Маршрут на карте',
    'sqm': '{n} м²',
    'guests': 'до {n} гостей',
    'amenities': 'В номере',
    'retry': 'Повторить',
    'empty': 'Отель не найден',
    'photos': '{n} фото',
  },
  'en': {
    'title': 'Hotels',
    'partner': 'Safo partner',
    'from': 'from',
    'night': 'night',
    'call': 'Call',
    'book_title': 'Check prices and book',
    'dates': 'Dates',
    'pick_dates': 'Choose dates',
    'adults': 'Adults',
    'children': 'Children',
    'show_prices': 'Show prices',
    'nights': '{n} nights',
    'free_rooms': 'Available rooms',
    'no_rooms': 'No rooms available for these dates. Try other dates.',
    'busy': 'Not available for these dates',
    'total': 'total',
    'book_hotel': 'Book at the hotel',
    'request': 'Send a request',
    'request_hint':
        'The request goes to the hotel. The hotel confirms the booking.',
    'prices_note':
        'Prices come from the hotel booking system and may change.',
    'name': 'Your name',
    'phone': 'Phone / WhatsApp',
    'comment': 'Requests (optional)',
    'send': 'Send',
    'sent_title': 'Request sent',
    'sent_text': 'The hotel will contact you.',
    'close': 'Close',
    'err_fill': 'Enter your name and phone',
    'err_dates': 'Choose dates first',
    'err_net': 'No connection. Please try again',
    'about': 'About the hotel',
    'features': 'Highlights',
    'rooms': 'Rooms and prices',
    'services': 'Services',
    'contacts': 'Contacts',
    'checkin': 'Check-in',
    'checkout': 'Check-out',
    'route': 'Directions on map',
    'sqm': '{n} m²',
    'guests': 'up to {n} guests',
    'amenities': 'In the room',
    'retry': 'Retry',
    'empty': 'Hotel not found',
    'photos': '{n} photos',
  },
};

extension _HX on BuildContext {
  String h(String key, [Map<String, Object>? p]) {
    var s = _s[app.lang]?[key] ?? _s['ru']![key] ?? key;
    p?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }
}

String _money(int n, String currency, String lang) {
  final digits = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  final sym = currency == 'TJS'
      ? (lang == 'tg' ? 'сомонӣ' : (lang == 'en' ? 'TJS' : 'сомони'))
      : currency;
  return lang == 'en' ? '$sym $buf' : '$buf $sym';
}

Future<void> _open(String url) async {
  final u = Uri.parse(url);
  if (await canLaunchUrl(u)) {
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }
}

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Открывает раздел «Отели»: если отель один — сразу его страница.
class HotelsScreen extends StatefulWidget {
  const HotelsScreen({super.key});

  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  List<Hotel>? _hotels;
  bool _failed = false;
  HotelsApi? _api;

  HotelsApi get api => _api ??= HotelsApi(context.app, context.store.api);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hotels == null && !_failed) _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final l = await api.list();
      if (mounted) setState(() => _hotels = l);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hotels = _hotels;
    if (hotels != null && hotels.length == 1) {
      return HotelDetail(hotel: hotels.first, api: api);
    }
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(context.h('title'))),
      body: hotels == null
          ? (_failed
                ? EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: context.h('err_net'),
                    action: PrimaryButton(
                      label: context.h('retry'),
                      icon: Icons.refresh_rounded,
                      onTap: _load,
                    ),
                  )
                : Center(child: CircularProgressIndicator(color: c.primary)))
          : hotels.isEmpty
          ? EmptyState(icon: Icons.hotel_rounded, title: context.h('empty'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: hotels.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) => HotelCard(
                hotel: hotels[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HotelDetail(hotel: hotels[i], api: api),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Карточка отеля: для главного экрана и списка.
class HotelCard extends StatelessWidget {
  const HotelCard({super.key, required this.hotel, required this.onTap});
  final Hotel hotel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.app.lang;
    final media = context.store.api.media;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: c.surface2,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hotel.photos.isNotEmpty)
              CachedNetworkImage(
                imageUrl: media(hotel.photos.first.medium),
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: c.surface2),
                errorWidget: (_, _, _) => Container(color: c.surface2),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xE6041A10)],
                  stops: [.35, 1],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .38),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: Color(0xFFE3B155),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.h('partner'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'★' * hotel.stars}  ${hotel.tagline.of(lang)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE3B155),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hotel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  if (hotel.fromPrice != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${context.h('from')} ${_money(hotel.fromPrice!, hotel.currency, lang)} / ${context.h('night')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HotelDetail extends StatefulWidget {
  const HotelDetail({super.key, required this.hotel, required this.api});
  final Hotel hotel;
  final HotelsApi api;

  @override
  State<HotelDetail> createState() => _HotelDetailState();
}

class _HotelDetailState extends State<HotelDetail> {
  late DateTimeRange _range;
  int _adults = 2;
  int _children = 0;
  bool _loading = false;
  String? _error;
  List<HQuote>? _quotes;
  DateTimeRange? _searched;
  int _searchedAdults = 2;
  int _searchedChildren = 0;
  final _page = PageController();
  int _photoIdx = 0;
  final _bookKey = GlobalKey();

  Hotel get h => widget.hotel;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _range = DateTimeRange(start: start, end: start.add(const Duration(days: 2)));
    widget.api.track(h.slug, 'VIEW');
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  int get _nights => _range.end.difference(_range.start).inDays;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final r = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _range,
      saveText: context.h('dates'),
    );
    if (r != null && r.end.isAfter(r.start)) {
      setState(() {
        _range = r;
        _quotes = null;
        _error = null;
      });
    }
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = await widget.api.quotes(h.slug, _range.start, _range.end, _adults);
      if (!mounted) return;
      setState(() {
        _quotes = q;
        _searched = _range;
        _searchedAdults = _adults;
        _searchedChildren = _children;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.h('err_net');
      });
    }
  }

  String? _officialUrl(String? roomCode) {
    if (h.bookingUrl == null) return null;
    final r = _searched ?? _range;
    final u = Uri.parse(h.bookingUrl!);
    final q = Map<String, String>.from(u.queryParameters)
      ..['date'] = HotelsApi.fmtDate(r.start)
      ..['nights'] = '${r.end.difference(r.start).inDays}'
      ..['adults'] = '${_searched != null ? _searchedAdults : _adults}'
      ..['children'] = '${_searched != null ? _searchedChildren : _children}';
    if (roomCode != null) q['room-type'] = roomCode;
    return u.replace(queryParameters: q).toString();
  }

  void _contact(String type, String url) {
    HapticFeedback.selectionClick();
    widget.api.track(h.slug, type);
    _open(url);
  }

  void _openViewer(List<HPhoto> photos, int start) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(photos: photos, start: start),
      ),
    );
  }

  Future<void> _requestSheet({HRoom? room, HQuote? quote}) async {
    final r = _searched ?? _range;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _RequestSheet(
        api: widget.api,
        hotel: h,
        range: r,
        adults: _searched != null ? _searchedAdults : _adults,
        children: _searched != null ? _searchedChildren : _children,
        room: room,
        quote: quote,
      ),
    );
    if (sent == true && mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.check_circle_rounded, color: ctx.c.primary, size: 44),
          title: Text(ctx.h('sent_title')),
          content: Text(ctx.h('sent_text')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.h('close')),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.app.lang;
    final media = context.store.api.media;
    final byCode = {for (final q in _quotes ?? <HQuote>[]) q.code: q};
    final avail = h.rooms.where((r) => byCode.containsKey(r.code)).toList()
      ..sort((a, b) => byCode[a.code]!.perNight.compareTo(byCode[b.code]!.perNight));
    final busy = h.rooms.where((r) => !byCode.containsKey(r.code)).toList();

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.text,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 360,
            backgroundColor: c.bg,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: .38),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (h.photos.isNotEmpty)
                    PageView.builder(
                      controller: _page,
                      itemCount: h.photos.length,
                      onPageChanged: (i) => setState(() => _photoIdx = i),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _openViewer(h.photos, i),
                        child: CachedNetworkImage(
                          imageUrl: media(h.photos[i].large),
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: c.surface2),
                          errorWidget: (_, _, _) => Container(color: c.surface2),
                        ),
                      ),
                    )
                  else
                    Container(color: c.surface2),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .25),
                            Colors.transparent,
                            const Color(0xF2041A10),
                          ],
                          stops: const [0, .45, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${'★' * h.stars}  ${h.tagline.of(lang)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE3B155),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            h.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (h.photos.length > 1)
                    Positioned(
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${_photoIdx + 1}/${h.photos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Цена + быстрые действия
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (h.fromPrice != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${context.h('from')} ',
                            style: TextStyle(color: c.muted, fontSize: 14),
                          ),
                          TextSpan(
                            text: _money(h.fromPrice!, h.currency, lang),
                            style: TextStyle(
                              color: c.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${context.h('night')}',
                            style: TextStyle(color: c.muted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: context.h('show_prices'),
                          icon: Icons.calendar_month_rounded,
                          onTap: () => Scrollable.ensureVisible(
                            _bookKey.currentContext!,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      if (h.phone != null) ...[
                        const SizedBox(width: 10),
                        _RoundBtn(
                          icon: Icons.call_rounded,
                          label: context.h('call'),
                          onTap: () => _contact('CALL', 'tel:${h.phone}'),
                        ),
                      ],
                      if (h.whatsapp != null) ...[
                        const SizedBox(width: 10),
                        _RoundBtn(
                          icon: Icons.chat_rounded,
                          label: 'WhatsApp',
                          onTap: () => _contact(
                            'WHATSAPP',
                            'https://wa.me/${_digits(h.whatsapp!)}',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Заезд/выезд + быстрые факты
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Fact(Icons.login_rounded, '${context.h('checkin')} ${h.checkIn}'),
                  _Fact(Icons.logout_rounded, '${context.h('checkout')} ${h.checkOut}'),
                ],
              ),
            ),
          ),

          // Проверка цен и бронирование
          SliverToBoxAdapter(
            key: _bookKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.h('book_title'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Pressable(
                      onTap: _pickDates,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_rounded, color: c.accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_fmt(_range.start)}  →  ${_fmt(_range.end)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: c.text,
                                ),
                              ),
                            ),
                            Text(
                              context.h('nights', {'n': _nights}),
                              style: TextStyle(color: c.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Stepper(
                            label: context.h('adults'),
                            value: _adults,
                            min: 1,
                            max: 6,
                            onChanged: (v) => setState(() {
                              _adults = v;
                              _quotes = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Stepper(
                            label: context.h('children'),
                            value: _children,
                            min: 0,
                            max: 6,
                            onChanged: (v) => setState(() => _children = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _loading
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(color: c.primary),
                              ),
                            )
                          : PrimaryButton(
                              label: context.h('show_prices'),
                              icon: Icons.search_rounded,
                              onTap: _search,
                            ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: TextStyle(color: c.danger)),
                    ],
                    if (_quotes != null) ...[
                      const SizedBox(height: 20),
                      if (avail.isEmpty)
                        Text(
                          context.h('no_rooms'),
                          style: TextStyle(color: c.muted),
                        )
                      else ...[
                        Text(
                          context.h('free_rooms'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final r in avail)
                          _QuoteTile(
                            room: r,
                            quote: byCode[r.code]!,
                            nights: _nights,
                            onBook: _officialUrl(r.code) == null
                                ? null
                                : () => _contact('BOOK_CLICK', _officialUrl(r.code)!),
                            onRequest: () => _requestSheet(room: r, quote: byCode[r.code]),
                          ),
                      ],
                      if (busy.isNotEmpty && avail.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${context.h('busy')}: ${busy.map((r) => r.name.of(lang)).join(' · ')}',
                          style: TextStyle(color: c.muted, fontSize: 12.5),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        context.h('prices_note'),
                        style: TextStyle(color: c.muted, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Divider(color: c.border, height: 1),
                    const SizedBox(height: 14),
                    Text(
                      context.h('request_hint'),
                      style: TextStyle(color: c.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: context.h('request'),
                        icon: Icons.send_rounded,
                        outlined: true,
                        onTap: () => _requestSheet(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Об отеле
          SliverToBoxAdapter(
            child: section(
              context.h('about'),
              Text(
                h.desc.of(lang),
                style: TextStyle(color: c.text, height: 1.6, fontSize: 15),
              ),
            ),
          ),
          if (h.features.isNotEmpty)
            SliverToBoxAdapter(
              child: section(
                context.h('features'),
                Column(
                  children: [
                    for (final f in h.features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _IconBadge(hotelIcon(f.icon)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 9),
                                child: Text(
                                  f.text.of(lang),
                                  style: TextStyle(color: c.text, height: 1.35),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Номера
          if (h.rooms.isNotEmpty)
            SliverToBoxAdapter(
              child: section(
                context.h('rooms'),
                Column(
                  children: [
                    for (final r in h.rooms)
                      _RoomCard(
                        room: r,
                        currency: h.currency,
                        onPhoto: (i) => _openViewer(r.photos, i),
                      ),
                  ],
                ),
              ),
            ),

          // Услуги
          if (h.services.isNotEmpty)
            SliverToBoxAdapter(
              child: section(
                context.h('services'),
                Column(
                  children: [
                    for (final s in h.services)
                      _ServiceCard(
                        service: s,
                        onPhoto: (i) => _openViewer(s.photos, i),
                      ),
                  ],
                ),
              ),
            ),

          // Контакты
          SliverToBoxAdapter(
            child: section(
              context.h('contacts'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (h.address.of(lang).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.place_rounded, color: c.accent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.address.of(lang),
                              style: TextStyle(color: c.text, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (h.lat != null && h.lng != null)
                        _Chip(
                          Icons.directions_rounded,
                          context.h('route'),
                          () => _open(
                            'https://www.google.com/maps/dir/?api=1&destination=${h.lat},${h.lng}',
                          ),
                        ),
                      if (h.phone != null)
                        _Chip(
                          Icons.call_rounded,
                          h.phone!,
                          () => _contact('CALL', 'tel:${h.phone}'),
                        ),
                      if (h.whatsapp != null)
                        _Chip(
                          Icons.chat_rounded,
                          'WhatsApp',
                          () => _contact(
                            'WHATSAPP',
                            'https://wa.me/${_digits(h.whatsapp!)}',
                          ),
                        ),
                      if (h.telegram != null)
                        _Chip(
                          Icons.send_rounded,
                          'Telegram',
                          () => _contact('TELEGRAM', 'https://t.me/${h.telegram}'),
                        ),
                      if (h.email != null)
                        _Chip(
                          Icons.mail_rounded,
                          h.email!,
                          () => _contact('EMAIL', 'mailto:${h.email}'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tooltip(
      message: label,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
          ),
          child: Icon(icon, color: c.primary),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c.accent),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c.primary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 21, color: c.accent),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({
    required this.room,
    required this.quote,
    required this.nights,
    required this.onBook,
    required this.onRequest,
  });
  final HRoom room;
  final HQuote quote;
  final int nights;
  final VoidCallback? onBook;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.app.lang;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room.name.of(lang),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: c.text,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _money(quote.perNight, quote.currency, lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: c.text,
                  ),
                ),
                TextSpan(
                  text:
                      ' / ${context.h('night')} · ${context.h('total')} ${_money(quote.total, quote.currency, lang)}',
                  style: TextStyle(color: c.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onBook != null)
                Expanded(
                  child: PrimaryButton(
                    label: context.h('book_hotel'),
                    icon: Icons.open_in_new_rounded,
                    onTap: onBook!,
                  ),
                ),
              if (onBook != null) const SizedBox(width: 10),
              _RoundBtn(
                icon: Icons.send_rounded,
                label: context.h('request'),
                onTap: onRequest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos, required this.onTap, this.height = 190});
  final List<HPhoto> photos;
  final ValueChanged<int> onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final media = context.store.api.media;
    if (photos.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: media(photos[i].medium),
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: c.surface2),
                errorWidget: (_, _, _) => Container(color: c.surface2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.currency, required this.onPhoto});
  final HRoom room;
  final String currency;
  final ValueChanged<int> onPhoto;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.app.lang;
    final size = room.sizeFrom == null
        ? null
        : context.h('sqm', {
            'n': room.sizeTo != null && room.sizeTo != room.sizeFrom
                ? '${room.sizeFrom}–${room.sizeTo}'
                : '${room.sizeFrom}',
          });
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PhotoStrip(photos: room.photos, onTap: onPhoto),
          if (room.photos.isNotEmpty) const SizedBox(height: 14),
          Text(
            room.name.of(lang),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: c.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              ?size,
              context.h('guests', {'n': room.maxGuests}),
            ].join(' · '),
            style: TextStyle(color: c.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            room.desc.of(lang),
            style: TextStyle(color: c.text, height: 1.5, fontSize: 14),
          ),
          if (room.amenities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in room.amenities)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      a.of(lang),
                      style: TextStyle(fontSize: 12, color: c.text),
                    ),
                  ),
              ],
            ),
          ],
          if (room.fromPrice != null) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${context.h('from')} ',
                    style: TextStyle(color: c.muted, fontSize: 13),
                  ),
                  TextSpan(
                    text: _money(room.fromPrice!, currency, lang),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: c.text,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${context.h('night')}',
                    style: TextStyle(color: c.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onPhoto});
  final HService service;
  final ValueChanged<int> onPhoto;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.app.lang;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PhotoStrip(photos: service.photos, onTap: onPhoto, height: 170),
          if (service.photos.isNotEmpty) const SizedBox(height: 14),
          Row(
            children: [
              _IconBadge(hotelIcon(_serviceIcon(service.key))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.title.of(lang),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
              ),
            ],
          ),
          if (service.hours != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  service.hours!,
                  style: TextStyle(
                    color: c.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            service.text.of(lang),
            style: TextStyle(color: c.text, height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

String _serviceIcon(String key) => switch (key) {
  'breakfast' => 'utensils',
  'fitness' => 'dumbbell',
  'spa' => 'waves',
  'conference' => 'briefcase',
  'offices' => 'building',
  'wifi' => 'wifi',
  'parking' => 'car',
  _ => '',
};

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.start});
  final List<HPhoto> photos;
  final int start;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _c = PageController(initialPage: widget.start);
  late int _i = widget.start;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = context.store.api.media;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_i + 1} / ${widget.photos.length}',
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: PageView.builder(
        controller: _c,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _i = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: media(widget.photos[i].large),
              fit: BoxFit.contain,
              placeholder: (_, _) =>
                  const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, _, _) =>
                  const Icon(Icons.broken_image_rounded, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({
    required this.api,
    required this.hotel,
    required this.range,
    required this.adults,
    required this.children,
    this.room,
    this.quote,
  });
  final HotelsApi api;
  final Hotel hotel;
  final DateTimeRange range;
  final int adults, children;
  final HRoom? room;
  final HQuote? quote;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+992');
  final _comment = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.length < 2 || phone.replaceAll(RegExp(r'\D'), '').length < 6) {
      setState(() => _error = context.h('err_fill'));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.api.request(
        widget.hotel.slug,
        name: name,
        phone: phone,
        from: widget.range.start,
        to: widget.range.end,
        adults: widget.adults,
        children: widget.children,
        roomCode: widget.room?.code,
        comment: _comment.text,
        quotedTotal: widget.quote?.total,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = context.h('err_net');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.app.lang;
    String d(DateTime x) =>
        '${x.day.toString().padLeft(2, '0')}.${x.month.toString().padLeft(2, '0')}.${x.year}';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.h('request'),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: c.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.hotel.name} · ${d(widget.range.start)} → ${d(widget.range.end)}'
              '${widget.room != null ? ' · ${widget.room!.name.of(lang)}' : ''}',
              style: TextStyle(color: c.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: context.h('name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: context.h('phone')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(labelText: context.h('comment')),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: TextStyle(color: c.danger)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _sending
                  ? Center(child: CircularProgressIndicator(color: c.primary))
                  : PrimaryButton(
                      label: context.h('send'),
                      icon: Icons.send_rounded,
                      onTap: _send,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Блок «Отели» на главном экране: карточка первого партнёрского отеля.
class HotelsHomeSection extends StatefulWidget {
  const HotelsHomeSection({super.key});

  @override
  State<HotelsHomeSection> createState() => _HotelsHomeSectionState();
}

class _HotelsHomeSectionState extends State<HotelsHomeSection> {
  List<Hotel> _hotels = const [];
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    HotelsApi(context.app, context.store.api).list().then((l) {
      if (mounted) setState(() => _hotels = l);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_hotels.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(context.h('title'), icon: Icons.hotel_rounded),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: HotelCard(
            hotel: _hotels.first,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HotelsScreen()),
            ),
          ),
        ),
      ],
    );
  }
}
