import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/profiles_provider.dart';
import 'profile_form_dialog.dart';

class ProfileSwitcher extends StatelessWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfilesProvider>(
      builder: (context, provider, _) {
        final active = provider.activeProfile;
        return GestureDetector(
          onTap: () => _openProfileSheet(context, provider),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileAvatar(profile: active),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProfileSheet(BuildContext context, ProfilesProvider provider) {
    debugPrint('[ProfileSwitcher] DEBUG: bottom-sheet open, profiles=${provider.profiles.length}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProfileSheet(provider: provider),
    ).then((_) {
      debugPrint('[ProfileSwitcher] DEBUG: bottom-sheet closed');
    });
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Profile? profile;
  const _ProfileAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16));
    }
    final initials = profile!.name.isNotEmpty ? profile!.name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: Color(profile!.avatarColor),
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  final ProfilesProvider provider;
  const _ProfileSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<ProfilesProvider>(
        builder: (ctx, prov, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Профили',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...prov.profiles.map((profile) => _ProfileTile(
                        profile: profile,
                        isActive: prov.activeProfileId == profile.id,
                        canDelete: prov.profiles.length > 1,
                        onSelect: () {
                          debugPrint('[ProfileSwitcher] DEBUG: profile selected id=${profile.id} name=${profile.name}');
                          prov.setActiveProfile(profile.id!);
                          Navigator.pop(ctx);
                        },
                        onEdit: () {
                          Navigator.pop(ctx);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => ProfileFormDialog(
                              existingProfile: profile,
                              existingNames: prov.profiles
                                  .where((p) => p.id != profile.id)
                                  .map((p) => p.name)
                                  .toList(),
                            ),
                          );
                        },
                        onDelete: () async {
                          Navigator.pop(ctx);
                          await prov.deleteProfile(profile.id!);
                        },
                      )),
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF00897B),
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                    title: const Text('Добавить профиль'),
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => ProfileFormDialog(
                          existingNames: prov.profiles.map((p) => p.name).toList(),
                        ),
                      );
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
}

class _ProfileTile extends StatelessWidget {
  final Profile profile;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.canDelete,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';
    return GestureDetector(
      onLongPress: () => _showPopupMenu(context),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(profile.avatarColor),
          child: Text(
            initials,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(profile.name),
        trailing: isActive
            ? const Icon(Icons.radio_button_checked, color: Color(0xFF00897B))
            : const Icon(Icons.radio_button_off, color: Colors.grey),
        onTap: onSelect,
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx, offset.dy, offset.dx + renderBox.size.width, offset.dy + renderBox.size.height,
      ),
      items: [
        const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
        if (canDelete)
          const PopupMenuItem(value: 'delete', child: Text('Удалить')),
      ],
    ).then((value) {
      if (value == 'edit') onEdit();
      if (value == 'delete') onDelete();
    });
  }
}
