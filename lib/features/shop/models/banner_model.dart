import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  String imageUrl;
   final String targetScreen;
   final bool active;
   final String title;
   final String subtitle;
   final String videoUrl;
   final String? categoryId;
   final String? brandId;
   final int sortOrder;

  BannerModel(
      {required this.imageUrl,
      required this.targetScreen,
      required this.active,
      this.title = '', this.subtitle = '', this.videoUrl = '',
      this.categoryId, this.brandId, this.sortOrder = 0});

  Map<String, dynamic> toJson() {
    return {
      'ImageUrl': imageUrl,
      'TargetScreen': targetScreen,
      'Active': active,
      'Title': title, 'Subtitle': subtitle, 'VideoUrl': videoUrl,
      if (categoryId != null) 'CategoryId': categoryId,
      if (brandId != null) 'BrandId': brandId,
      'SortOrder': sortOrder,
    };
  }

  factory BannerModel.fromJson(Map<String, dynamic> data) => BannerModel(
    imageUrl: data['ImageUrl'] ?? '', targetScreen: data['TargetScreen'] ?? '',
    active: data['Active'] ?? false, title: data['Title'] ?? '',
    subtitle: data['Subtitle'] ?? '', videoUrl: data['VideoUrl'] ?? '',
    categoryId: data['CategoryId'], brandId: data['BrandId'], sortOrder: data['SortOrder'] ?? 0,
  );

  factory BannerModel.fromSnapShot(DocumentSnapshot snapshot) =>
      BannerModel.fromJson(Map<String, dynamic>.from(snapshot.data() as Map));

  factory BannerModel.fromQuerySnapshot(DocumentSnapshot<Object?> document) =>
      BannerModel.fromJson(Map<String, dynamic>.from(document.data() as Map));
}
