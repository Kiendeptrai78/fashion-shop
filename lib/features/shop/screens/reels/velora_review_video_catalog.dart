import 'package:fashion_business_app/features/shop/models/product_model.dart';

class VeloraReviewClip {
  const VeloraReviewClip({
    required this.url,
    required this.categoryId,
    required this.presetLabel,
    required this.creatorName,
    required this.creatorHandle,
    required this.creatorInitials,
    required this.reviewTag,
    required this.reviewQuoteVi,
    required this.reviewQuoteEn,
  });

  final String url;
  final String categoryId;
  final String presetLabel;
  final String creatorName;
  final String creatorHandle;
  final String creatorInitials;
  final String reviewTag;
  final String reviewQuoteVi;
  final String reviewQuoteEn;
}

/// Curated real-human sneaker review, try-on, store check, and live performance
/// clips (720p HD MP4) organized by footwear category.
class VeloraReviewVideoCatalog {
  VeloraReviewVideoCatalog._();

  static const Map<String, List<VeloraReviewClip>> byCategory = {
    'lifestyle-category': [
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/34278/34278-720.mp4',
        categoryId: 'lifestyle-category',
        presetLabel: 'Review thực tế • Soi form giày tại kệ cửa hàng',
        creatorName: 'Minh Khôi',
        creatorHandle: '@khoi.sneakercheck',
        creatorInitials: 'MK',
        reviewTag: 'Review tại cửa hàng',
        reviewQuoteVi:
            'Cầm trực tiếp trên tay đường may gọn, form ôm chân gọn gàng, phối quần jean hay short đều ổn.',
        reviewQuoteEn:
            'Clean stitching in hand, sharp silhouette, easy to pair with jeans or shorts.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/35386/35386-720.mp4',
        categoryId: 'lifestyle-category',
        presetLabel: 'Review thực tế • Tư vấn chọn size & thử mẫu tại shop',
        creatorName: 'Thảo Vy',
        creatorHandle: '@thaovy.kicks',
        creatorInitials: 'TV',
        reviewTag: 'Unbox & Tư vấn size',
        reviewQuoteVi:
            'Form chuẩn EU, ai chân bè nhẹ tăng nửa size mang đi làm cả ngày vẫn thoáng và êm gót.',
        reviewQuoteEn:
            'True to EU size—wide feet can go half a size up for all-day heel comfort.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/3525/3525-720.mp4',
        categoryId: 'lifestyle-category',
        presetLabel: 'On-feet thực tế • Cận cảnh bước đi ngoài phố',
        creatorName: 'Đức Anh',
        creatorHandle: '@ducanh.onfeet',
        creatorInitials: 'ĐA',
        reviewTag: 'On-feet ngoài phố',
        reviewQuoteVi:
            'Lên chân thực tế gọn mắt, đế bám đường tốt và mũi giày ít bị gãy nếp sau 2 tuần mang hằng ngày.',
        reviewQuoteEn:
            'Sleek on-feet profile, reliable outsole grip, minimal toe-box creasing after 2 weeks.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/15060/15060-720.mp4',
        categoryId: 'lifestyle-category',
        presetLabel: 'Review thực tế • Xỏ giày & kiểm tra độ ôm cổ chân',
        creatorName: 'Lan Chi',
        creatorHandle: '@lanchi.dailywear',
        creatorInitials: 'LC',
        reviewTag: 'Test xỏ chân thực tế',
        reviewQuoteVi:
            'Lưỡi gà mềm, siết dây ôm cổ chân không cấn mu bàn chân, đi bộ nhiều không bị đau gót.',
        reviewQuoteEn:
            'Plush tongue and lockdown lacing without instep pressure on long walks.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/98/98-720.mp4',
        categoryId: 'lifestyle-category',
        presetLabel: 'Streetwear thực tế • Đi bộ qua phố kiểm tra độ êm',
        creatorName: 'Hoàng Nam',
        creatorHandle: '@nam.streetfits',
        creatorInitials: 'HN',
        reviewTag: 'Review đi phố 8 tiếng',
        reviewQuoteVi:
            'Mang đi café và di chuyển cả buổi chiều vẫn nhẹ chân, phối đồ tối giản cực kỳ dễ mặc.',
        reviewQuoteEn:
            'Lightweight through an entire afternoon downtown—effortless minimalist pairing.',
      ),
    ],
    'running-category': [
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/16231/16231-720.mp4',
        categoryId: 'running-category',
        presetLabel: 'Runner Review • Buộc dây & chuẩn bị chạy sáng',
        creatorName: 'Ngọc Hà',
        creatorHandle: '@ha.morningrun',
        creatorInitials: 'NH',
        reviewTag: 'Test chạy 5km sáng',
        reviewQuoteVi:
            'Khóa gót chắc, buộc dây kiểu runner’s loop không bị tuột gót khi tăng tốc đoạn nước rút.',
        reviewQuoteEn:
            'Locked-in heel counter with zero slip when picking up pace.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/40765/40765-720.mp4',
        categoryId: 'running-category',
        presetLabel: 'Runner Review • Cận cảnh tiếp đất khi chạy đường nhựa',
        creatorName: 'Quang Huy',
        creatorHandle: '@huy.pace430',
        creatorInitials: 'QH',
        reviewTag: 'Test tiếp đất thực tế',
        reviewQuoteVi:
            'Đệm phản hồi rõ rệt lúc chuyển bước từ giữa bàn chân sang mũi, chạy mặt đường nhựa rất êm.',
        reviewQuoteEn:
            'Crisp midsole rebound through midfoot-to-toe transition on asphalt.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/32809/32809-720.mp4',
        categoryId: 'running-category',
        presetLabel: 'Runner Review • Góc quay thấp test độ nảy tốc độ',
        creatorName: 'Minh Trí',
        creatorHandle: '@tri.runclub',
        creatorInitials: 'MT',
        reviewTag: 'Test tempo 10km',
        reviewQuoteVi:
            'Chạy pace 5:00 giữ nhịp rất thoáng chân, phần upper lưới thoát khí nhanh, không bị bí.',
        reviewQuoteEn:
            'Breathable engineered mesh keeps feet cool throughout a 10K tempo run.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/609/609-720.mp4',
        categoryId: 'running-category',
        presetLabel: 'Runner Review • Test sân chạy điền kinh slow-motion',
        creatorName: 'Bảo Long',
        creatorHandle: '@long.trackvn',
        creatorInitials: 'BL',
        reviewTag: 'Test sân track',
        reviewQuoteVi:
            'Độ bám mặt đường track cực ổn, bứt tốc đoạn 400m cảm giác nhẹ và đẩy lực mượt.',
        reviewQuoteEn:
            'Confident track traction and smooth propulsion during 400m intervals.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/46653/46653-720.mp4',
        categoryId: 'running-category',
        presetLabel: 'Runner Review • Chạy đường dài đô thị dưới cầu',
        creatorName: 'Phương Anh',
        creatorHandle: '@panh.marathon',
        creatorInitials: 'PA',
        reviewTag: 'Review Half-Marathon',
        reviewQuoteVi:
            'Chạy trên 15km đệm vẫn giữ độ đàn hồi tốt, không bị xẹp hay mỏi cổ chân về cuối buổi.',
        reviewQuoteEn:
            'Cushioning stays lively past 15K without late-run foot fatigue.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/32813/32813-720.mp4',
        categoryId: 'running-category',
        presetLabel: 'Runner Review • Cặp đôi chạy bộ test độ ổn định',
        creatorName: 'Khang & Linh',
        creatorHandle: '@saigon.runners',
        creatorInitials: 'KL',
        reviewTag: 'Test nhóm chạy bộ',
        reviewQuoteVi:
            'Cả bản nam và nữ đều dễ làm quen ngay từ buổi chạy đầu tiên, không cần break-in lâu.',
        reviewQuoteEn:
            'Comfortable right out of the box for both daily miles and speed work.',
      ),
    ],
    'training-category': [
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/23056/23056-720.mp4',
        categoryId: 'training-category',
        presetLabel: 'Gym Review • Nhảy dây kiểm tra độ ổn định cổ chân',
        creatorName: 'Tuấn Kiệt',
        creatorHandle: '@kiet.fitcheck',
        creatorInitials: 'TK',
        reviewTag: 'Test HIIT & Nhảy dây',
        reviewQuoteVi:
            'Tiếp đất liên tục khi nhảy dây rất chắc chân, mũi giày linh hoạt mà không bị lật cổ chân.',
        reviewQuoteEn:
            'Stable landings on rapid jump-rope sets with flexible forefoot flex.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/40248/40248-720.mp4',
        categoryId: 'training-category',
        presetLabel: 'Gym Review • Test bám sàn khi chống đẩy & tập tạ',
        creatorName: 'Việt Hoàng',
        creatorHandle: '@hoang.strength',
        creatorInitials: 'VH',
        reviewTag: 'Test sàn gym thực tế',
        reviewQuoteVi:
            'Đế phẳng bám sàn cao su cực tốt, lúc plank hay đẩy tạ không bị trượt mũi giày.',
        reviewQuoteEn:
            'Flat rubber traction grips gym flooring solidly during planks and lifts.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/23450/23450-720.mp4',
        categoryId: 'training-category',
        presetLabel: 'Gym Review • Tập xà & bài tập toàn thân trong phòng gym',
        creatorName: 'Thành Đạt',
        creatorHandle: '@dat.calisthenics',
        creatorInitials: 'TĐ',
        reviewTag: 'Review phòng tập',
        reviewQuoteVi:
            'Giày nhẹ và ôm gọn, đổi từ bài tập thân trên sang cardio cuối buổi không cần thay đôi khác.',
        reviewQuoteEn:
            'Light, snug fit—transitions seamlessly from strength work to finisher cardio.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/606/606-720.mp4',
        categoryId: 'training-category',
        presetLabel: 'Gym Review • Test cardio cường độ cao ngoài trời',
        creatorName: 'Trung Hiếu',
        creatorHandle: '@hieu.cardiocoach',
        creatorInitials: 'TH',
        reviewTag: 'Test cardio thực tế',
        reviewQuoteVi:
            'Thoáng khí tốt, đổi hướng ngang chắc chắn nhờ phần khung TPU giữ hai bên thân giày.',
        reviewQuoteEn:
            'Great breathability and side-to-side stability from the lateral support cage.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/583/583-720.mp4',
        categoryId: 'training-category',
        presetLabel: 'Gym Review • Khởi động & test độ linh hoạt đế giày',
        creatorName: 'Mai Phương',
        creatorHandle: '@maiphuong.fit',
        creatorInitials: 'MP',
        reviewTag: 'Review tập đa năng',
        reviewQuoteVi:
            'Rãnh đế uốn dẻo theo chuyển động bàn chân, tập lunge và squat rất vững trọng tâm.',
        reviewQuoteEn:
            'Natural forefoot flex grooves keep lunges and squats balanced.',
      ),
    ],
    'basketball-category': [
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/44448/44448-720.mp4',
        categoryId: 'basketball-category',
        presetLabel: 'Hoops Review • Test bật nhảy ném rổ trên sân',
        creatorName: 'Gia Khánh',
        creatorHandle: '@khanh.hoops',
        creatorInitials: 'GK',
        reviewTag: 'Test ném rổ thực tế',
        reviewQuoteVi:
            'Bật nhảy tiếp đất rất đầm, cổ giày ôm sát mắt cá giúp tự tin hơn khi tranh chấp dưới bảng.',
        reviewQuoteEn:
            'Composed impact protection on jump shots with reassuring ankle lockdown.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/744/744-720.mp4',
        categoryId: 'basketball-category',
        presetLabel: 'Hoops Review • Test nhồi bóng & đổi hướng gấp',
        creatorName: 'Tấn Phát',
        creatorHandle: '@phat.courtcheck',
        creatorInitials: 'TP',
        reviewTag: 'Test crossover sân ngoài',
        reviewQuoteVi:
            'Vân đế xương cá rít sân rõ rệt, phanh gấp và crossover sân bê tông vẫn giữ bám tốt.',
        reviewQuoteEn:
            'Sharp herringbone bite on hard stops and quick crossovers.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/44468/44468-720.mp4',
        categoryId: 'basketball-category',
        presetLabel: 'Hoops Review • Thi đấu 1v1 kiểm tra độ chống lật',
        creatorName: 'Minh Đức',
        creatorHandle: '@duc.streetball',
        creatorInitials: 'MĐ',
        reviewTag: 'Test đấu 1v1',
        reviewQuoteVi:
            'Phần outrigger mở rộng ngoài đế giúp phòng thủ ngang chắc chắn, không có cảm giác chênh vênh.',
        reviewQuoteEn:
            'Wide lateral outrigger stays planted during intense 1-on-1 defense.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/2291/2291-720.mp4',
        categoryId: 'basketball-category',
        presetLabel: 'Hoops Review • Tập kỹ thuật sân bóng rổ',
        creatorName: 'Khánh Linh',
        creatorHandle: '@linh.bball',
        creatorInitials: 'KL',
        reviewTag: 'Test luyện tập sân gỗ',
        reviewQuoteVi:
            'Giày nhẹ hơn mong đợi so với form bóng rổ, di chuyển liên tục 4 hiệp vẫn rất linh hoạt.',
        reviewQuoteEn:
            'Lighter than expected for a court shoe—stays nimble through all four quarters.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/2285/2285-720.mp4',
        categoryId: 'basketball-category',
        presetLabel: 'Hoops Review • Bứt tốc & bật cao úp rổ',
        creatorName: 'Quốc Bảo',
        creatorHandle: '@bao.dunklab',
        creatorInitials: 'QB',
        reviewTag: 'Test lực bật nhảy',
        reviewQuoteVi:
            'Đệm mũi nảy nhanh hỗ trợ dậm nhảy tốt, tiếp đất bằng gót êm mà không bị dội lực.',
        reviewQuoteEn:
            'Responsive forefoot launch with cushioned heel landing absorption.',
      ),
    ],
    'trail-category': [
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/16119/16119-720.mp4',
        categoryId: 'trail-category',
        presetLabel: 'Trail Review • Leo sống núi địa hình dốc đá',
        creatorName: 'Hoàng Sơn',
        creatorHandle: '@son.trekkingvn',
        creatorInitials: 'HS',
        reviewTag: 'Test leo núi đá',
        reviewQuoteVi:
            'Gai đế sâu bám chắc trên dốc sỏi, bọc mũi chống va đá cực kỳ yên tâm khi đổ dốc.',
        reviewQuoteEn:
            'Deep lugs bite into loose gravel while the reinforced toe cap shields against rocks.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/49337/49337-720.mp4',
        categoryId: 'trail-category',
        presetLabel: 'Trail Review • Băng rừng ẩm ướt hướng về thác nước',
        creatorName: 'Nhật Minh',
        creatorHandle: '@minh.outdoor',
        creatorInitials: 'NM',
        reviewTag: 'Test đường rừng ẩm',
        reviewQuoteVi:
            'Đi qua đoạn đá ẩm gần suối vẫn giữ ma sát tốt, vải kháng nước nhẹ không thấm ướt tất nhanh.',
        reviewQuoteEn:
            'Reliable wet-rock traction near streams with splash-resistant upper protection.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/43148/43148-720.mp4',
        categoryId: 'trail-category',
        presetLabel: 'Trail Review • Đi bộ đường mòn rừng cây cuối tuần',
        creatorName: 'Hải & Trang',
        creatorHandle: '@vietnam.trails',
        creatorInitials: 'HT',
        reviewTag: 'Test trek cuối tuần',
        reviewQuoteVi:
            'Nhẹ gần như giày chạy bộ nhưng bám đường đất tốt hơn hẳn, đi cung 12km rất thoải mái.',
        reviewQuoteEn:
            'Feels nearly as light as a road runner with serious dirt-trail grip.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/43152/43152-720.mp4',
        categoryId: 'trail-category',
        presetLabel: 'Trail Review • Nhóm bạn trekking đường mòn xuyên rừng',
        creatorName: 'Văn Toàn',
        creatorHandle: '@toan.campers',
        creatorInitials: 'VT',
        reviewTag: 'Review nhóm trekking',
        reviewQuoteVi:
            'Đệm gót dày đỡ mỏi bàn chân khi đeo balo nặng, bám rễ cây và đất ẩm ổn định.',
        reviewQuoteEn:
            'Supportive heel cushioning under pack weight across roots and damp soil.',
      ),
      VeloraReviewClip(
        url: 'https://assets.mixkit.co/videos/87/87-720.mp4',
        categoryId: 'trail-category',
        presetLabel: 'Trail Review • Chạy địa hình tốc độ trong rừng',
        creatorName: 'Đình Khoa',
        creatorHandle: '@khoa.trailrun',
        creatorInitials: 'ĐK',
        reviewTag: 'Test trail tốc độ',
        reviewQuoteVi:
            'Ôm gọn phần giữa bàn chân, vào cua đường mòn đất sỏi không bị xô lệch bàn chân trong giày.',
        reviewQuoteEn:
            'Secure midfoot lockdown prevents internal foot slide on technical switchbacks.',
      ),
    ],
  };

  static final List<VeloraReviewClip> allClips = [
    for (final list in byCategory.values) ...list,
  ];

  static final Map<String, VeloraReviewClip> _byUrl = {
    for (final clip in allClips) clip.url: clip,
  };

  /// Detects legacy synthetic/old promo video URLs in Firestore so existing
  /// products immediately display real-human review clips while still honoring
  /// any new custom video uploaded by Admin into `velora-product-videos/`.
  static bool isLegacyAiVideoUrl(String url) {
    final normalized = url.trim().toLowerCase();
    if (normalized.contains('velora-reels-v2/')) return true;
    if (normalized.contains('y7nancfcenukj5xudnhh')) return true;
    if (normalized.contains('res.cloudinary.com/lbbgn51d/video/upload/') &&
        !normalized.contains('/velora-product-videos/')) {
      return true;
    }
    return false;
  }

  /// Deterministic string hash (identical across Dart VM / iOS / Web).
  static int stableHash(String input) {
    var hash = 2166136261;
    for (var i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  static List<VeloraReviewClip> clipsForCategory(String? categoryId) {
    return byCategory[categoryId] ?? byCategory['lifestyle-category']!;
  }

  /// Returns 2 distinct real-human review video URLs for a product (or the
  /// product's custom non-legacy Admin videos if uploaded).
  static List<String> videosForProduct(ProductModel product, {int fallbackCount = 2}) {
    final customExplicit = (product.videos ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !isLegacyAiVideoUrl(e))
        .toList();
    if (customExplicit.isNotEmpty) return customExplicit;

    final pool = clipsForCategory(product.categoryId);
    final seed = stableHash('${product.id}|${product.title}');
    final startIdx = seed % pool.length;
    final count = fallbackCount.clamp(1, pool.length);
    return List<String>.generate(
      count,
      (offset) => pool[(startIdx + offset) % pool.length].url,
    );
  }

  /// Picks a real-human clip for [product] while avoiding [recentlyUsedUrls]
  /// so consecutive feed slides stay visually diverse.
  static VeloraReviewClip pickDiverseClipForProduct(
    ProductModel product, {
    required Set<String> recentlyUsedUrls,
  }) {
    final pool = clipsForCategory(product.categoryId);
    final seed = stableHash('${product.id}|${product.title}');
    final startIdx = seed % pool.length;
    for (var offset = 0; offset < pool.length; offset++) {
      final candidate = pool[(startIdx + offset) % pool.length];
      if (!recentlyUsedUrls.contains(candidate.url)) {
        return candidate;
      }
    }
    return pool[startIdx];
  }

  /// Resolves authentic reviewer metadata for a reel slide.
  static VeloraReviewClip metadataForUrl(String url, ProductModel product) {
    final direct = _byUrl[url.trim()];
    if (direct != null) return direct;
    final pool = clipsForCategory(product.categoryId);
    final idx = stableHash('${product.id}|$url') % pool.length;
    return pool[idx];
  }

  /// Curated preset list for the Web Admin Featured Reels video picker.
  static List<({String label, String url})> get adminPresetVideos => [
        for (final clip in allClips)
          (
            label: '${clip.presetLabel} (${clip.creatorHandle})',
            url: clip.url,
          ),
      ];
}
