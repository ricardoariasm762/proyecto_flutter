import 'package:supabase_flutter/supabase_flutter.dart';

class RideService {
  RideService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ==========================================
  // FASE 1: PASAJEROS (Grupos y Carpooling)
  // ==========================================

  Future<void> createGroup({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    int availableSeats = 1,
    double? offeredPrice,
  }) async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) throw Exception('auth-required');

    await _client.from('groups').insert({
      'creator_id': user.id,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'status': 'gathering',
      'available_seats': availableSeats,
      'offered_price': offeredPrice,
    });
  }

  Future<void> findDriver(String groupId) async {
    await _client
        .from('groups')
        .update({'status': 'searching_driver'})
        .eq('id', groupId);
  }

  Future<void> updateOfferedPrice(String groupId, double newPrice) async {
    await _client
        .from('groups')
        .update({'offered_price': newPrice})
        .eq('id', groupId);
  }

  Future<void> cancelGroup(String groupId) async {
    await _client
        .from('groups')
        .update({'status': 'cancelled'})
        .eq('id', groupId);
  }

  Future<void> completeGroup(String groupId) async {
    await _client
        .from('groups')
        .update({'status': 'completed'})
        .eq('id', groupId);
  }

  Stream<List<Map<String, dynamic>>> getGatheringGroupsStreamExcludingUser({
    String? excludeUserId,
  }) {
    final query = _client
        .from('groups')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return query.map((rows) {
      return rows
          .where((r) {
            final status = r['status']?.toString() ?? '';
            final isCreator =
                (r['creator_id'] ?? '').toString() == excludeUserId;
            final isActiveStatus =
                status == 'gathering' || status == 'searching_driver';
            return !isCreator && isActiveStatus;
          })
          .toList(growable: false);
    });
  }

  Future<bool> hasActiveGroupRequest() async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return false;

    final data = await _client
        .from('group_members')
        .select()
        .eq('user_id', user.id)
        .filter('status', 'in', ['pending', 'accepted']);

    return data.isNotEmpty;
  }

  Future<void> requestJoinGroup({required String groupId}) async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return;

    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': user.id,
      'status': 'pending',
    });
  }

  Future<Map<String, dynamic>?> getActiveGroup() async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return null;

    // Is Creator?
    final creatorGroup = await _client
        .from('groups')
        .select()
        .eq('creator_id', user.id)
        .filter('status', 'in', [
          'gathering',
          'searching_driver',
          'driver_assigned',
        ])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (creatorGroup != null) return creatorGroup;

    // Is Member?
    final request = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', user.id)
        .filter('status', 'in', ['pending', 'accepted'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (request != null) {
      final group = await _client
          .from('groups')
          .select()
          .eq('id', request['group_id'])
          .maybeSingle();
      return group;
    }

    return null;
  }

  Stream<Map<String, dynamic>?> getActiveGroupStream() {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return Stream.value(null);

    return _client.from('groups').stream(primaryKey: ['id']).map((rows) {
      // Check if creator
      final creatorGroup = rows.cast<Map<String, dynamic>?>().firstWhere(
        (r) =>
            r!['creator_id'] == user.id &&
            [
              'gathering',
              'searching_driver',
              'driver_assigned',
              'active',
            ].contains(r['status']),
        orElse: () => null,
      );

      if (creatorGroup != null) return creatorGroup;

      // Note: Members check would require a separate stream or a more complex query
      // because .stream() only works on a single table.
      // For now, we'll focus on the creator's real-time experience.
      return null;
    });
  }

  void listenForGroupRequests(
    void Function(Map<String, dynamic> requestData) onNewRequest,
  ) {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return;

    _client
        .channel('public:group_members')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_members',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            if (newRecord != null && newRecord['status'] == 'pending') {
              final groupId = (newRecord['group_id'] ?? '').toString();

              final groupData = await _client
                  .from('groups')
                  .select('creator_id')
                  .eq('id', groupId)
                  .maybeSingle();

              if (groupData != null && groupData['creator_id'] == user.id) {
                onNewRequest(newRecord);
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> acceptGroupRequest({required String membershipId}) async {
    await _client
        .from('group_members')
        .update({'status': 'accepted'})
        .eq('id', membershipId);
  }

  Future<void> rejectGroupRequest({required String membershipId}) async {
    await _client
        .from('group_members')
        .update({'status': 'rejected'})
        .eq('id', membershipId);
  }

  // ==========================================
  // FASE 2: CONDUCTOR (Estilo Uber)
  // ==========================================

  Future<void> searchDriverForGroup(String groupId) async {
    // Creator clicks "Buscar Conductor"
    await _client
        .from('groups')
        .update({'status': 'searching_driver'})
        .eq('id', groupId);
  }

  // ==========================================
  // FASE 2: CONDUCTORES (Aceptar viajes)
  // ==========================================

  Future<void> acceptRide({required String groupId}) async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) throw Exception('auth-required');

    // Actualizar el grupo con el ID del conductor y cambiar estado
    await _client
        .from('groups')
        .update({'driver_id': user.id, 'status': 'driver_assigned'})
        .eq('id', groupId);
  }

  Future<void> goOnline(double lat, double lng) async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return;
    await _client.from('active_drivers').upsert({
      'id': user.id,
      'last_lat': lat,
      'last_lng': lng,
      'is_online': true,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> goOffline() async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return;
    await _client.from('active_drivers').delete().eq('id', user.id);
  }

  void listenForDriverPings(
    void Function(Map<String, dynamic> groupData) onPing,
  ) {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return;

    _client
        .channel('public:groups')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'groups',
          callback: (payload) {
            final newRecord = payload.newRecord;
            // Si un grupo acaba de pasar a estado 'searching_driver'
            if (newRecord != null &&
                newRecord['status'] == 'searching_driver') {
              onPing(newRecord);
            }
          },
        )
        .subscribe();
  }

  Future<void> acceptDriverPing(String groupId) async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('groups')
        .update({'status': 'driver_assigned', 'driver_id': user.id})
        .eq('id', groupId)
        .eq('status', 'searching_driver');
  }

  Future<void> rejectDriverPing(String groupId) async {
    // Si lo rechaza un conductor específico, podríamos hacer lógica, pero por ahora solo se ignora en el UI.
  }

  // ==========================================
  // FASE 3: CHAT (Mensajería Realtime)
  // ==========================================

  Stream<List<Map<String, dynamic>>> getChatMessagesStream(String groupId) {
    return _client
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: true);
  }

  Future<void> sendChatMessage({
    required String groupId,
    required String content,
  }) async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return;

    await _client.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': user.id,
      'content': content,
    });
  }

  Future<void> sendInitialMessage(String groupId, String lang) async {
    final initialText = lang == 'es'
        ? "¡Hola! Aquí puedes comunicarte con tu grupo para coordinar el viaje."
        : "Hello! Here you can communicate with your group to coordinate the ride.";

    // Solo enviar si no hay mensajes
    final existing = await _client
        .from('group_messages')
        .select()
        .eq('group_id', groupId)
        .limit(1);
    if (existing.isEmpty) {
      await _client.from('group_messages').insert({
        'group_id': groupId,
        'sender_id': 'system', // O un ID especial
        'content': initialText,
      });
    }
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  Future<String> getUserName(String userId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      if (profile != null && profile['name'] != null) {
        return profile['name'].toString();
      }
    } catch (_) {}
    return "Usuario";
  }

  Future<String> getCurrentUserRole() async {
    try {
      final user =
          _client.auth.currentSession?.user ?? _client.auth.currentUser;
      if (user == null) return 'passenger';
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null && profile['role'] != null) {
        return profile['role'].toString();
      }
    } catch (_) {}
    return 'passenger';
  }
}
