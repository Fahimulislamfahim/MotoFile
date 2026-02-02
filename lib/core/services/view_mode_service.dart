import 'package:shared_preferences/shared_preferences.dart';

enum ViewMode {
  grid,
  list,
  card,
}

class ViewModeService {
  static const String _viewModeKey = 'view_mode';

  // Get saved view mode
  Future<ViewMode> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_viewModeKey);
    
    if (modeString == null) {
      return ViewMode.grid; // Default
    }
    
    return ViewMode.values.firstWhere(
      (mode) => mode.name == modeString,
      orElse: () => ViewMode.grid,
    );
  }

  // Save view mode
  Future<void> saveViewMode(ViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode.name);
  }
}
