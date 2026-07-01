import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/user_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/shared/widgets/bottom_nav_bar.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).currentUser;
      if (user != null) {
        ref.read(chatProvider.notifier).loadChats(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final chatState = ref.watch(chatProvider);
    final chats = chatState.chats;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600)),
        backgroundColor: context.bgColor,
        automaticallyImplyLeading: false,
        actions: [
          // Clients can search for a property to chat about; owners respond to inbound messages.
          if (user?.isOwner == false)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: context.textColor),
              onPressed: () => context.push(AppRoutes.search),
              tooltip: 'Find a property to chat about',
            ),
        ],
      ),
      body: chatState.isLoadingChats
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, color: context.textSecColor, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        user?.isOwner == true
                            ? 'No conversations yet.\nClients will message you about your properties.'
                            : 'No conversations yet.\nFind a property and start chatting!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.textSecColor, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (_, i) {
                    final chat = chats[i];
                    final otherName = chat.participantNames
                        .firstWhere((n) => n != user?.username, orElse: () => 'Unknown');
                    final timeAgo = _formatTime(chat.lastMessageTime);

                    return _ChatTile(
                      name: otherName,
                      lastMessage: chat.lastMessage,
                      time: timeAgo,
                      unread: chat.unreadCount,
                      propertyTitle: chat.propertyTitle,
                      onTap: () => context.push(
                        AppRoutes.chatRoomPath(chat.id),
                        extra: {'title': otherName},
                      ),
                    ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: -0.1);
                  },
                ),
      bottomNavigationBar: user?.role == UserRole.owner
          ? const OwnerBottomNav(currentIndex: 3)
          : const ClientBottomNav(currentIndex: 3),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final String propertyTitle;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.propertyTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: context.textColor,
                fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          Text(time, style: TextStyle(color: context.textSecColor, fontSize: 11)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lastMessage,
            style: TextStyle(
              color: unread > 0 ? context.textColor : context.textSecColor,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Re: $propertyTitle',
            style: TextStyle(color: context.textMutedColor, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Text(
                '$unread',
                style: const TextStyle(color: AppColors.black, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      ),
    );
  }
}
