import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player_model.dart';

class PlayerService {
  final CollectionReference _playerCollection =
      FirebaseFirestore.instance.collection('players');

  Future<List<Player>> getPlayers() async {
    final querySnapshot = await _playerCollection.get();
    return querySnapshot.docs
        .map((doc) => Player.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPlayer(Player player) async {
    final docRef = await _playerCollection.add(player.toJson());
    player.id = docRef.id;
  }

  Future<void> updatePlayer(Player player) async {
    if (player.id == null) return;
    await _playerCollection.doc(player.id).update(player.toJson());
  }

  Future<void> deletePlayer(String playerId) async {
    await _playerCollection.doc(playerId).delete();
  }
}
