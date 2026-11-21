import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';

class CampaignCarousel extends StatefulWidget {
  const CampaignCarousel({super.key, required this.campaigns, required this.onOpen});

  final List<BannerModel> campaigns;
  final ValueChanged<BannerModel> onOpen;

  @override
  State<CampaignCarousel> createState() => _CampaignCarouselState();
}

class _CampaignCarouselState extends State<CampaignCarousel> with WidgetsBindingObserver {
  int _current = 0;
  bool _visible = false;
  bool _paused = false;
  bool _resumed = true;
  bool _requestedMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) setState(() => _resumed = state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.campaigns.isEmpty) return const SizedBox.shrink();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final moving = _visible && _resumed && !_paused && (!reduceMotion || _requestedMotion);
    final current = widget.campaigns[_current.clamp(0, widget.campaigns.length - 1)];
    final theme = Theme.of(context);
    return VisibilityDetector(
      key: ObjectKey(this),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0.5;
        if (mounted && visible != _visible) setState(() => _visible = visible);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: ShopText('THE SNEAKER EDIT', style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600))),
            IconButton(
              tooltip: _paused || reduceMotion && !_requestedMotion ? 'Play campaigns' : 'Pause campaigns',
              onPressed: () => setState(() {
                if (reduceMotion && !_requestedMotion) {
                  _requestedMotion = true;
                  _paused = false;
                } else {
                  _paused = !_paused;
                }
              }),
              icon: Icon(_paused || reduceMotion && !_requestedMotion
                  ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ]),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CarouselSlider.builder(
              itemCount: widget.campaigns.length,
              options: CarouselOptions(
                aspectRatio: 1.55,
                viewportFraction: 1,
                autoPlay: moving && !reduceMotion && widget.campaigns.length > 1,
                autoPlayInterval: const Duration(seconds: 10),
                autoPlayAnimationDuration: const Duration(milliseconds: 600),
                pauseAutoPlayOnTouch: true,
                enableInfiniteScroll: widget.campaigns.length > 1,
                onPageChanged: (index, _) => setState(() => _current = index),
              ),
              itemBuilder: (context, index, _) {
                final campaign = widget.campaigns[index];
                return Semantics(
                  button: true, label: campaign.title.isEmpty ? 'Explore collection' : campaign.title,
                  child: InkWell(
                    onTap: () => widget.onOpen(campaign),
                    child: Stack(fit: StackFit.expand, children: [
                      if (campaign.videoUrl.isNotEmpty)
                        _CampaignVideo(campaign: campaign, active: moving && index == _current)
                      else
                        TRoundedImage(imageUrl: campaign.imageUrl, isNetworkImage: true,
                            fit: BoxFit.cover, width: double.infinity, height: double.infinity, borderRadius: 0),
                      if (campaign.videoUrl.isNotEmpty) ...[
                        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                          begin: Alignment.center, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB3000000)],
                        ))),
                        Positioned(left: 20, bottom: 20, right: 20, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ShopText('IN MOTION', style: TextStyle(color: Colors.white70,
                                fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            ShopText(campaign.title, maxLines: 2, style: const TextStyle(color: Colors.white,
                                fontSize: 26, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: -0.6)),
                            const SizedBox(height: 8),
                            Row(children: [
                              ShopText(campaign.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                            ]),
                          ],
                        )),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: InkWell(
              onTap: () => widget.onOpen(current),
              child: Row(children: [
                Flexible(child: ShopText(current.videoUrl.isNotEmpty ? 'Shop the collection'
                    : current.title.isEmpty ? 'Explore collection' : current.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ]),
            )),
            const SizedBox(width: 12),
            for (var index = 0; index < widget.campaigns.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: index == _current ? 18 : 5, height: 5,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
                    color: index == _current ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.2)),
              ),
          ]),
        ],
      ),
    );
  }
}

class _CampaignVideo extends StatefulWidget {
  const _CampaignVideo({required this.campaign, required this.active});
  final BannerModel campaign;
  final bool active;

  @override
  State<_CampaignVideo> createState() => _CampaignVideoState();
}

class _CampaignVideoState extends State<_CampaignVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  Future<void> _start() async {
    if (_controller != null || _failed) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.campaign.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (!mounted || _controller != controller) return;
      setState(() {});
      _syncPlayback();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (widget.active && !_failed) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  @override
  void didUpdateWidget(covariant _CampaignVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && _controller == null) _start();
    _syncPlayback();
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || controller == null || !controller.value.isInitialized) {
      return TRoundedImage(imageUrl: widget.campaign.imageUrl, isNetworkImage: true,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity, borderRadius: 0);
    }
    return SizedBox.expand(child: FittedBox(fit: BoxFit.cover,
        child: SizedBox(width: controller.value.size.width, height: controller.value.size.height,
            child: VideoPlayer(controller))));
  }
}
