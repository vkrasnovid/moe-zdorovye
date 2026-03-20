import 'package:flutter/foundation.dart';

class Profile {
  final int? id;
  final String name;
  final int avatarColor;
  final bool isDefault;
  final DateTime createdAt;

  Profile({
    this.id,
    required this.name,
    required this.avatarColor,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Profile copyWith({
    int? id,
    String? name,
    int? avatarColor,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarColor: avatarColor ?? this.avatarColor,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    debugPrint('[Profile.toMap] DEBUG: serializing profile id=$id name=$name avatarColor=$avatarColor isDefault=$isDefault');
    return {
      if (id != null) 'id': id,
      'name': name,
      'avatar_color': avatarColor,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    final profile = Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      avatarColor: map['avatar_color'] as int,
      isDefault: (map['is_default'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
    debugPrint('[Profile.fromMap] DEBUG: deserialized profile id=${profile.id} name=${profile.name}');
    return profile;
  }
}
