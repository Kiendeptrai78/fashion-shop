import 'package:fashion_business_app/utils/local_storage/local_utility.dart';

const shopperPreferencesKey = 'shopper_preferences_v1';
const ageGroups = <String, String>{
  'under18': 'Under 18', '18_24': '18–24', '25_34': '25–34',
  '35_44': '35–44', '45plus': '45+', 'unspecified': 'Prefer not to say',
};

class ShopperPreferences {
  const ShopperPreferences({this.completed = false, this.ageGroup = 'unspecified',
    this.categoryIds = const []});
  final bool completed;
  final String ageGroup;
  final List<String> categoryIds;

  factory ShopperPreferences.fromJson(Map<String, dynamic> data) => ShopperPreferences(
    completed: data['completed'] == true,
    ageGroup: ageGroups.containsKey(data['ageGroup']) ? data['ageGroup'] as String : 'unspecified',
    categoryIds: (data['categoryIds'] as List? ?? []).whereType<String>().toSet().toList(),
  );

  Map<String, dynamic> toJson() => {'completed': completed, 'ageGroup': ageGroup,
    'categoryIds': categoryIds};

  static ShopperPreferences load() {
    final data = TLocalStorage.instance().readData<Map<String, dynamic>>(shopperPreferencesKey);
    return data == null ? const ShopperPreferences() : ShopperPreferences.fromJson(data);
  }

  Future<void> save() => TLocalStorage.instance().saveData(shopperPreferencesKey, toJson());
}
