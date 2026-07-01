import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taftaf/core/models/ad_model.dart';
import 'package:taftaf/core/models/booking_model.dart';
import 'package:taftaf/core/services/booking_service.dart';
import 'package:taftaf/core/models/message_model.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/models/transaction_model.dart';
import 'package:taftaf/core/models/user_model.dart';
import 'package:taftaf/core/services/auth_service.dart';
import 'package:taftaf/core/services/chat_service.dart';
import 'package:taftaf/core/services/property_service.dart';

// ─── Service Providers ───────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final propertyServiceProvider = Provider<PropertyService>((_) => PropertyService());
final chatServiceProvider = Provider<ChatService>((_) => ChatService());

// ─── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? currentUser;
  final bool isLoading;
  final String? error;

  const AuthState({this.currentUser, this.isLoading = false, this.error});

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({UserModel? currentUser, bool? isLoading, String? error, bool clearUser = false}) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service) : super(const AuthState(isLoading: true)) {
    _init();
  }

  final AuthService _service;

  Future<void> _init() async {
    try {
      final user = await _service.getPersistedSession();
      state = state.copyWith(currentUser: user, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.login(identifier, password);
      state = state.copyWith(currentUser: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> signup(String username, String email, String phone, UserRole role, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.signup(username, email, phone, role, password);
      state = state.copyWith(currentUser: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }

  Future<void> updateProfile({
    String? username,
    String? profilePic,
    String? coverPhoto,
    String? email,
    String? phone,
  }) async {
    await _service.updateProfile(
      username: username,
      profilePic: profilePic,
      coverPhoto: coverPhoto,
      email: email,
      phone: phone,
    );
    state = state.copyWith(
      currentUser: state.currentUser?.copyWith(
        username: username,
        profilePic: profilePic,
        coverPhoto: coverPhoto,
        email: email,
        phone: phone,
      ),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _service.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> sendPasswordResetOtp(String email) =>
      _service.sendPasswordResetOtp(email);

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      _service.resetPasswordWithOtp(email: email, otp: otp, newPassword: newPassword);

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

// ─── Property State ───────────────────────────────────────────────────────────

class PropertyState {
  final List<PropertyModel> properties;
  final bool isLoading;
  final String? error;
  final PropertyType? selectedType;
  final String searchQuery;

  const PropertyState({
    this.properties = const [],
    this.isLoading = false,
    this.error,
    this.selectedType,
    this.searchQuery = '',
  });

  List<PropertyModel> get filtered {
    var list = properties;
    if (selectedType != null) list = list.where((p) => p.type == selectedType).toList();
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  PropertyState copyWith({
    List<PropertyModel>? properties,
    bool? isLoading,
    String? error,
    PropertyType? selectedType,
    String? searchQuery,
    bool clearType = false,
  }) {
    return PropertyState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class PropertyNotifier extends StateNotifier<PropertyState> {
  PropertyNotifier(this._service) : super(const PropertyState());

  final PropertyService _service;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final props = await _service.fetchProperties();
      state = state.copyWith(properties: props, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadByOwner(String ownerId) async {
    state = state.copyWith(isLoading: true);
    try {
      final props = await _service.fetchProperties(ownerId: ownerId);
      state = state.copyWith(properties: props, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectType(PropertyType? type) {
    if (type == null || type == state.selectedType) {
      state = state.copyWith(clearType: true);
    } else {
      state = state.copyWith(selectedType: type);
    }
  }

  void search(String query) => state = state.copyWith(searchQuery: query);

  Future<void> toggleLike(String propertyId, String userId) async {
    try {
      final updated = await _service.toggleLike(propertyId, userId);
      final list = state.properties.map((p) => p.id == propertyId ? updated : p).toList();
      state = state.copyWith(properties: list);
    } catch (_) {}
  }

  Future<PropertyModel?> addProperty(PropertyModel property) async {
    try {
      final added = await _service.addProperty(property);
      state = state.copyWith(properties: [...state.properties, added]);
      return added;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> updateProperty(PropertyModel property) async {
    try {
      final updated = await _service.updateProperty(property);
      state = state.copyWith(
        properties: state.properties.map((p) => p.id == updated.id ? updated : p).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> verifyProperty(String propertyId) async {
    try {
      final prop = state.properties.firstWhere((p) => p.id == propertyId);
      final updated = await _service.updateProperty(prop.copyWith(isVerified: true));
      state = state.copyWith(
        properties: state.properties.map((p) => p.id == propertyId ? updated : p).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      await _service.deleteProperty(id);
      state = state.copyWith(
        properties: state.properties.where((p) => p.id != id).toList(),
      );
    } catch (_) {}
  }

  /// Increments the view count for [propertyId] and updates live state so
  /// the owner's analytics reflect the change without a full reload.
  Future<void> incrementView(String propertyId) async {
    try {
      await _service.incrementView(propertyId);
      state = state.copyWith(
        properties: state.properties.map((p) {
          if (p.id != propertyId) return p;
          return p.copyWith(viewCount: p.viewCount + 1);
        }).toList(),
      );
    } catch (_) {}
  }
}

final propertyProvider = StateNotifierProvider<PropertyNotifier, PropertyState>((ref) {
  return PropertyNotifier(ref.read(propertyServiceProvider));
});

// ─── Favorites ───────────────────────────────────────────────────────────────

final favoritesProvider = FutureProvider.family<List<PropertyModel>, String>((ref, userId) async {
  final service = ref.read(propertyServiceProvider);
  return service.fetchFavorites(userId);
});

// ─── Chat State ───────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatModel> chats;
  final List<MessageModel> messages;
  final bool isLoadingChats;

  const ChatState({
    this.chats = const [],
    this.messages = const [],
    this.isLoadingChats = false,
  });

  ChatState copyWith({
    List<ChatModel>? chats,
    List<MessageModel>? messages,
    bool? isLoadingChats,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      isLoadingChats: isLoadingChats ?? this.isLoadingChats,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._service) : super(const ChatState());

  final ChatService _service;

  Future<void> loadChats(String userId) async {
    state = state.copyWith(isLoadingChats: true);
    final chats = await _service.fetchChats(userId);
    state = state.copyWith(chats: chats, isLoadingChats: false);
  }

  // Silent refresh — no loading spinner; used for polling and on re-enter
  Future<void> loadMessages(String chatId) async {
    final msgs = await _service.fetchMessages(chatId);
    state = state.copyWith(messages: msgs);
  }

  // Reset unread badge for a chat both in prefs and in state
  Future<void> markRead(String chatId) async {
    await _service.markChatRead(chatId);
    state = state.copyWith(
      chats: state.chats.map((c) {
        if (c.id != chatId) return c;
        return ChatModel(
          id: c.id,
          participantIds: c.participantIds,
          participantNames: c.participantNames,
          propertyId: c.propertyId,
          propertyTitle: c.propertyTitle,
          lastMessage: c.lastMessage,
          lastMessageTime: c.lastMessageTime,
          unreadCount: 0,
        );
      }).toList(),
    );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final msg = await _service.sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: content,
    );
    // Add to current message list
    state = state.copyWith(messages: [...state.messages, msg]);
    // Update chat list preview (sender's own unread = 0)
    state = state.copyWith(
      chats: state.chats.map((c) {
        if (c.id != chatId) return c;
        return ChatModel(
          id: c.id,
          participantIds: c.participantIds,
          participantNames: c.participantNames,
          propertyId: c.propertyId,
          propertyTitle: c.propertyTitle,
          lastMessage: content,
          lastMessageTime: msg.timestamp,
          unreadCount: 0,
        );
      }).toList(),
    );
  }

  Future<ChatModel> findOrCreateChat({
    required String userId,
    required String userName,
    required String ownerId,
    required String ownerName,
    required String propertyId,
    required String propertyTitle,
  }) {
    return _service.findOrCreateChat(
      userId: userId,
      userName: userName,
      ownerId: ownerId,
      ownerName: ownerName,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.read(chatServiceProvider));
});

// ─── Notifications ────────────────────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super([]);

  void add(NotificationModel n) => state = [n, ...state];

  void markRead(String id) {
    state = [for (final n in state) n.id == id ? n.copyWith(isRead: true) : n];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationModel>>(
        (_) => NotificationNotifier());

// ─── Ad State ─────────────────────────────────────────────────────────────────

class AdNotifier extends StateNotifier<List<AdModel>> {
  AdNotifier(this._service) : super([]) {
    _load();
    // Purge expired ads from live state every 60 seconds without a full reload.
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _purgeExpired());
  }

  final PropertyService _service;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    state = await _service.fetchActiveAds();
  }

  void _purgeExpired() {
    final now = DateTime.now();
    final stillActive = state.where((a) => a.expiresAt.isAfter(now)).toList();
    if (stillActive.length != state.length) state = stillActive;
  }

  Future<AdModel> boostProperty({
    required String propertyId,
    required String ownerId,
    required AdPackage package,
  }) async {
    final ad = await _service.boostProperty(
      propertyId: propertyId,
      ownerId: ownerId,
      package: package,
    );
    await _load();
    return ad;
  }
}

final adProvider = StateNotifierProvider<AdNotifier, List<AdModel>>((ref) {
  return AdNotifier(ref.read(propertyServiceProvider));
});

// ─── Analytics ────────────────────────────────────────────────────────────────

final analyticsProvider = Provider<Map<String, dynamic>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  if (user == null) return {};
  final service = ref.read(propertyServiceProvider);
  return service.getAnalytics(user.id);
});

// ─── Booking Service ──────────────────────────────────────────────────────────

final bookingServiceProvider = Provider<BookingService>((_) => BookingService());

// ─── Owner Booking State ──────────────────────────────────────────────────────

class BookingNotifier extends StateNotifier<List<BookingModel>> {
  BookingNotifier(this._service, String? ownerId) : super([]) {
    if (ownerId != null) _load(ownerId);
  }

  final BookingService _service;

  Future<void> _load(String ownerId) async {
    final bookings = await _service.fetchByOwner(ownerId);
    if (mounted) state = bookings;
  }

  Future<void> acceptBooking(String id) async {
    final updated = await _service.updateStatus(id, BookingStatus.confirmed);
    state = [for (final b in state) b.id == id ? updated : b];
  }

  Future<void> rejectBooking(String id, {String? reason}) async {
    final updated = await _service.updateStatus(
      id, BookingStatus.cancelled, rejectionReason: reason,
    );
    state = [for (final b in state) b.id == id ? updated : b];
  }

  Future<void> refresh(String ownerId) => _load(ownerId);
}

final bookingProvider =
    StateNotifierProvider<BookingNotifier, List<BookingModel>>((ref) {
  final userId = ref.watch(authProvider).currentUser?.id;
  return BookingNotifier(ref.read(bookingServiceProvider), userId);
});

// ─── Client Booking State ─────────────────────────────────────────────────────

class ClientBookingNotifier extends StateNotifier<List<BookingModel>> {
  ClientBookingNotifier(this._service, this._clientId, this._clientName)
      : super([]) {
    if (_clientId != null) _load();
  }

  final BookingService _service;
  final String? _clientId;
  final String? _clientName;

  Future<void> _load() async {
    if (_clientId == null) return;
    final bookings = await _service.fetchByClient(_clientId);
    if (mounted) state = bookings;
  }

  Future<BookingModel?> createBooking({
    required PropertyModel property,
    required BookingType type,
    required DateTime scheduledDate,
    String? message,
    DateTime? checkIn,
    DateTime? checkOut,
    int? contractMonths,
  }) async {
    if (_clientId == null) return null;
    final booking = await _service.createBooking(
      propertyId:      property.id,
      propertyTitle:   property.title,
      ownerId:         property.ownerId,
      clientId:        _clientId,
      clientName:      _clientName ?? 'Client',
      type:            type,
      scheduledDate:   scheduledDate,
      message:         message,
      checkIn:         checkIn,
      checkOut:        checkOut,
      pricePerNight:   (property.priceType == PriceType.daily || type == BookingType.rental)
                         ? property.price.toDouble()
                         : null,
      propertyTypeName: property.type.name,
      contractMonths:  contractMonths,
    );
    if (mounted) state = [booking, ...state];
    return booking;
  }

  Future<void> cancelBooking(String id) async {
    await _service.updateStatus(id, BookingStatus.cancelled);
    if (mounted) {
      state = [
        for (final b in state)
          b.id == id ? b.copyWith(status: BookingStatus.cancelled) : b,
      ];
    }
  }

  Future<void> refresh() => _load();
}

final clientBookingProvider =
    StateNotifierProvider<ClientBookingNotifier, List<BookingModel>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return ClientBookingNotifier(
    ref.read(bookingServiceProvider),
    user?.id,
    user?.username,
  );
});

// ─── Active Sliding Card (only one PropertyListCard animates at a time) ──────

final activeSlidingCardProvider = StateProvider<String?>((ref) => null);

// ─── Theme Mode ───────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  static const _key = 'theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_key) == 'light') state = ThemeMode.light;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// ─── Router Notifier (bridges auth state to GoRouter) ─────────────────────────

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
  AuthState get authState => _ref.read(authProvider);
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});
