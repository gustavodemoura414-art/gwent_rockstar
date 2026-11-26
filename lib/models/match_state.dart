import 'package:gwent_gta6/models/game_card.dart';
import 'package:gwent_gta6/models/leader_ability.dart';

enum GameMode {
  vsAi,
  twoPlayersLocal,
}

enum PlayerSide {
  player1,
  player2,
}

class PlayerBoardState {
  final String label;
  final RockStarDeck selectedDeck;
  final LeaderAbility leaderAbility;
  final bool leaderUsed;
  final int leaderBonusClose;
  final int leaderBonusRanged;
  final int leaderBonusSiege;
  final int mulligansLeft;
  final List<GameCard> deck;
  final List<GameCard> hand;
  final List<GameCard> closeRow;
  final List<GameCard> rangedRow;
  final List<GameCard> siegeRow;
  final List<GameCard> graveyard;
  final bool hasPassed;
  final int roundsWon;

  const PlayerBoardState({
    required this.label,
    required this.selectedDeck,
    required this.leaderAbility,
    this.leaderUsed = false,
    this.leaderBonusClose = 0,
    this.leaderBonusRanged = 0,
    this.leaderBonusSiege = 0,
    this.mulligansLeft = 2,
    required this.deck,
    required this.hand,
    this.closeRow = const [],
    this.rangedRow = const [],
    this.siegeRow = const [],
    this.graveyard = const [],
    this.hasPassed = false,
    this.roundsWon = 0,
  });

  int leaderBonusForRow(CombatRow row) {
    switch (row) {
      case CombatRow.close:
        return leaderBonusClose;
      case CombatRow.ranged:
        return leaderBonusRanged;
      case CombatRow.siege:
        return leaderBonusSiege;
    }
  }

  PlayerBoardState copyWith({
    String? label,
    RockStarDeck? selectedDeck,
    LeaderAbility? leaderAbility,
    bool? leaderUsed,
    int? leaderBonusClose,
    int? leaderBonusRanged,
    int? leaderBonusSiege,
    int? mulligansLeft,
    List<GameCard>? deck,
    List<GameCard>? hand,
    List<GameCard>? closeRow,
    List<GameCard>? rangedRow,
    List<GameCard>? siegeRow,
    List<GameCard>? graveyard,
    bool? hasPassed,
    int? roundsWon,
  }) {
    return PlayerBoardState(
      label: label ?? this.label,
      selectedDeck: selectedDeck ?? this.selectedDeck,
      leaderAbility: leaderAbility ?? this.leaderAbility,
      leaderUsed: leaderUsed ?? this.leaderUsed,
      leaderBonusClose: leaderBonusClose ?? this.leaderBonusClose,
      leaderBonusRanged: leaderBonusRanged ?? this.leaderBonusRanged,
      leaderBonusSiege: leaderBonusSiege ?? this.leaderBonusSiege,
      mulligansLeft: mulligansLeft ?? this.mulligansLeft,
      deck: deck ?? this.deck,
      hand: hand ?? this.hand,
      closeRow: closeRow ?? this.closeRow,
      rangedRow: rangedRow ?? this.rangedRow,
      siegeRow: siegeRow ?? this.siegeRow,
      graveyard: graveyard ?? this.graveyard,
      hasPassed: hasPassed ?? this.hasPassed,
      roundsWon: roundsWon ?? this.roundsWon,
    );
  }
}

class MatchState {
  final GameMode mode;
  final PlayerBoardState p1;
  final PlayerBoardState p2;
  final PlayerSide currentTurn;
  final Set<CombatRow> activeWeather;
  final int roundNumber;
  final String lastActionLog;
  final bool awaitingHandover;
  final bool isMulliganPhase;
  final PlayerSide? matchWinner;

  const MatchState({
    required this.mode,
    required this.p1,
    required this.p2,
    required this.currentTurn,
    this.activeWeather = const {},
    this.roundNumber = 1,
    this.lastActionLog = 'Partida iniciada!',
    this.awaitingHandover = false,
    this.isMulliganPhase = true,
    this.matchWinner,
  });

  PlayerBoardState playerState(PlayerSide side) =>
      side == PlayerSide.player1 ? p1 : p2;

  MatchState copyWith({
    GameMode? mode,
    PlayerBoardState? p1,
    PlayerBoardState? p2,
    PlayerSide? currentTurn,
    Set<CombatRow>? activeWeather,
    int? roundNumber,
    String? lastActionLog,
    bool? awaitingHandover,
    bool? isMulliganPhase,
    PlayerSide? matchWinner,
  }) {
    return MatchState(
      mode: mode ?? this.mode,
      p1: p1 ?? this.p1,
      p2: p2 ?? this.p2,
      currentTurn: currentTurn ?? this.currentTurn,
      activeWeather: activeWeather ?? this.activeWeather,
      roundNumber: roundNumber ?? this.roundNumber,
      lastActionLog: lastActionLog ?? this.lastActionLog,
      awaitingHandover: awaitingHandover ?? this.awaitingHandover,
      isMulliganPhase: isMulliganPhase ?? this.isMulliganPhase,
      matchWinner: matchWinner ?? this.matchWinner,
    );
  }
}
