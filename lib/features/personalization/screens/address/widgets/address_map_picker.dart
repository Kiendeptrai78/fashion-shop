import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class AddressMapPicker extends StatelessWidget {
  const AddressMapPicker({super.key, required this.value, required this.onChanged});
  final LatLng? value;
  final ValueChanged<LatLng?> onChanged;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Expanded(child: ShopText('Pin delivery location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      if (value != null) IconButton(onPressed: () => onChanged(null), icon: const Icon(Icons.close, size: 18))]),
    const SizedBox(height: 10),
    const ShopText('Tap the map to add a pin. Keep the written address complete for delivery.', style: TextStyle(fontSize: 12, height: 1.6)),
    const SizedBox(height: 16),
    ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 280,
      child: FlutterMap(options: MapOptions(
        initialCenter: value ?? const LatLng(16.0, 106.0), initialZoom: value == null ? 5.0 : 15,
        onTap: (_, point) => onChanged(point),
      ), children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.fashion_business_app'),
        if (value != null) MarkerLayer(markers: [Marker(point: value!, width: 44, height: 44,
            alignment: Alignment.topCenter,
            child: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 42))]),
        RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors',
            onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')))]),
      ]),
    )),
    if (value != null) Padding(padding: const EdgeInsets.only(top: 10),
      child: ShopText('Delivery pin saved with this address.', style: TextStyle(
          color: Theme.of(context).colorScheme.primary, fontSize: 12))),
  ]);
}
