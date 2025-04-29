enum MatchTypeEnum {
  draft,
  sealed,
  blitz,
  classicConstructed;

  String get displayName {
    switch (this) {
      case MatchTypeEnum.draft:
        return "Draft";
      case MatchTypeEnum.sealed:
        return "Sealed";
      case MatchTypeEnum.blitz:
        return "Blitz";
      case MatchTypeEnum.classicConstructed:
        return "Classic Constructed";
    }
  }
}

class MatchType {
  MatchTypeEnum type;
  int durationGame;
  int lifeGamePlayer;

  MatchType({
    required this.type,
    required this.durationGame,
    required this.lifeGamePlayer,
  });

  factory MatchType.fromJson(Map<String, dynamic> json) {
    return MatchType(
      type: MatchTypeEnum.values.firstWhere((e) => e.name == json['type']),
      durationGame: json['durationGame'],
      lifeGamePlayer: json['lifeGamePlayer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'durationGame': durationGame,
      'lifeGamePlayer': lifeGamePlayer,
    };
  }

  static int getDurationByType(MatchTypeEnum type) {
    return type == MatchTypeEnum.classicConstructed ? 50 * 60 : 30 * 60;
  }

  static int getLifeGamePlayerByType(MatchTypeEnum type) {
    return type == MatchTypeEnum.classicConstructed ? 40 : 20;
  }

  static MatchType initMatch() {
    return MatchType(
      type: MatchTypeEnum.classicConstructed,
      durationGame: getDurationByType(MatchTypeEnum.classicConstructed),
      lifeGamePlayer: getLifeGamePlayerByType(MatchTypeEnum.classicConstructed),
    );
  }
}
