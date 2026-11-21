import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/data/repositories/reviews/review_repository.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class ProductReview extends StatefulWidget {
  const ProductReview({super.key, this.productId, this.productTitle, this.loadReviews});
  final String? productId, productTitle;
  final Future<List<ProductReviewEntry>> Function()? loadReviews;
  @override
  State<ProductReview> createState() => _ProductReviewState();
}

class _ProductReviewState extends State<ProductReview> {
  late Future<List<ProductReviewEntry>> _reviews;
  int _star = 0;
  @override
  void initState() { super.initState(); _reviews = _load(); }
  Future<List<ProductReviewEntry>> _load() => widget.loadReviews?.call()
      ?? (widget.productId == null ? Future.value([]) : ReviewRepository().fetchRecent(widget.productId!));
  Future<void> _refresh() async {
    final next = _load();
    setState(() { _reviews = next; });
    try { await next; } catch (_) { /* Inline retry below. */ }
  }

  Future<void> _write() async {
    final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      useSafeArea: true, builder: (_) => _WriteReview(productId: widget.productId!));
    if (saved == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const TAppbar(showBackArrow: true, title: ShopText('Customer reviews',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
      body: FutureBuilder<List<ProductReviewEntry>>(future: _reviews, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ShopText('Couldn’t load reviews.'),
          TextButton(onPressed: _refresh, child: const ShopText('Try again')),
        ]));
        final reviews = snapshot.data ?? [];
        final summary = ProductReviewSummary(reviews);
        final filtered = reviews.where((review) => _star == 0 || review.rating == _star).toList();
        return RefreshIndicator(onRefresh: _refresh, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24), children: [
            if (widget.productTitle != null) Text(widget.productTitle!,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.7)),
            const SizedBox(height: 12),
            const ShopText('Real experiences. Better choices.', style: TextStyle(height: 1.6)),
            const SizedBox(height: 28),
            if (reviews.isNotEmpty) ...[
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(summary.average.toStringAsFixed(1), style: const TextStyle(fontSize: 52,
                      height: 1, fontWeight: FontWeight.w600, letterSpacing: -2)),
                  const SizedBox(height: 10), _stars(summary.average),
                  const SizedBox(height: 10), ShopText('${summary.count} recent reviews', style: theme.textTheme.bodySmall),
                ]),
                const SizedBox(width: 24),
                Expanded(child: Column(children: [for (var star = 5; star >= 1; star--)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
                    Text('$star', style: theme.textTheme.labelSmall), const SizedBox(width: 8),
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                      minHeight: 5, value: summary.stars[star]! / summary.count,
                      color: theme.colorScheme.primary, backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.07)))),
                    const SizedBox(width: 8), Text('${summary.stars[star]}', style: theme.textTheme.labelSmall),
                  ])),
                ])),
              ]),
              const Divider(height: 40),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final star in [0, 5, 4, 3, 2, 1])
                ChoiceChip(selected: _star == star, selectedColor: theme.colorScheme.primary,
                  label: ShopText(star == 0 ? 'All' : '$star ★', style: TextStyle(
                      color: _star == star ? Colors.white : theme.colorScheme.primary)),
                  onSelected: (_) => setState(() => _star = star)),
              ]),
              const SizedBox(height: 24),
            ],
            if (filtered.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [
              Icon(Icons.rate_review_outlined, size: 52, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              ShopText(widget.productId == null ? 'Choose a pair to see its reviews.'
                  : reviews.isEmpty ? 'Be the first to share your experience.' : 'No reviews with this rating yet.',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              const ShopText('Reviews can be shared after an order is received.', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.7)),
            ])),
            for (final review in filtered) Padding(padding: const EdgeInsets.only(bottom: 28), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [CircleAvatar(backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.07),
                    child: Text(review.authorName.trim().isEmpty ? 'K' : review.authorName.characters.first.toUpperCase(),
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShopText(review.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (review.createdAt != null) Text(DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                        .format(review.createdAt!), style: theme.textTheme.labelSmall),
                  ])),
                ]),
                const SizedBox(height: 14), _stars(review.rating.toDouble()),
                const SizedBox(height: 12), Text(review.text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                if (review.hasAdminReply) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 15, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Phản hồi từ VELORA',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (review.adminReplyAt != null) ...[
                              const Spacer(),
                              Text(
                                DateFormat.yMMMd(
                                        Localizations.localeOf(context).languageCode)
                                    .format(review.adminReplyAt!),
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          review.adminReply!,
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24), const Divider(height: 1),
              ],
            )),
          ],
        ));
      }),
      bottomNavigationBar: widget.productId == null ? null : SafeArea(top: false,
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 20), child: ElevatedButton(
          onPressed: _write, child: const ShopText('Write a review'))),
    );
  }

  Widget _stars(double rating) => Row(mainAxisSize: MainAxisSize.min, children: [for (var star = 1; star <= 5; star++)
    Icon(rating >= star ? Icons.star_rounded : rating >= star - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded,
        size: 17, color: Theme.of(context).colorScheme.primary)]);
}

class _WriteReview extends StatefulWidget {
  const _WriteReview({required this.productId});
  final String productId;
  @override
  State<_WriteReview> createState() => _WriteReviewState();
}

class _WriteReviewState extends State<_WriteReview> {
  final _text = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  String? _error;
  @override
  void dispose() { _text.dispose(); super.dispose(); }
  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await ReviewRepository().save(widget.productId, _rating, _text.text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error is StateError ? error.message.toString() : 'Couldn’t save your review. Please try again.');
    } finally { if (mounted) setState(() => _saving = false); }
  }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
    child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ShopText('How does this pair feel?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 20),
      Row(children: [for (var star = 1; star <= 5; star++) IconButton(
        tooltip: '$star ★', onPressed: _saving ? null : () => setState(() => _rating = star),
        icon: Icon(star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 32, color: Theme.of(context).colorScheme.primary)),
      ]),
      const SizedBox(height: 18),
      TextField(controller: _text, minLines: 3, maxLines: 6, maxLength: 1000, enabled: !_saving,
          decoration: InputDecoration(hintText: 'Fit, comfort and what you like about this pair...'.tr)),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 14),
          child: ShopText(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving || _rating == 0 ? null : _save,
          child: ShopText(_saving ? 'Saving changes...' : 'Publish review'))),
    ])),
  );
}
