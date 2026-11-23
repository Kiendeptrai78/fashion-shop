import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/product/favourite_icon/favourite_icon.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class VeloraReelItem {
  const VeloraReelItem({
    required this.id,
    required this.product,
    required this.videoUrl,
    required this.videoIndex,
    required this.totalProductVideos,
    this.isPersonalizedRecommendation = false,
  });

  final String id;
  final ProductModel product;
  final String videoUrl;
  final int videoIndex;
  final int totalProductVideos;
  final bool isPersonalizedRecommendation;
}

class VeloraReelsScreen extends StatefulWidget {
  const VeloraReelsScreen({
    super.key,
    this.initialProduct,
    this.showBackButton = false,
    this.initialOpenComments = false,
  });

  final ProductModel? initialProduct;
  final bool showBackButton;
  final bool initialOpenComments;

  @override
  State<VeloraReelsScreen> createState() => _VeloraReelsScreenState();
}

class _VeloraReelsScreenState extends State<VeloraReelsScreen> {
  final _db = FirebaseFirestore.instance;
  PageController _pageController = PageController();

  List<ProductModel> _allProducts = [];
  List<VeloraReelItem> _reels = [];
  Set<String> _recommendedProductIds = {};
  Set<String> _favoriteCategoryIds = {};
  String _selectedCategoryId = 'all';
  int _currentIndex = 0;
  bool _loading = true;
  bool _muted = false;

  // Fallback Cloudinary promo videos if a product doesn't have custom videos yet
  static const Map<String, List<String>> _defaultCategoryVideos = {
    'running-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247608/velora-reels-v2/velora_reel_running_v2.mp4',
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247611/velora-reels-v2/velora_reel_stride_v2.mp4',
    ],
    'lifestyle-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247614/velora-reels-v2/velora_reel_lifestyle_v2.mp4',
    ],
    'training-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247616/velora-reels-v2/velora_reel_training_v2.mp4',
    ],
    'basketball-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247618/velora-reels-v2/velora_reel_basketball_v2.mp4',
    ],
    'trail-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247621/velora-reels-v2/velora_reel_trail_v2.mp4',
    ],
  };

  static const List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Dành cho bạn'},
    {'id': 'running-category', 'name': 'Chạy bộ'},
    {'id': 'lifestyle-category', 'name': 'Hằng ngày'},
    {'id': 'training-category', 'name': 'Tập luyện'},
    {'id': 'basketball-category', 'name': 'Bóng rổ'},
    {'id': 'trail-category', 'name': 'Địa hình'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _videosForProduct(ProductModel p) {
    final explicit = (p.videos ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (explicit.isNotEmpty) return explicit;
    return _defaultCategoryVideos[p.categoryId] ??
        _defaultCategoryVideos['running-category']!;
  }

  Future<void> _loadReels() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final uDoc = await _db.collection('Users').doc(user.uid).get();
          final uData = uDoc.data();
          if (uData != null) {
            _recommendedProductIds = Set<String>.from(
              (uData['recommendedProductIds'] as List? ?? const [])
                  .map((e) => e.toString()),
            );
            _favoriteCategoryIds = Set<String>.from(
              (uData['FavoriteCategoryIds'] as List? ?? const [])
                  .map((e) => e.toString()),
            );
          }
        } catch (_) {}
      }

      final snap = await _db.collection('Products').get();
      final products = snap.docs.map(ProductModel.fromSnapshot).toList();
      _allProducts = products;
      _rebuildReelList();
    } catch (_) {
      if (widget.initialProduct != null) {
        _allProducts = [widget.initialProduct!];
        _rebuildReelList();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Dynamically injects similar products into the user's feed right after
  /// they like or comment on a video!
  void _injectSimilarProductsFor(ProductModel watched) {
    final existingIds = _reels.map((r) => r.product.id).toSet();
    final similar = _allProducts
        .where((p) =>
            p.id != watched.id &&
            p.categoryId == watched.categoryId &&
            !existingIds.contains(p.id))
        .take(3)
        .toList();
    if (similar.isEmpty) return;

    final inserted = <VeloraReelItem>[];
    for (final p in similar) {
      _recommendedProductIds.add(p.id);
      final vids = _videosForProduct(p);
      if (vids.isNotEmpty) {
        inserted.add(VeloraReelItem(
          id: '${p.id}_rec_${DateTime.now().millisecondsSinceEpoch}',
          product: p,
          videoUrl: vids.first,
          videoIndex: 0,
          totalProductVideos: vids.length,
          isPersonalizedRecommendation: true,
        ));
      }
    }
    if (inserted.isEmpty) return;
    setState(() {
      final insertPos = (_currentIndex + 1).clamp(0, _reels.length);
      _reels.insertAll(insertPos, inserted);
    });
  }

  void _rebuildReelList() {
    // Only show curated Featured products + user's personalized recommendations
    // (never dump all 105 products / 210 videos to every user at once).
    final basePool = _allProducts.where((p) {
      if (widget.initialProduct != null && p.id == widget.initialProduct!.id) {
        return true;
      }
      if (_recommendedProductIds.contains(p.id)) return true;
      return p.isFeatured;
    }).toList();

    final pool = basePool.isNotEmpty ? basePool : _allProducts.take(15).toList();
    final filteredProducts = _selectedCategoryId == 'all'
        ? pool
        : pool.where((p) => p.categoryId == _selectedCategoryId).toList();

    filteredProducts.sort((a, b) {
      if (widget.initialProduct != null) {
        if (a.id == widget.initialProduct!.id) return -1;
        if (b.id == widget.initialProduct!.id) return 1;
      }
      final aRec = _recommendedProductIds.contains(a.id);
      final bRec = _recommendedProductIds.contains(b.id);
      if (aRec != bRec) return aRec ? -1 : 1;
      final aFavCat = _favoriteCategoryIds.contains(a.categoryId);
      final bFavCat = _favoriteCategoryIds.contains(b.categoryId);
      if (aFavCat != bFavCat) return aFavCat ? -1 : 1;
      return a.title.compareTo(b.title);
    });

    final items = <VeloraReelItem>[];
    for (final p in filteredProducts) {
      final vids = _videosForProduct(p);
      final isInitial =
          widget.initialProduct != null && p.id == widget.initialProduct!.id;
      final isRec = _recommendedProductIds.contains(p.id);
      // Show all videos for the explicitly opened product, and 1 primary highlight video per feed product
      final count = isInitial ? vids.length : (vids.isNotEmpty ? 1 : 0);
      for (var i = 0; i < count; i++) {
        items.add(VeloraReelItem(
          id: '${p.id}_v$i',
          product: p,
          videoUrl: vids[i],
          videoIndex: i,
          totalProductVideos: vids.length,
          isPersonalizedRecommendation: isRec,
        ));
      }
    }

    _pageController.dispose();
    _pageController = PageController(initialPage: 0);
    setState(() {
      _reels = items;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isVi = lang != 'en';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF07130F),
        body: Stack(
          children: [
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFDDEABB)),
              )
            else if (_reels.isEmpty)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.video_slash, color: Colors.white54, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      isVi
                          ? 'Chưa có video quảng cáo nào trong danh mục này.'
                          : 'No promo videos in this category yet.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        _selectedCategoryId = 'all';
                        _rebuildReelList();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDDEABB),
                        side: const BorderSide(color: Color(0xFFDDEABB)),
                      ),
                      child: Text(isVi ? 'Xem tất cả Video VELORA' : 'View all VELORA Reels'),
                    ),
                  ],
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _reels.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final reel = _reels[index];
                  return _VeloraReelSlide(
                    key: ValueKey(reel.id),
                    reel: reel,
                    isActive: index == _currentIndex,
                    isMuted: _muted,
                    autoOpenComments:
                        index == 0 && widget.initialOpenComments,
                    onToggleMute: () => setState(() => _muted = !_muted),
                    onUserInteracted: () => _injectSimilarProductsFor(reel.product),
                  );
                },
              ),

            // Top header + category filter tabs (TikTok style)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (widget.showBackButton || Navigator.of(context).canPop())
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFDDEABB).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFDDEABB),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isVi ? 'VELORA NỔI BẬT' : 'VELORA FEATURED',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_reels.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${_reels.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) {
                          final cat = _categories[idx];
                          final selected = _selectedCategoryId == cat['id'];
                          return GestureDetector(
                            onTap: () {
                              if (_selectedCategoryId != cat['id']) {
                                _selectedCategoryId = cat['id']!;
                                _rebuildReelList();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFDDEABB)
                                    : Colors.black.withValues(alpha: 0.42),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFDDEABB)
                                      : Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: ShopText(
                                cat['name']!,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF102B23)
                                      : Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VeloraReelSlide extends StatefulWidget {
  const _VeloraReelSlide({
    super.key,
    required this.reel,
    required this.isActive,
    required this.isMuted,
    this.autoOpenComments = false,
    required this.onToggleMute,
    required this.onUserInteracted,
  });

  final VeloraReelItem reel;
  final bool isActive;
  final bool isMuted;
  final bool autoOpenComments;
  final VoidCallback onToggleMute;
  final VoidCallback onUserInteracted;

  @override
  State<_VeloraReelSlide> createState() => _VeloraReelSlideState();
}

class _VeloraReelSlideState extends State<_VeloraReelSlide>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  VideoPlayerController? _videoController;
  bool _initialized = false;
  bool _pausedByUser = false;
  bool _liked = false;
  int _likesCount = 24;
  int _commentsCount = 3;
  bool _showHeartBurst = false;

  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    // Base organic counts from product hash so every video looks active
    final seed = widget.reel.product.id.hashCode.abs();
    _likesCount = 18 + (seed % 95);
    _commentsCount = 3 + (seed % 14);
    _loadInteractionState();
    _initVideo();
    if (widget.autoOpenComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openCommentsSheet();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _VeloraReelSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive && !_pausedByUser) {
        _videoController?.play();
      } else {
        _videoController?.pause();
      }
    }
    if (widget.isMuted != oldWidget.isMuted) {
      _videoController?.setVolume(widget.isMuted ? 0 : 1);
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl));
      _videoController = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(widget.isMuted ? 0 : 1);
      if (widget.isActive && !_pausedByUser) {
        await ctrl.play();
      }
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _initialized = false);
    }
  }

  Future<void> _loadInteractionState() async {
    final user = FirebaseAuth.instance.currentUser;
    final pId = widget.reel.product.id;
    try {
      final doc = await _db.collection('Products').doc(pId).get();
      final data = doc.data();
      if (data != null && mounted) {
        final likedIds = List<String>.from(data['videoLikedUserIds'] as List? ?? const []);
        final storedLikes = (data['videoLikesCount'] as num?)?.toInt();
        final storedComments = (data['videoCommentsCount'] as num?)?.toInt();
        setState(() {
          if (user != null && likedIds.contains(user.uid)) _liked = true;
          if (storedLikes != null && storedLikes > 0) _likesCount = storedLikes;
          if (storedComments != null && storedComments > 0) _commentsCount = storedComments;
        });
      }
    } catch (_) {}
  }

  Future<void> _recordAdminInterest({
    required String source,
    required String actionSummary,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final p = widget.reel.product;
    final userName = Get.isRegistered<UserController>() &&
            UserController.instance.user.value.fullName.trim().isNotEmpty
        ? UserController.instance.user.value.fullName.trim()
        : (user.displayName ?? user.email?.split('@').first ?? 'Khách hàng');

    try {
      await _db.collection('UserInterests').doc(user.uid).set({
        'userId': user.uid,
        'userName': userName,
        'userEmail': user.email ?? '',
        'lastQuery': actionSummary,
        'lastSource': source, // 'video_like' | 'video_comment'
        'lastProductId': p.id,
        'lastProductTitle': p.title,
        'recentQueries': FieldValue.arrayUnion([actionSummary]),
        'interestedBrands': FieldValue.arrayUnion(['VELORA']),
        if (p.categoryName.isNotEmpty)
          'interestedCategories': FieldValue.arrayUnion([p.categoryName]),
        if (p.categoryId.isNotEmpty)
          'interestedCategoryIds': FieldValue.arrayUnion([p.categoryId]),
        'queryCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db.collection('Users').doc(user.uid).set({
        if (p.categoryId.isNotEmpty)
          'FavoriteCategoryIds': FieldValue.arrayUnion([p.categoryId]),
        'lastInterestProductId': p.id,
      }, SetOptions(merge: true));

      // Check AdminAutomationSettings to see if auto-push of similar products is enabled
      final autoDoc = await _db.collection('Settings').doc('AdminAutomation').get();
      final autoData = autoDoc.data() ?? const <String, dynamic>{};
      final autoPush = autoData['autoVideoSimilarPush'] != false;
      if (autoPush && p.categoryId.isNotEmpty) {
        final simSnap = await _db
            .collection('Products')
            .where('CategoryId', isEqualTo: p.categoryId)
            .limit(8)
            .get();
        final simDocs = simSnap.docs
            .map(ProductModel.fromSnapshot)
            .where((item) => item.id != p.id)
            .take(3)
            .toList();
        if (simDocs.isNotEmpty) {
          final simIds = simDocs.map((s) => s.id).toList();
          final simTitles = simDocs.map((s) => s.title).join(', ');
          await _db.collection('Users').doc(user.uid).set({
            'recommendedProductIds': FieldValue.arrayUnion(simIds),
          }, SetOptions(merge: true));

          final rawTpl = (autoData['templateVideoSimilarPush'] as String?)?.trim();
          final tpl = (rawTpl != null && rawTpl.isNotEmpty)
              ? rawTpl
              : 'Thấy {name} yêu thích video {product} — VELORA gợi ý thêm {similar} cùng dòng {category} đã được mở khóa trên tab Nổi bật Dành cho bạn!';
          final bodyVi = tpl
              .replaceAll('{name}', userName)
              .replaceAll('{product}', p.title)
              .replaceAll('{similar}', simTitles)
              .replaceAll('{category}', p.categoryName);
          final notifId = 'auto-sim-${p.id}';
          await _db
              .collection('Users')
              .doc(user.uid)
              .collection('Notifications')
              .doc(notifId)
              .set({
            'id': notifId,
            'kind': 'product',
            'targetId': simDocs.first.id,
            'imageUrl': simDocs.first.thumbnail,
            'titleVi': 'Gợi ý tương tự ${p.title}: ${simDocs.first.title}',
            'titleEn': 'Similar to ${p.title}: ${simDocs.first.title}',
            'bodyVi': bodyVi,
            'bodyEn':
                'Since you liked ${p.title}, check out $simTitles in your Featured feed!',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleLike({bool forceLike = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final nextLiked = forceLike ? true : !_liked;
    if (forceLike) {
      setState(() => _showHeartBurst = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showHeartBurst = false);
      });
    }
    if (nextLiked == _liked) return;

    setState(() {
      _liked = nextLiked;
      _likesCount = (_likesCount + (nextLiked ? 1 : -1)).clamp(0, 999999);
    });

    final p = widget.reel.product;
    if (nextLiked) {
      widget.onUserInteracted();
    }
    try {
      await _db.collection('Products').doc(p.id).set({
        'videoLikesCount': _likesCount,
        if (user != null)
          'videoLikedUserIds': nextLiked
              ? FieldValue.arrayUnion([user.uid])
              : FieldValue.arrayRemove([user.uid]),
      }, SetOptions(merge: true));

      if (nextLiked) {
        await _recordAdminInterest(
          source: 'video_like',
          actionSummary: '❤️ Thả tim video quảng cáo: ${p.title} (${p.categoryName})',
        );
      }
    } catch (_) {}
  }

  Future<void> _openCommentsSheet() async {
    final p = widget.reel.product;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: const Color(0xFF10221C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _ReelCommentsSheet(
        product: p,
        videoUrl: widget.reel.videoUrl,
        onCommentPosted: (commentText) async {
          setState(() => _commentsCount++);
          widget.onUserInteracted();
          try {
            await _db.collection('Products').doc(p.id).set({
              'videoCommentsCount': _commentsCount,
            }, SetOptions(merge: true));
          } catch (_) {}
          await _recordAdminInterest(
            source: 'video_comment',
            actionSummary: '💬 Bình luận video ${p.title}: "$commentText"',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.reel.product;
    final lang = Localizations.localeOf(context).languageCode;
    final effectivePrice = p.salePrice > 0 ? p.salePrice : p.price;

    return GestureDetector(
      onTap: () {
        if (_videoController == null || !_initialized) return;
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
            _pausedByUser = true;
          } else {
            _videoController!.play();
            _pausedByUser = false;
          }
        });
      },
      onDoubleTap: () => _toggleLike(forceLike: true),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video player or animated studio canvas while buffering
          if (_initialized && _videoController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            _AnimatedShoeBackdrop(
              product: p,
              animation: _floatCtrl,
            ),

          // 2. Subtle top & bottom gradient scrim for legible text
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x9905100C),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xE605100C),
                ],
                stops: [0.0, 0.22, 0.58, 1.0],
              ),
            ),
          ),

          // 3. Pause indicator icon
          if (_pausedByUser)
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 42),
              ),
            ),

          // 4. Double-tap heart burst animation
          if (_showHeartBurst)
            const Center(
              child: Icon(
                Icons.favorite_rounded,
                color: Color(0xFFFF4D6D),
                size: 110,
              ),
            ),

          // 5. Right-side TikTok action rail (Like, Comment, Mute, Wishlist)
          Positioned(
            right: 14,
            bottom: 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like / Heart button
                _ReelActionButton(
                  icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: _liked ? const Color(0xFFFF4D6D) : Colors.white,
                  label: '$_likesCount',
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 18),
                // Comment button
                _ReelActionButton(
                  icon: Iconsax.message_text_15,
                  iconColor: Colors.white,
                  label: '$_commentsCount',
                  onTap: _openCommentsSheet,
                ),
                const SizedBox(height: 18),
                // Wishlist button
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TFavouriteIcon(productId: p.id),
                ),
                const SizedBox(height: 4),
                const ShopText(
                  'Save',
                  style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                // Mute / Unmute
                _ReelActionButton(
                  icon: widget.isMuted ? Iconsax.volume_cross : Iconsax.volume_high,
                  iconColor: Colors.white,
                  label: lang == 'en'
                      ? (widget.isMuted ? 'Unmute' : 'Mute')
                      : (widget.isMuted ? 'Bật tiếng' : 'Tắt tiếng'),
                  onTap: widget.onToggleMute,
                ),
              ],
            ),
          ),

          // 6. Bottom caption & interactive Product Card overlay
          Positioned(
            left: 16,
            right: 78,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEABB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ShopText(
                        'VELORA · ${p.categoryName.isNotEmpty ? p.categoryName : "Running"}',
                        style: const TextStyle(
                          color: Color(0xFF102B23),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (widget.reel.totalProductVideos > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Video ${widget.reel.videoIndex + 1}/${widget.reel.totalProductVideos}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (widget.reel.isPersonalizedRecommendation)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFFD166).withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Text(
                          '✨ Gợi ý hợp gu bạn',
                          style: TextStyle(
                            color: Color(0xFFFFE599),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((p.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.description!,
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Product card CTA (full title & full price without ellipsis)
                InkWell(
                  onTap: () {
                    _videoController?.pause();
                    Get.to(() => ProductDetail(product: p));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14352B).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFDDEABB).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: p.thumbnail,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) =>
                                const Icon(Iconsax.shopping_bag, color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    formatShopMoney(effectivePrice, language: lang),
                                    style: const TextStyle(
                                      color: Color(0xFFDDEABB),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  if (p.salePrice > 0 && p.salePrice < p.price)
                                    Text(
                                      formatShopMoney(p.price, language: lang),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDEABB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const ShopText(
                            'Buy now',
                            style: TextStyle(
                              color: Color(0xFF102B23),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  const _ReelActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedShoeBackdrop extends StatelessWidget {
  const _AnimatedShoeBackdrop({
    required this.product,
    required this.animation,
  });

  final ProductModel product;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final dy = (animation.value - 0.5) * 20;
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.1),
              radius: 0.9,
              colors: [
                Color(0xFF1E5242),
                Color(0xFF0A1E17),
              ],
            ),
          ),
          child: Center(
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: CachedNetworkImage(
                  imageUrl: product.thumbnail,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReelCommentsSheet extends StatefulWidget {
  const _ReelCommentsSheet({
    required this.product,
    required this.videoUrl,
    required this.onCommentPosted,
  });

  final ProductModel product;
  final String videoUrl;
  final ValueChanged<String> onCommentPosted;

  @override
  State<_ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<_ReelCommentsSheet> {
  final _db = FirebaseFirestore.instance;
  final _ctrl = TextEditingController();
  bool _sending = false;

  static const List<String> _quickComments = [
    'Đôi này còn size 41 không shop?',
    'Phối màu VELORA đẹp xuất sắc 🔥',
    'Chạy bộ cự ly 10km êm không ạ?',
    'Cho mình xin mã voucher giảm giá nhé!',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);

    final user = FirebaseAuth.instance.currentUser;
    final authorName = Get.isRegistered<UserController>() &&
            UserController.instance.user.value.fullName.trim().isNotEmpty
        ? UserController.instance.user.value.fullName.trim()
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : (user?.email?.split('@').first ?? 'Khách hàng VELORA'));

    try {
      String adminReply = '';
      try {
        final autoSnap =
            await _db.collection('Settings').doc('AdminAutomation').get();
        final autoData = autoSnap.data() ?? const <String, dynamic>{};
        final autoReplyEnabled = autoData['autoVideoCommentReply'] != false;
        if (autoReplyEnabled) {
          final rawTpl =
              (autoData['templateVideoCommentReply'] as String?)?.trim();
          final tpl = (rawTpl != null && rawTpl.isNotEmpty)
              ? rawTpl
              : 'Cảm ơn {name} đã quan tâm video mẫu {product}! Đôi này đang sẵn đủ size EU 38–44 tại VELORA. Mình vừa mở khóa thêm vài mẫu {category} tương tự trên tab Nổi bật cho bạn tham khảo nhé ❤️';
          adminReply = tpl
              .replaceAll('{name}', authorName)
              .replaceAll('{product}', widget.product.title)
              .replaceAll(
                '{category}',
                widget.product.categoryName.isNotEmpty
                    ? widget.product.categoryName
                    : 'giày thể thao',
              );
        }
      } catch (_) {}

      await _db
          .collection('Products')
          .doc(widget.product.id)
          .collection('VideoComments')
          .add({
        'userId': user?.uid ?? '',
        'authorName': authorName,
        'text': text,
        'videoUrl': widget.videoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        if (adminReply.isNotEmpty) ...{
          'adminReply': adminReply,
          'adminReplyAt': FieldValue.serverTimestamp(),
        },
      });
      _ctrl.clear();
      widget.onCommentPosted(text);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bình luận • ${widget.product.title}',
                      softWrap: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db
                    .collection('Products')
                    .doc(widget.product.id)
                    .collection('VideoComments')
                    .orderBy('createdAt', descending: true)
                    .limit(40)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? const [];
                  final defaultComments = [
                    {
                      'authorName': 'Minh Hoàng',
                      'text': 'Form giày VELORA nhìn ngoài thực tế cực kỳ sắc nét, đệm đi êm lắm!',
                      'time': '2 giờ trước',
                    },
                    {
                      'authorName': 'Thanh Thảo',
                      'text': 'Mình mới nhận đôi này hôm qua, mang chạy 5km nhẹ tênh luôn ❤️',
                      'time': '5 giờ trước',
                    },
                    {
                      'authorName': 'Tuấn Kiệt',
                      'text': 'Phối đồ đi làm hay đi tập đều hợp, chuẩn hãng thiết kế riêng.',
                      'time': '1 ngày trước',
                    },
                  ];

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final doc in docs)
                        _buildCommentTile(
                          author: doc.data()['authorName'] as String? ?? 'Khách hàng',
                          text: doc.data()['text'] as String? ?? '',
                          time: (doc.data()['createdAt'] as Timestamp?) != null
                              ? DateFormat('dd/MM HH:mm')
                                  .format((doc.data()['createdAt'] as Timestamp).toDate())
                              : 'Vừa xong',
                          adminReply: doc.data()['adminReply'] as String?,
                          highlight: true,
                        ),
                      for (final c in defaultComments)
                        _buildCommentTile(
                          author: c['authorName']!,
                          text: c['text']!,
                          time: c['time']!,
                        ),
                    ],
                  );
                },
              ),
            ),
            // Quick comment pills (custom dark pills so TChipTheme never makes them white-on-white)
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: _quickComments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _send(_quickComments[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3C30),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFDDEABB).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      _quickComments[i],
                      style: const TextStyle(
                        color: Color(0xFFDDEABB),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận về mẫu giày này...',
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: _sending ? null : () => _send(),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFDDEABB),
                        foregroundColor: const Color(0xFF102B23),
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Iconsax.send_1, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile({
    required String author,
    required String text,
    required String time,
    String? adminReply,
    bool highlight = false,
  }) {
    final hasReply = adminReply != null && adminReply.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: highlight
                ? const Color(0xFFDDEABB)
                : Colors.white.withValues(alpha: 0.14),
            child: Text(
              author.isNotEmpty ? author.characters.first.toUpperCase() : 'V',
              style: TextStyle(
                color: highlight ? const Color(0xFF102B23) : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                ),
                if (hasReply) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173D31),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFDDEABB).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: Color(0xFFDDEABB),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Phản hồi từ VELORA',
                              style: TextStyle(
                                color: Color(0xFFDDEABB),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adminReply.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
