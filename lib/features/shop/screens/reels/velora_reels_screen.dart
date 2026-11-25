import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/loaders/loader.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/favourite_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/features/shop/screens/reels/velora_review_video_catalog.dart';
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
    return VeloraReviewVideoCatalog.videosForProduct(p, fallbackCount: 2);
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
    final usedUrls = <String>{};
    for (final p in filteredProducts) {
      final customExplicit = (p.videos ?? const <String>[])
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !VeloraReviewVideoCatalog.isLegacyAiVideoUrl(e))
          .toList();
      final isInitial =
          widget.initialProduct != null && p.id == widget.initialProduct!.id;
      final isRec = _recommendedProductIds.contains(p.id);

      if (isInitial) {
        final vids = _videosForProduct(p);
        for (var i = 0; i < vids.length; i++) {
          usedUrls.add(vids[i]);
          items.add(VeloraReelItem(
            id: '${p.id}_v$i',
            product: p,
            videoUrl: vids[i],
            videoIndex: i,
            totalProductVideos: vids.length,
            isPersonalizedRecommendation: isRec,
          ));
        }
      } else if (customExplicit.isNotEmpty) {
        usedUrls.add(customExplicit.first);
        items.add(VeloraReelItem(
          id: '${p.id}_v0',
          product: p,
          videoUrl: customExplicit.first,
          videoIndex: 0,
          totalProductVideos: customExplicit.length,
          isPersonalizedRecommendation: isRec,
        ));
      } else {
        // Pick a fresh real-human reviewer clip so consecutive slides never repeat.
        final pool = VeloraReviewVideoCatalog.clipsForCategory(p.categoryId);
        if (pool.every((c) => usedUrls.contains(c.url))) {
          for (final c in pool) {
            usedUrls.remove(c.url);
          }
        }
        final picked = VeloraReviewVideoCatalog.pickDiverseClipForProduct(
          p,
          recentlyUsedUrls: usedUrls,
        );
        usedUrls.add(picked.url);
        items.add(VeloraReelItem(
          id: '${p.id}_v0',
          product: p,
          videoUrl: picked.url,
          videoIndex: 0,
          totalProductVideos: 2,
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
                          ? 'Chưa có video review thực tế nào trong danh mục này.'
                          : 'No product review videos in this category yet.',
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
                                Icons.play_circle_filled_rounded,
                                color: Color(0xFFDDEABB),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isVi ? 'VELORA REVIEW' : 'VELORA REVIEWS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
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

class _VeloraReelSlideState extends State<_VeloraReelSlide> {
  final _db = FirebaseFirestore.instance;
  VideoPlayerController? _videoController;
  bool _initialized = false;
  bool _pausedByUser = false;
  bool _liked = false;
  bool _videoSaved = false;
  int _likesCount = 24;
  int _commentsCount = 3;
  bool _showHeartBurst = false;

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
      if (user != null) {
        final uDoc = await _db.collection('Users').doc(user.uid).get();
        final savedVideos =
            List<String>.from(uDoc.data()?['savedReelVideos'] as List? ?? const []);
        final isFav = Get.isRegistered<FavouritesController>() &&
            FavouritesController.instance.isFavourite(pId);
        if (mounted && (savedVideos.contains(widget.reel.id) || isFav)) {
          setState(() => _videoSaved = true);
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleSaveVideoAndProduct() async {
    final p = widget.reel.product;
    final user = FirebaseAuth.instance.currentUser;
    final nextSaved = !_videoSaved;
    setState(() => _videoSaved = nextSaved);

    if (Get.isRegistered<FavouritesController>()) {
      final favCtrl = FavouritesController.instance;
      if (favCtrl.isFavourite(p.id) != nextSaved) {
        favCtrl.toggleFavouriteProduct(p.id);
      }
    }

    if (user != null) {
      try {
        await _db.collection('Users').doc(user.uid).set({
          'savedReelVideos': nextSaved
              ? FieldValue.arrayUnion([widget.reel.id])
              : FieldValue.arrayRemove([widget.reel.id]),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    if (nextSaved) {
      widget.onUserInteracted();
    }
  }

  Future<void> _openSaveAndShareSheet() async {
    final p = widget.reel.product;
    final lang = Localizations.localeOf(context).languageCode;
    final isVi = lang != 'en';
    final effectivePrice = p.salePrice > 0 ? p.salePrice : p.price;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      backgroundColor: const Color(0xFF0E211B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isSaved = _videoSaved ||
              (Get.isRegistered<FavouritesController>() &&
                  FavouritesController.instance.isFavourite(p.id));
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Product header preview
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: p.thumbnail,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                            Iconsax.shopping_bag,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              softWrap: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formatShopMoney(effectivePrice, language: lang),
                              style: const TextStyle(
                                color: Color(0xFFDDEABB),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Lưu video & sản phẩm
                  _ReelSheetActionTile(
                    icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    iconColor: isSaved
                        ? const Color(0xFF102B23)
                        : const Color(0xFFDDEABB),
                    iconBg: isSaved
                        ? const Color(0xFFDDEABB)
                        : Colors.white.withValues(alpha: 0.1),
                    title: isSaved
                        ? (isVi ? 'Đã lưu video & Yêu thích' : 'Saved to Favorites & Videos')
                        : (isVi ? 'Lưu video & Yêu thích sản phẩm' : 'Save Video & Add to Favorites'),
                    subtitle: isSaved
                        ? (isVi
                            ? 'Xem lại bất cứ lúc nào trong mục Tài khoản → Yêu thích'
                            : 'View anytime in Account → Saved Pairs')
                        : (isVi
                            ? 'Lưu lại video này và đôi giày vào danh sách yêu thích'
                            : 'Keep this reel and sneaker in your saved collection'),
                    onTap: () async {
                      await _toggleSaveVideoAndProduct();
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. Chia sẻ video & mẫu giày
                  _ReelSheetActionTile(
                    icon: Iconsax.share,
                    iconColor: const Color(0xFF7DD3FC),
                    iconBg: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    title: isVi ? 'Chia sẻ video & mẫu giày' : 'Share Video & Sneaker',
                    subtitle: isVi
                        ? 'Sao chép liên kết giới thiệu để gửi qua Zalo, Messenger...'
                        : 'Copy shareable link & sneaker info to clipboard',
                    onTap: () async {
                      final shareText =
                          '🔥 Xem ngay mẫu ${p.title} (${formatShopMoney(effectivePrice, language: lang)}) chính hãng VELORA!\n🎬 Video thực tế: ${widget.reel.videoUrl}';
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      TLoaders.successSnackBar(
                        title: isVi ? 'Đã sao chép liên kết chia sẻ' : 'Share link copied',
                        message: isVi
                            ? 'Bạn có thể dán để gửi cho bạn bè qua Zalo hoặc Messenger!'
                            : 'Paste anywhere to share this VELORA reel with friends!',
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 3. Xem chi tiết sản phẩm
                  _ReelSheetActionTile(
                    icon: Iconsax.bag_2,
                    iconColor: const Color(0xFFDDEABB),
                    iconBg: const Color(0xFF1E4D3E).withValues(alpha: 0.6),
                    title: isVi ? 'Xem chi tiết & chọn size EU' : 'View Details & Choose EU Size',
                    subtitle: isVi
                        ? 'Mở trang sản phẩm để xem ảnh thực tế, đánh giá và đặt mua'
                        : 'Open product page for gallery, reviews & checkout',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _videoController?.pause();
                      Get.to(() => ProductDetail(product: p));
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
            'pushPending': true,
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
    final isVi = lang != 'en';
    final effectivePrice = p.salePrice > 0 ? p.salePrice : p.price;
    final clipMeta = VeloraReviewVideoCatalog.metadataForUrl(
      widget.reel.videoUrl,
      p,
    );

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
          // 1. Real video player or clean dark buffering placeholder
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
            const ColoredBox(
              color: Color(0xFF0A0D0C),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white54,
                  ),
                ),
              ),
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

          // 5. Right-side refined Reels action rail (Like, Comment, Unified Save & Share, Mute)
          Positioned(
            right: 12,
            bottom: 138,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like / Heart button
                _ReelActionButton(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: _liked ? const Color(0xFFFF4D6D) : Colors.white,
                  activeBg: _liked
                      ? const Color(0xFFFF4D6D).withValues(alpha: 0.22)
                      : null,
                  label: '$_likesCount',
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 16),
                // Comment button
                _ReelActionButton(
                  icon: Iconsax.message_text_15,
                  iconColor: Colors.white,
                  label: '$_commentsCount',
                  onTap: _openCommentsSheet,
                ),
                const SizedBox(height: 16),
                // Unified Save Video + Share single icon button
                _ReelActionButton(
                  icon: _videoSaved
                      ? Icons.bookmark_added_rounded
                      : Iconsax.share,
                  iconColor:
                      _videoSaved ? const Color(0xFFDDEABB) : Colors.white,
                  activeBg: _videoSaved
                      ? const Color(0xFF173E32).withValues(alpha: 0.78)
                      : null,
                  showHighlightDot: _videoSaved,
                  label: lang == 'en' ? 'Save / Share' : 'Lưu · Chia sẻ',
                  onTap: _openSaveAndShareSheet,
                ),
                const SizedBox(height: 16),
                // Mute / Unmute
                _ReelActionButton(
                  icon: widget.isMuted
                      ? Iconsax.volume_cross
                      : Iconsax.volume_high,
                  iconColor: Colors.white,
                  label: lang == 'en'
                      ? (widget.isMuted ? 'Unmute' : 'Mute')
                      : (widget.isMuted ? 'Bật tiếng' : 'Tắt tiếng'),
                  onTap: widget.onToggleMute,
                ),
              ],
            ),
          ),

          // 6. Bottom caption, sleek product glass card & thin video scrubber
          Positioned(
            left: 16,
            right: 84,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Real reviewer creator strip (TikTok / Shopee Video style)
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F5444), Color(0xFF0E2921)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDDEABB),
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        clipMeta.creatorInitials,
                        style: const TextStyle(
                          color: Color(0xFFDDEABB),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  clipMeta.creatorName,
                                  softWrap: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFFDDEABB),
                                size: 14,
                              ),
                            ],
                          ),
                          Text(
                            '${clipMeta.creatorHandle} · ${clipMeta.reviewTag}',
                            softWrap: true,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEABB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: ShopText(
                        'VELORA · ${p.categoryName.isNotEmpty ? p.categoryName : "Running"}',
                        style: const TextStyle(
                          color: Color(0xFF102B23),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (widget.reel.totalProductVideos > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'Review ${widget.reel.videoIndex + 1}/${widget.reel.totalProductVideos}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (widget.reel.isPersonalizedRecommendation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFFFD166).withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Text(
                          'Hợp gu bạn',
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
                  softWrap: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '“${isVi ? clipMeta.reviewQuoteVi : clipMeta.reviewQuoteEn}”',
                  softWrap: true,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Luxury Glass Product Card CTA
                InkWell(
                  onTap: () {
                    _videoController?.pause();
                    Get.to(() => ProductDetail(product: p));
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF14362B).withValues(alpha: 0.94),
                          const Color(0xFF0C221B).withValues(alpha: 0.96),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFDDEABB).withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: p.thumbnail,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(
                              Iconsax.shopping_bag,
                              color: Colors.white54,
                            ),
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
                                  fontWeight: FontWeight.w800,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDEABB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShopText(
                                'Buy now',
                                style: TextStyle(
                                  color: Color(0xFF102B23),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: Color(0xFF102B23),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 7. Sleek thin video progress bar along the very bottom edge
          if (_initialized && _videoController != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: VideoProgressColors(
                  playedColor: const Color(0xFFDDEABB),
                  bufferedColor: Colors.white.withValues(alpha: 0.25),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
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
    this.activeBg,
    this.showHighlightDot = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Color? activeBg;
  final bool showHighlightDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: activeBg ?? Colors.black.withValues(alpha: 0.42),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: showHighlightDot
                        ? const Color(0xFFDDEABB).withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.24),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              if (showHighlightDot)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDEABB),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0A1E17),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelSheetActionTile extends StatelessWidget {
  const _ReelSheetActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      softWrap: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      softWrap: true,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
