import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/place_cards.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _map = MapController();
  Place? _sel;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l = context.app.lang;
    final places = context.store.places.where((p) => p.hasCoords).toList();
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: const LatLng(38.86, 71.28),
            initialZoom: 6.6,
            minZoom: 5,
            maxZoom: 17,
            onTap: (_, _) => setState(() => _sel = null),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'tj.safo.safo',
              // Тёмная тема: те же плитки OSM с инверсией цвета (CARTO требует ключ)
              tileBuilder: dark ? darkModeTileBuilder : null,
            ),
            MarkerLayer(
              markers: [
                for (final p in places)
                  Marker(
                    point: LatLng(p.lat!, p.lng!),
                    width: 52,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _sel = p);
                        _map.move(LatLng(p.lat! - .02, p.lng!), 10.5);
                      },
                      child: _Pin(
                        icon: catIcon(p.category),
                        active: _sel?.id == p.id,
                      ),
                    ),
                  ),
              ],
            ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution(
                  dark ? '© OpenStreetMap, © CARTO' : '© OpenStreetMap',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: top + 14,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.map_rounded, color: c.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.t('nav_map'),
                    style: context.tt.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${places.length}',
                    style: TextStyle(
                      color: c.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          left: 20,
          right: 20,
          bottom: _sel == null ? -220 : 118,
          child: _sel == null
              ? const SizedBox(height: 150)
              : Pressable(
                  onTap: () => openPlace(context, _sel!, 'map-${_sel!.slug}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: c.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .3),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 92,
                            height: 92,
                            child: Hero(
                              tag: 'map-${_sel!.slug}',
                              child: PlaceImage(
                                url: firstPhoto(context, _sel!),
                                category: _sel!.category,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _sel!.nameOf(l),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.tt.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${context.cat(_sel!.category)} · ${context.reg(_sel!.region)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: c.muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    context.t('open'),
                                    style: TextStyle(
                                      color: c.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: c.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.icon, required this.active});
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedScale(
      scale: active ? 1.25 : 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(colors: [c.accent, const Color(0xFFF59E0B)])
                  : c.brand,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: active ? Colors.black87 : c.onPrimary,
            ),
          ),
          Container(
            width: 3,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
