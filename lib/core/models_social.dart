// Модели для жителей, раиса и чата.

class MahallaItem {
  MahallaItem({required this.id, required this.name, required this.city});
  final String id, name, city;

  factory MahallaItem.fromJson(Map<String, dynamic> j) => MahallaItem(
    id: j['id'] as String,
    name: j['name'] as String,
    city: (j['city'] ?? '') as String,
  );
}

class MyPhoto {
  MyPhoto({required this.status, required this.thumb, this.reason});
  final String status, thumb;
  final String? reason;

  factory MyPhoto.fromJson(Map<String, dynamic> j) => MyPhoto(
    status: j['status'] as String,
    thumb: j['thumb'] as String,
    reason: j['reason'] as String?,
  );
}

class Subbotnik {
  Subbotnik({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.startsAt,
    required this.photoFrom,
    required this.photoUntil,
    required this.status,
    this.state,
    required this.photos,
    this.participate = 0,
    this.refused = 0,
    this.accepted = 0,
  });

  final String id, title, description, location, status;
  final DateTime date, startsAt, photoFrom, photoUntil;
  final String? state;
  final List<MyPhoto> photos;
  final int participate, refused, accepted;

  bool get photoWindowOpen {
    final now = DateTime.now();
    return now.isAfter(photoFrom) && now.isBefore(photoUntil);
  }

  factory Subbotnik.fromJson(Map<String, dynamic> j) {
    DateTime d(dynamic v) => DateTime.parse(v as String).toLocal();
    final my = j['my'] as Map<String, dynamic>?;
    final st = j['stats'] as Map<String, dynamic>?;
    return Subbotnik(
      id: j['id'] as String,
      title: j['title'] as String,
      description: (j['description'] ?? '') as String,
      location: (j['location'] ?? '') as String,
      date: d(j['date']),
      startsAt: d(j['startsAt']),
      photoFrom: d(j['photoFrom']),
      photoUntil: d(j['photoUntil']),
      status: j['status'] as String,
      state: my?['state'] as String?,
      photos: [
        for (final p in ((my?['photos'] as List?) ?? []))
          MyPhoto.fromJson((p as Map).cast<String, dynamic>()),
      ],
      participate: (st?['participate'] as num?)?.toInt() ?? 0,
      refused: (st?['refused'] as num?)?.toInt() ?? 0,
      accepted: (st?['accepted'] as num?)?.toInt() ?? 0,
    );
  }
}

class SubbotnikData {
  SubbotnikData({
    required this.mahalla,
    required this.rating,
    required this.refusalsUsed,
    required this.refusalLimit,
    required this.residents,
    required this.items,
    required this.role,
  });

  final String mahalla, role;
  final int rating, refusalsUsed, refusalLimit, residents;
  final List<Subbotnik> items;

  factory SubbotnikData.fromJson(Map<String, dynamic> j) {
    final m = j['mahalla'] as Map<String, dynamic>?;
    return SubbotnikData(
      mahalla: m == null ? '' : '${m['city'] ?? ''} · ${m['name'] ?? ''}',
      role: j['role'] as String,
      rating: (j['rating'] as num).toInt(),
      refusalsUsed: (j['refusalsUsed'] as num).toInt(),
      refusalLimit: (j['refusalLimit'] as num).toInt(),
      residents: (j['residents'] as num?)?.toInt() ?? 0,
      items: [
        for (final s in (j['subbotniks'] as List))
          Subbotnik.fromJson((s as Map).cast<String, dynamic>()),
      ],
    );
  }
}

class ChatMsg {
  ChatMsg({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.pinned,
    required this.deleted,
    required this.authorId,
    required this.role,
    this.house,
    this.name,
  });

  final String id, body, authorId, role;
  final DateTime createdAt;
  final bool pinned, deleted;
  final String? house, name;

  String get label => role == 'CHAIRMAN' ? (name ?? '') : '№ ${house ?? ''}';

  factory ChatMsg.fromJson(Map<String, dynamic> j) {
    final a = (j['author'] as Map).cast<String, dynamic>();
    return ChatMsg(
      id: j['id'] as String,
      body: (j['body'] ?? '') as String,
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      pinned: j['pinned'] as bool,
      deleted: j['deleted'] as bool,
      authorId: a['id'] as String,
      role: a['role'] as String,
      house: a['house'] as String?,
      name: a['name'] as String?,
    );
  }
}

class ChatData {
  ChatData({
    required this.messages,
    this.pinned,
    required this.meId,
    required this.isChairman,
  });

  final List<ChatMsg> messages;
  final ChatMsg? pinned;
  final String meId;
  final bool isChairman;

  factory ChatData.fromJson(Map<String, dynamic> j) => ChatData(
    messages: [
      for (final m in (j['messages'] as List))
        ChatMsg.fromJson((m as Map).cast<String, dynamic>()),
    ],
    pinned: j['pinned'] == null
        ? null
        : ChatMsg.fromJson((j['pinned'] as Map).cast<String, dynamic>()),
    meId: j['meId'] as String,
    isChairman: j['isChairman'] as bool,
  );
}
