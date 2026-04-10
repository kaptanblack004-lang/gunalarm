import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gun_alarm_app.dart';

enum FamilyMemberRole {
  parent,
  child,
  teenager,
  adult,
}

enum FamilyAlarmType {
  shared,
  individual,
  group,
  emergency,
}

class FamilyMember {
  final String id;
  final String name;
  final String email;
  final FamilyMemberRole role;
  final String avatar;
  final bool isActive;
  final DateTime joinedAt;
  final List<String> permissions;

  FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatar,
    this.isActive = true,
    required this.joinedAt,
    this.permissions = const ['view', 'edit_own'],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString(),
      'avatar': avatar,
      'isActive': isActive,
      'joinedAt': joinedAt.toIso8601String(),
      'permissions': permissions,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: FamilyMemberRole.values.firstWhere(
        (role) => role.toString() == json['role'],
        orElse: () => FamilyMemberRole.adult,
      ),
      avatar: json['avatar'] ?? '',
      isActive: json['isActive'] ?? true,
      joinedAt: DateTime.parse(json['joinedAt']),
      permissions: List<String>.from(json['permissions'] ?? ['view', 'edit_own']),
    );
  }

  String get displayName {
    switch (role) {
      case FamilyMemberRole.parent:
        return '$name (Ebeveyn)';
      case FamilyMemberRole.child:
        return '$name (Çocuk)';
      case FamilyMemberRole.teenager:
        return '$name (Genç)';
      case FamilyMemberRole.adult:
        return name;
    }
  }

  Color get roleColor {
    switch (role) {
      case FamilyMemberRole.parent:
        return Colors.blue;
      case FamilyMemberRole.child:
        return Colors.green;
      case FamilyMemberRole.teenager:
        return Colors.orange;
      case FamilyMemberRole.adult:
        return Colors.purple;
    }
  }
}

class SharedAlarm {
  final String id;
  final String title;
  final TimeOfDay time;
  final List<String> memberIds;
  final FamilyAlarmType type;
  final String createdBy;
  final DateTime createdAt;
  final List<bool> selectedDays;
  final bool isActive;
  final String? note;
  final List<String> completedBy;

  SharedAlarm({
    required this.id,
    required this.title,
    required this.time,
    required this.memberIds,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    this.selectedDays = const [false, false, false, false, false, false, false],
    this.isActive = true,
    this.note,
    this.completedBy = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hour': time.hour,
      'minute': time.minute,
      'memberIds': memberIds,
      'type': type.toString(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'selectedDays': selectedDays,
      'isActive': isActive,
      'note': note,
      'completedBy': completedBy,
    };
  }

  factory SharedAlarm.fromJson(Map<String, dynamic> json) {
    return SharedAlarm(
      id: json['id'],
      title: json['title'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      type: FamilyAlarmType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => FamilyAlarmType.shared,
      ),
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      selectedDays: List<bool>.from(json['selectedDays'] ?? [false, false, false, false, false, false, false]),
      isActive: json['isActive'] ?? true,
      note: json['note'],
      completedBy: List<String>.from(json['completedBy'] ?? []),
    );
  }

  String get timeString => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String get typeDisplayName {
    switch (type) {
      case FamilyAlarmType.shared:
        return 'Paylaþýlan';
      case FamilyAlarmType.individual:
        return 'Kiþisel';
      case FamilyAlarmType.group:
        return 'Grup';
      case FamilyAlarmType.emergency:
        return 'Acil Durum';
    }
  }

  Color get typeColor {
    switch (type) {
      case FamilyAlarmType.shared:
        return Colors.blue;
      case FamilyAlarmType.individual:
        return Colors.green;
      case FamilyAlarmType.group:
        return Colors.orange;
      case FamilyAlarmType.emergency:
        return Colors.red;
    }
  }
}

class FamilySharingService {
  static final FamilySharingService _instance = FamilySharingService._internal();
  factory FamilySharingService() => _instance;
  FamilySharingService._internal();

  bool _isFamilyModeEnabled = false;
  String? _familyId;
  String? _familyName;
  List<FamilyMember> _familyMembers = [];
  List<SharedAlarm> _sharedAlarms = [];
  String? _currentUserId;

  bool get isFamilyModeEnabled => _isFamilyModeEnabled;
  String? get familyId => _familyId;
  String? get familyName => _familyName;
  List<FamilyMember> get familyMembers => List.from(_familyMembers);
  List<SharedAlarm> get sharedAlarms => List.from(_sharedAlarms);
  String? get currentUserId => _currentUserId;

  static const List<FamilyMember> _mockMembers = [
    FamilyMember(
      id: 'parent1',
      name: 'Anne',
      email: 'anne@family.com',
      role: FamilyMemberRole.parent,
      avatar: 'https://picsum.photos/seed/mom/100/100.jpg',
      joinedAt: DateTime.now().subtract(const Duration(days: 365)),
      permissions: ['view', 'edit_own', 'edit_shared', 'manage_family'],
    ),
    FamilyMember(
      id: 'parent2',
      name: 'Baba',
      email: 'baba@family.com',
      role: FamilyMemberRole.parent,
      avatar: 'https://picsum.photos/seed/dad/100/100.jpg',
      joinedAt: DateTime.now().subtract(const Duration(days: 365)),
      permissions: ['view', 'edit_own', 'edit_shared', 'manage_family'],
    ),
    FamilyMember(
      id: 'child1',
      name: 'Çocuk',
      email: 'cocuk@family.com',
      role: FamilyMemberRole.child,
      avatar: 'https://picsum.photos/seed/child/100/100.jpg',
      joinedAt: DateTime.now().subtract(const Duration(days: 180)),
      permissions: ['view', 'edit_own'],
    ),
    FamilyMember(
      id: 'teen1',
      name: 'Genç',
      email: 'genc@family.com',
      role: FamilyMemberRole.teenager,
      avatar: 'https://picsum.photos/seed/teen/100/100.jpg',
      joinedAt: DateTime.now().subtract(const Duration(days: 200)),
      permissions: ['view', 'edit_own', 'edit_shared'],
    ),
  ];

  static const List<SharedAlarm> _mockSharedAlarms = [
    SharedAlarm(
      id: 'shared1',
      title: 'Aile Kahvaltýsý',
      time: TimeOfDay(hour: 8, minute: 0),
      memberIds: ['parent1', 'parent2', 'child1', 'teen1'],
      type: FamilyAlarmType.shared,
      createdBy: 'parent1',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      selectedDays: [true, true, true, true, true, false, false],
      note: 'Her gün birlikte kahvaltý edelim!',
    ),
    SharedAlarm(
      id: 'shared2',
      title: 'Ödev Zamaný',
      time: TimeOfDay(hour: 16, minute: 30),
      memberIds: ['child1'],
      type: FamilyAlarmType.individual,
      createdBy: 'parent1',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      selectedDays: [true, true, true, true, true, false, false],
      note: 'Ödevlerini yapmayý unutma!',
    ),
    SharedAlarm(
      id: 'shared3',
      title: 'Aile Film Gecesi',
      time: TimeOfDay(hour: 20, minute: 0),
      memberIds: ['parent1', 'parent2', 'child1', 'teen1'],
      type: FamilyAlarmType.group,
      createdBy: 'parent2',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      selectedDays: [false, false, false, false, false, true, false],
      note: 'Cuma akþamý film izleme zamaný!',
    ),
    SharedAlarm(
      id: 'emergency1',
      title: 'Acil Durum Alarmý',
      time: TimeOfDay(hour: 7, minute: 0),
      memberIds: ['parent1', 'parent2'],
      type: FamilyAlarmType.emergency,
      createdBy: 'parent1',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      selectedDays: [true, true, true, true, true, true, true],
      note: 'Herkesin acil durumlar için',
    ),
  ];

  Future<void> initialize() async {
    await _loadSettings();
    await _loadMockData();
    
    debugPrint('=== FAMILY SHARING INITIALIZED ===');
    debugPrint('Family Mode: $_isFamilyModeEnabled');
    debugPrint('Family Members: ${_familyMembers.length}');
    debugPrint('Shared Alarms: ${_sharedAlarms.length}');
    debugPrint('===============================');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isFamilyModeEnabled = prefs.getBool('family_mode_enabled') ?? false;
    _familyId = prefs.getString('family_id');
    _familyName = prefs.getString('family_name');
    _currentUserId = prefs.getString('current_user_id') ?? 'parent1';
    
    final membersJson = prefs.getStringList('family_members') ?? [];
    _familyMembers = membersJson
        .map((json) => FamilyMember.fromJson(jsonDecode(json)))
        .toList();
    
    final alarmsJson = prefs.getStringList('shared_alarms') ?? [];
    _sharedAlarms = alarmsJson
        .map((json) => SharedAlarm.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _loadMockData() async {
    if (_familyMembers.isEmpty && _isFamilyModeEnabled) {
      _familyMembers = List.from(_mockMembers);
      _sharedAlarms = List.from(_mockSharedAlarms);
      _familyId = 'family_${DateTime.now().millisecondsSinceEpoch}';
      _familyName = 'Ailem';
      
      await _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('family_mode_enabled', _isFamilyModeEnabled);
    await prefs.setString('family_id', _familyId ?? '');
    await prefs.setString('family_name', _familyName ?? '');
    await prefs.setString('current_user_id', _currentUserId ?? '');
    
    final membersJson = _familyMembers
        .map((member) => jsonEncode(member.toJson()))
        .toList();
    await prefs.setStringList('family_members', membersJson);
    
    final alarmsJson = _sharedAlarms
        .map((alarm) => jsonEncode(alarm.toJson()))
        .toList();
    await prefs.setStringList('shared_alarms', alarmsJson);
  }

  Future<void> enableFamilyMode() async {
    _isFamilyModeEnabled = true;
    await _loadMockData();
    
    debugPrint('Family mode ENABLED');
  }

  Future<void> disableFamilyMode() async {
    _isFamilyModeEnabled = false;
    _familyId = null;
    _familyName = null;
    _familyMembers.clear();
    _sharedAlarms.clear();
    
    await _saveSettings();
    
    debugPrint('Family mode DISABLED');
  }

  Future<void> createFamily(String familyName) async {
    _familyName = familyName;
    _familyId = 'family_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserId = 'parent1';
    
    // Mevcut kullanýcýyý aileye ekle
    _familyMembers = [
      FamilyMember(
        id: _currentUserId!,
        name: 'Ben',
        email: 'me@family.com',
        role: FamilyMemberRole.parent,
        avatar: 'https://picsum.photos/seed/me/100/100.jpg',
        joinedAt: DateTime.now(),
        permissions: ['view', 'edit_own', 'edit_shared', 'manage_family'],
      ),
    ];
    
    await _saveSettings();
    
    debugPrint('Family created: $familyName');
  }

  Future<void> inviteFamilyMember(String email, String name, FamilyMemberRole role) async {
    final newMember = FamilyMember(
      id: 'member_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: role,
      avatar: 'https://picsum.photos/seed/$email/100/100.jpg',
      joinedAt: DateTime.now(),
      permissions: _getDefaultPermissions(role),
    );
    
    _familyMembers.add(newMember);
    await _saveSettings();
    
    debugPrint('Invited family member: $name ($email)');
  }

  List<String> _getDefaultPermissions(FamilyMemberRole role) {
    switch (role) {
      case FamilyMemberRole.parent:
        return ['view', 'edit_own', 'edit_shared', 'manage_family'];
      case FamilyMemberRole.adult:
        return ['view', 'edit_own', 'edit_shared'];
      case FamilyMemberRole.teenager:
        return ['view', 'edit_own', 'edit_shared'];
      case FamilyMemberRole.child:
        return ['view', 'edit_own'];
    }
  }

  Future<void> removeFamilyMember(String memberId) async {
    _familyMembers.removeWhere((member) => member.id == memberId);
    
    // Üyenin oluþturduðu alarmlarý da temizle
    _sharedAlarms.removeWhere((alarm) => alarm.createdBy == memberId);
    
    await _saveSettings();
    
    debugPrint('Removed family member: $memberId');
  }

  Future<void> createSharedAlarm({
    required String title,
    required TimeOfDay time,
    required List<String> memberIds,
    required FamilyAlarmType type,
    String? note,
    List<bool> selectedDays = const [false, false, false, false, false, false, false],
  }) async {
    final sharedAlarm = SharedAlarm(
      id: 'alarm_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      time: time,
      memberIds: memberIds,
      type: type,
      createdBy: _currentUserId!,
      createdAt: DateTime.now(),
      note: note,
      selectedDays: selectedDays,
    );
    
    _sharedAlarms.add(sharedAlarm);
    await _saveSettings();
    
    debugPrint('Created shared alarm: $title');
  }

  Future<void> updateSharedAlarm(SharedAlarm alarm) async {
    final index = _sharedAlarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _sharedAlarms[index] = alarm;
      await _saveSettings();
      
      debugPrint('Updated shared alarm: ${alarm.title}');
    }
  }

  Future<void> deleteSharedAlarm(String alarmId) async {
    _sharedAlarms.removeWhere((alarm) => alarm.id == alarmId);
    await _saveSettings();
    
    debugPrint('Deleted shared alarm: $alarmId');
  }

  Future<void> markAlarmCompleted(String alarmId, String memberId) async {
    final alarm = _sharedAlarms.firstWhere((a) => a.id == alarmId);
    
    if (!alarm.completedBy.contains(memberId)) {
      alarm.completedBy.add(memberId);
      await updateSharedAlarm(alarm);
      
      debugPrint('Alarm completed by $memberId: ${alarm.title}');
    }
  }

  List<SharedAlarm> getAlarmsForUser(String userId) {
    return _sharedAlarms.where((alarm) => 
      alarm.memberIds.contains(userId) && alarm.isActive
    ).toList();
  }

  List<SharedAlarm> getAlarmsCreatedByUser(String userId) {
    return _sharedAlarms.where((alarm) => 
      alarm.createdBy == userId && alarm.isActive
    ).toList();
  }

  List<SharedAlarm> getTodaySharedAlarms() {
    final now = DateTime.now();
    final todayIndex = now.weekday % 7; // Pazartesi = 1
    
    return _sharedAlarms.where((alarm) => 
      alarm.isActive &&
      alarm.memberIds.contains(_currentUserId ?? '') &&
      (alarm.selectedDays.isEmpty || alarm.selectedDays[todayIndex])
    ).toList();
  }

  Future<void> syncWithFamily() async {
    if (!_isFamilyModeEnabled) return;
    
    debugPrint('=== SYNCING WITH FAMILY ===');
    await Future.delayed(const Duration(seconds: 2));
    
    // Simüle edilmiþ senkronizasyon
    // Gerçek uygulamada burada cloud sync yapýlýr
    
    debugPrint('Family synced: ${_familyMembers.length} members, ${_sharedAlarms.length} alarms');
    debugPrint('========================');
  }

  Future<Map<String, dynamic>> getFamilyStatistics() async {
    if (!_isFamilyModeEnabled) return {};
    
    final todayAlarms = getTodaySharedAlarms();
    final userAlarms = getAlarmsForUser(_currentUserId ?? '');
    
    return {
      'totalMembers': _familyMembers.length,
      'activeMembers': _familyMembers.where((m) => m.isActive).length,
      'totalSharedAlarms': _sharedAlarms.length,
      'activeSharedAlarms': _sharedAlarms.where((a) => a.isActive).length,
      'todayAlarms': todayAlarms.length,
      'userAlarms': userAlarms.length,
      'alarmsCreatedByUser': getAlarmsCreatedByUser(_currentUserId ?? '').length,
      'familyName': _familyName,
      'currentRole': _familyMembers.firstWhere((m) => m.id == _currentUserId, orElse: () => _mockMembers.first).role.toString(),
    };
  }

  Future<void> exportFamilyData() async {
    final data = {
      'familyId': _familyId,
      'familyName': _familyName,
      'members': _familyMembers.map((m) => m.toJson()).toList(),
      'alarms': _sharedAlarms.map((a) => a.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
    
    debugPrint('Family data exported: ${data['members'].length} members, ${data['alarms'].length} alarms');
  }

  Future<void> importFamilyData(Map<String, dynamic> data) async {
    _familyId = data['familyId'];
    _familyName = data['familyName'];
    
    if (data['members'] != null) {
      _familyMembers = (data['members'] as List)
          .map((json) => FamilyMember.fromJson(json))
          .toList();
    }
    
    if (data['alarms'] != null) {
      _sharedAlarms = (data['alarms'] as List)
          .map((json) => SharedAlarm.fromJson(json))
          .toList();
    }
    
    _isFamilyModeEnabled = true;
    await _saveSettings();
    
    debugPrint('Family data imported successfully');
  }
}
