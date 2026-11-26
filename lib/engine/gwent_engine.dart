import 'dart:math';
import 'package:gwent_gta6/data/rockstar_decks.dart';
import 'package:gwent_gta6/models/game_card.dart';
import 'package:gwent_gta6/models/leader_ability.dart';
import 'package:gwent_gta6/models/match_state.dart';

class GwentEngine {
  static const int initialHandSize = 8;
  static const int mulligansPerRound = 2;

  static MatchState createMatch(
    GameMode mode, {
    RockStarDeck p1DeckType = RockStarDeck.gta6,
    RockStarDeck p2DeckType = RockStarDeck.viceCity,
  }) {
    final p1Deck = RockstarDecks.buildShuffledDeck(p1DeckType, 'p1');
    final p2Deck = RockstarDecks.buildShuffledDeck(p2DeckType, 'p2');

    final p1HandCount = min(initialHandSize, p1Deck.length);
    final p2HandCount = min(initialHandSize, p2Deck.length);

    return MatchState(
      mode: mode,
      p1: PlayerBoardState(
        label: 'Jogador 1 (${p1DeckType.displayName})',
        selectedDeck: p1DeckType,
        leaderAbility: LeaderAbility.forDeck(p1DeckType),
        mulligansLeft: mulligansPerRound,
        deck: p1Deck.skip(p1HandCount).toList(),
        hand: p1Deck.take(p1HandCount).toList(),
      ),
      p2: PlayerBoardState(
        label: mode == GameMode.vsAi
            ? 'IA (${p2DeckType.displayName})'
            : 'Jogador 2 (${p2DeckType.displayName})',
        selectedDeck: p2DeckType,
        leaderAbility: LeaderAbility.forDeck(p2DeckType),
        mulligansLeft: mulligansPerRound,
        deck: p2Deck.skip(p2HandCount).toList(),
        hand: p2Deck.take(p2HandCount).toList(),
      ),
      currentTurn: PlayerSide.player1,
      isMulliganPhase: true,
      lastActionLog:
          'Mulligan Rodada 1: troque ate $mulligansPerRound cartas ou confirme para iniciar.',
    );
  }

  /// Troca uma carta da mao por outra do baralho durante a fase de mulligan.
  static MatchState mulliganCard(MatchState state, GameCard card) {
    if (!state.isMulliganPhase || state.matchWinner != null) return state;

    final side = state.currentTurn;
    final isP1 = side == PlayerSide.player1;
    final actor = isP1 ? state.p1 : state.p2;

    if (actor.mulligansLeft <= 0 || actor.deck.isEmpty) return state;

    final newHand = List<GameCard>.from(actor.hand)
      ..removeWhere((c) => c.id == card.id);
    if (newHand.length == actor.hand.length) return state;

    final newDeck = List<GameCard>.from(actor.deck)..add(card);
    newDeck.shuffle(Random());
    final drawnCard = newDeck.removeAt(0);
    newHand.add(drawnCard);

    final updatedActor = actor.copyWith(
      hand: newHand,
      deck: newDeck,
      mulligansLeft: actor.mulligansLeft - 1,
    );

    return state.copyWith(
      p1: isP1 ? updatedActor : state.p1,
      p2: isP1 ? state.p2 : updatedActor,
      lastActionLog:
          '${actor.label} trocou ${card.name} por ${drawnCard.name} (${updatedActor.mulligansLeft} troca(s) restante(s)).',
    );
  }

  /// Conclui o mulligan do jogador atual; no modo 2P passa para o outro jogador trocar antes de iniciar.
  static MatchState finishMulligan(MatchState state) {
    if (!state.isMulliganPhase || state.matchWinner != null) return state;

    if (state.mode == GameMode.twoPlayersLocal &&
        state.currentTurn == PlayerSide.player1) {
      return state.copyWith(
        currentTurn: PlayerSide.player2,
        awaitingHandover: true,
        lastActionLog:
            'Mulligan de ${state.p2.label}: troque cartas ou confirme.',
      );
    }

    // IA faz mulligan automatico se tiver cartas de clima sem unidades correspondentes ou mao fraca
    var nextState = state;
    if (nextState.mode == GameMode.vsAi && nextState.p2.mulligansLeft > 0) {
      final aiHand = List<GameCard>.from(nextState.p2.hand);
      for (final c in aiHand) {
        if (nextState.p2.mulligansLeft <= 0) break;
        if (c.ability == CardAbility.clearWeather) {
          final tempState = nextState.copyWith(currentTurn: PlayerSide.player2);
          nextState = mulliganCard(tempState, c);
        }
      }
    }

    return nextState.copyWith(
      isMulliganPhase: false,
      currentTurn: PlayerSide.player1,
      awaitingHandover: false,
      lastActionLog:
          'Rodada ${nextState.roundNumber} em andamento! Vez de ${nextState.p1.label}.',
    );
  }

  /// Ativa a habilidade especial do Lider do baralho atual (1 vez por partida).
  static MatchState activateLeaderAbility(MatchState state) {
    if (state.isMulliganPhase ||
        state.matchWinner != null ||
        state.awaitingHandover) {
      return state;
    }

    final side = state.currentTurn;
    final isP1 = side == PlayerSide.player1;
    var actor = isP1 ? state.p1 : state.p2;
    var opponent = isP1 ? state.p2 : state.p1;
    var weather = Set<CombatRow>.from(state.activeWeather);

    if (actor.leaderUsed || actor.hasPassed) return state;

    final ability = actor.leaderAbility.type;
    var log =
        '${actor.label} ativou ${actor.leaderAbility.title} (${actor.leaderAbility.leaderName})!';

    switch (ability) {
      case LeaderAbilityType.leonidaRush:
        if (actor.rangedRow.isNotEmpty) {
          actor = actor.copyWith(
            leaderBonusRanged: actor.leaderBonusRanged + 5,
          );
        } else {
          actor = actor.copyWith(
            leaderBonusClose: actor.leaderBonusClose + 5,
          );
        }
        log = '${actor.label} usou ${actor.leaderAbility.title}: +5 de forca!';

      case LeaderAbilityType.malibuEmpire:
        weather.clear();
        actor = actor.copyWith(
          leaderBonusClose: actor.leaderBonusClose + 3,
        );
        log =
            '${actor.label} usou ${actor.leaderAbility.title}: clima limpo e +3 no Combate Proximo!';

      case LeaderAbilityType.losSantosChaos:
        final scorched = _applyScorch(actor, opponent, minPowerThreshold: 7);
        actor = scorched.$1;
        opponent = scorched.$2;
        log = scorched.$3 > 0
            ? '${actor.label} usou ${actor.leaderAbility.title} e destruiu ${scorched.$3} unidade(s)!'
            : '${actor.label} usou ${actor.leaderAbility.title}, mas nao havia alvo >= 7.';

      case LeaderAbilityType.groveRespect:
        final extraDraw = actor.deck.take(1).toList();
        actor = actor.copyWith(
          deck: actor.deck.skip(extraDraw.length).toList(),
          hand: [...actor.hand, ...extraDraw],
          leaderBonusClose: actor.leaderBonusClose + 2,
        );
        log =
            '${actor.label} usou ${actor.leaderAbility.title}: +1 carta e +2 no Combate Proximo!';

      case LeaderAbilityType.thePlan:
        actor = actor.copyWith(
          leaderBonusClose: actor.leaderBonusClose + 2,
          leaderBonusRanged: actor.leaderBonusRanged + 2,
          leaderBonusSiege: actor.leaderBonusSiege + 2,
        );
        log =
            '${actor.label} usou ${actor.leaderAbility.title}: +2 em todas as suas fileiras!';
    }

    actor = actor.copyWith(leaderUsed: true);

    final nextState = state.copyWith(
      p1: isP1 ? actor : opponent,
      p2: isP1 ? opponent : actor,
      activeWeather: weather,
      lastActionLog: log,
    );

    return _advanceTurn(nextState);
  }

  static int calculateRowScore(
    List<GameCard> rowCards,
    CombatRow row,
    Set<CombatRow> activeWeather, {
    int leaderBonus = 0,
  }) {
    if (rowCards.isEmpty) return 0;
    final hasWeather = activeWeather.contains(row);
    final boostCount =
        rowCards.where((c) => c.ability == CardAbility.moralBoost).length;

    var nonHeroCount = 0;
    var total = 0;

    for (final card in rowCards) {
      if (card.isHero) {
        total += card.basePower;
        continue;
      }
      nonHeroCount++;
      var power = hasWeather ? min(1, card.basePower) : card.basePower;
      final ownBoost = card.ability == CardAbility.moralBoost ? 1 : 0;
      power += (boostCount - ownBoost);
      total += power;
    }

    if (nonHeroCount > 0 && leaderBonus != 0) {
      total += leaderBonus;
    }

    return total;
  }

  static int calculateTotalScore(
    PlayerBoardState player,
    Set<CombatRow> activeWeather,
  ) {
    return calculateRowScore(
          player.closeRow,
          CombatRow.close,
          activeWeather,
          leaderBonus: player.leaderBonusClose,
        ) +
        calculateRowScore(
          player.rangedRow,
          CombatRow.ranged,
          activeWeather,
          leaderBonus: player.leaderBonusRanged,
        ) +
        calculateRowScore(
          player.siegeRow,
          CombatRow.siege,
          activeWeather,
          leaderBonus: player.leaderBonusSiege,
        );
  }

  static MatchState confirmHandover(MatchState state) {
    return state.copyWith(awaitingHandover: false);
  }

  static MatchState playCard(MatchState state, GameCard card) {
    if (state.isMulliganPhase ||
        state.matchWinner != null ||
        state.awaitingHandover) {
      return state;
    }

    final side = state.currentTurn;
    final isP1 = side == PlayerSide.player1;
    var actor = isP1 ? state.p1 : state.p2;
    var opponent = isP1 ? state.p2 : state.p1;
    var weather = Set<CombatRow>.from(state.activeWeather);

    if (actor.hasPassed) return state;

    final updatedHand = List<GameCard>.from(actor.hand)
      ..removeWhere((c) => c.id == card.id);
    actor = actor.copyWith(hand: updatedHand);

    var log = '${actor.label} jogou ${card.name}.';

    if (card.ability == CardAbility.weather && card.weatherTargetRow != null) {
      weather.add(card.weatherTargetRow!);
      actor = actor.copyWith(graveyard: [...actor.graveyard, card]);
      log = '${actor.label} ativou clima ${card.name}!';
    } else if (card.ability == CardAbility.clearWeather) {
      weather.clear();
      actor = actor.copyWith(graveyard: [...actor.graveyard, card]);
      log = '${actor.label} limpou o clima com ${card.name}!';
    } else if (card.ability == CardAbility.spy) {
      opponent = _addCardToRow(opponent, card);
      final drawn = actor.deck.take(2).toList();
      actor = actor.copyWith(
        deck: actor.deck.skip(drawn.length).toList(),
        hand: [...actor.hand, ...drawn],
      );
      log =
          '${actor.label} infiltrou ${card.name} e comprou ${drawn.length} carta(s)!';
    } else {
      actor = _addCardToRow(actor, card);

      if (card.ability == CardAbility.medic) {
        final revivable =
            actor.graveyard.where((c) => !c.isHero && c.basePower > 0).toList();
        if (revivable.isNotEmpty) {
          final revived = revivable.last;
          final newGrave = List<GameCard>.from(actor.graveyard)
            ..removeWhere((c) => c.id == revived.id);
          actor = _addCardToRow(actor.copyWith(graveyard: newGrave), revived);
          log = '${actor.label} jogou ${card.name} e reviveu ${revived.name}!';
        }
      }

      if (card.ability == CardAbility.scorch) {
        final scorched = _applyScorch(actor, opponent, minPowerThreshold: 8);
        actor = scorched.$1;
        opponent = scorched.$2;
        if (scorched.$3 > 0) {
          log =
              '${actor.label} ativou ${card.name} e destruiu ${scorched.$3} carta(s) forte(s)!';
        }
      }
    }

    final nextState = state.copyWith(
      p1: isP1 ? actor : opponent,
      p2: isP1 ? opponent : actor,
      activeWeather: weather,
      lastActionLog: log,
    );

    final updatedActor = nextState.playerState(side);
    if (updatedActor.hand.isEmpty) {
      return passTurn(nextState);
    }

    return _advanceTurn(nextState);
  }

  static MatchState passTurn(MatchState state) {
    if (state.isMulliganPhase ||
        state.matchWinner != null ||
        state.awaitingHandover) {
      return state;
    }

    final side = state.currentTurn;
    final isP1 = side == PlayerSide.player1;
    final actor = (isP1 ? state.p1 : state.p2).copyWith(hasPassed: true);

    final nextState = state.copyWith(
      p1: isP1 ? actor : state.p1,
      p2: isP1 ? state.p2 : actor,
      lastActionLog: '${actor.label} passou a rodada.',
    );

    if (nextState.p1.hasPassed && nextState.p2.hasPassed) {
      return _resolveRound(nextState);
    }

    return _advanceTurn(nextState);
  }

  static MatchState _advanceTurn(MatchState state) {
    final otherSide = state.currentTurn == PlayerSide.player1
        ? PlayerSide.player2
        : PlayerSide.player1;

    final otherPlayer = state.playerState(otherSide);
    if (otherPlayer.hasPassed) {
      return state;
    }

    final needsHandover = state.mode == GameMode.twoPlayersLocal;
    return state.copyWith(
      currentTurn: otherSide,
      awaitingHandover: needsHandover,
    );
  }

  static PlayerBoardState _prepareNextRoundPlayer(
    PlayerBoardState clearedPlayer,
    int roundsWon,
  ) {
    final neededDraws = max(0, initialHandSize - clearedPlayer.hand.length);
    final draws = clearedPlayer.deck.take(neededDraws).toList();
    return clearedPlayer.copyWith(
      roundsWon: roundsWon,
      hasPassed: false,
      leaderBonusClose: 0,
      leaderBonusRanged: 0,
      leaderBonusSiege: 0,
      mulligansLeft: mulligansPerRound,
      deck: clearedPlayer.deck.skip(draws.length).toList(),
      hand: [...clearedPlayer.hand, ...draws],
    );
  }

  static MatchState _resolveRound(MatchState state) {
    final p1Score = calculateTotalScore(state.p1, state.activeWeather);
    final p2Score = calculateTotalScore(state.p2, state.activeWeather);

    var p1Wins = state.p1.roundsWon;
    var p2Wins = state.p2.roundsWon;
    String roundSummary;

    if (p1Score > p2Score) {
      p1Wins++;
      roundSummary =
          '${state.p1.label} venceu a Rodada ${state.roundNumber} ($p1Score x $p2Score)!';
    } else if (p2Score > p1Score) {
      p2Wins++;
      roundSummary =
          '${state.p2.label} venceu a Rodada ${state.roundNumber} ($p2Score x $p1Score)!';
    } else {
      p1Wins++;
      p2Wins++;
      roundSummary =
          'Empate na Rodada ${state.roundNumber} ($p1Score x $p2Score)!';
    }

    PlayerSide? winner;
    if (p1Wins >= 2 && p2Wins >= 2) {
      winner = p1Score >= p2Score ? PlayerSide.player1 : PlayerSide.player2;
    } else if (p1Wins >= 2) {
      winner = PlayerSide.player1;
    } else if (p2Wins >= 2) {
      winner = PlayerSide.player2;
    }

    final clearedP1 = _clearBoardToGraveyard(state.p1);
    final clearedP2 = _clearBoardToGraveyard(state.p2);

    if (winner != null) {
      final winnerLabel =
          winner == PlayerSide.player1 ? clearedP1.label : clearedP2.label;
      return state.copyWith(
        p1: clearedP1.copyWith(roundsWon: p1Wins, hasPassed: false),
        p2: clearedP2.copyWith(roundsWon: p2Wins, hasPassed: false),
        activeWeather: const {},
        matchWinner: winner,
        awaitingHandover: false,
        isMulliganPhase: false,
        lastActionLog: '$roundSummary $winnerLabel venceu a partida!',
      );
    }

    final nextP1 = _prepareNextRoundPlayer(clearedP1, p1Wins);
    final nextP2 = _prepareNextRoundPlayer(clearedP2, p2Wins);
    final nextRound = state.roundNumber + 1;

    return state.copyWith(
      p1: nextP1,
      p2: nextP2,
      activeWeather: const {},
      roundNumber: nextRound,
      currentTurn: PlayerSide.player1,
      isMulliganPhase: true,
      awaitingHandover: false,
      lastActionLog:
          '$roundSummary Mulligan Rodada $nextRound: ate $mulligansPerRound trocas.',
    );
  }

  static MatchState performAiTurn(MatchState state) {
    if (state.isMulliganPhase ||
        state.mode != GameMode.vsAi ||
        state.currentTurn != PlayerSide.player2 ||
        state.matchWinner != null) {
      return state;
    }

    final ai = state.p2;
    final human = state.p1;
    if (ai.hand.isEmpty) return passTurn(state);

    final aiScore = calculateTotalScore(ai, state.activeWeather);
    final humanScore = calculateTotalScore(human, state.activeWeather);

    // Usa habilidade de Lider quando estiver perdendo por margem relevante ou para limpar clima
    if (!ai.leaderUsed &&
        (humanScore - aiScore >= 7 ||
            (state.activeWeather.isNotEmpty &&
                ai.leaderAbility.type == LeaderAbilityType.malibuEmpire))) {
      return activateLeaderAbility(state);
    }

    if (human.hasPassed && aiScore > humanScore) {
      return passTurn(state);
    }

    if (ai.roundsWon == 1 &&
        (humanScore - aiScore) >= 20 &&
        ai.hand.length <= 4) {
      return passTurn(state);
    }

    final sorted = List<GameCard>.from(ai.hand)
      ..sort((a, b) {
        if (a.ability == CardAbility.spy && b.ability != CardAbility.spy) {
          return -1;
        }
        if (b.ability == CardAbility.spy && a.ability != CardAbility.spy) {
          return 1;
        }
        return b.basePower.compareTo(a.basePower);
      });

    return playCard(state, sorted.first);
  }

  static PlayerBoardState _addCardToRow(
      PlayerBoardState player, GameCard card) {
    switch (card.row) {
      case CombatRow.close:
        return player.copyWith(closeRow: [...player.closeRow, card]);
      case CombatRow.ranged:
        return player.copyWith(rangedRow: [...player.rangedRow, card]);
      case CombatRow.siege:
        return player.copyWith(siegeRow: [...player.siegeRow, card]);
    }
  }

  static PlayerBoardState _clearBoardToGraveyard(PlayerBoardState player) {
    final allBoard = [
      ...player.closeRow,
      ...player.rangedRow,
      ...player.siegeRow,
    ];
    return player.copyWith(
      closeRow: const [],
      rangedRow: const [],
      siegeRow: const [],
      graveyard: [...player.graveyard, ...allBoard],
    );
  }

  static (PlayerBoardState, PlayerBoardState, int) _applyScorch(
    PlayerBoardState actor,
    PlayerBoardState opponent, {
    int minPowerThreshold = 8,
  }) {
    final allNonHero = <GameCard>[
      ...actor.closeRow,
      ...actor.rangedRow,
      ...actor.siegeRow,
      ...opponent.closeRow,
      ...opponent.rangedRow,
      ...opponent.siegeRow,
    ].where((c) => !c.isHero && c.basePower > 0).toList();

    if (allNonHero.isEmpty) return (actor, opponent, 0);

    final maxPower =
        allNonHero.map((c) => c.basePower).reduce((a, b) => max(a, b));
    if (maxPower < minPowerThreshold) return (actor, opponent, 0);

    final targetIds = allNonHero
        .where((c) => c.basePower == maxPower)
        .map((c) => c.id)
        .toSet();

    PlayerBoardState burnFrom(PlayerBoardState p) {
      final burned = [
        ...p.closeRow,
        ...p.rangedRow,
        ...p.siegeRow,
      ].where((c) => targetIds.contains(c.id)).toList();

      return p.copyWith(
        closeRow: p.closeRow.where((c) => !targetIds.contains(c.id)).toList(),
        rangedRow: p.rangedRow.where((c) => !targetIds.contains(c.id)).toList(),
        siegeRow: p.siegeRow.where((c) => !targetIds.contains(c.id)).toList(),
        graveyard: [...p.graveyard, ...burned],
      );
    }

    return (burnFrom(actor), burnFrom(opponent), targetIds.length);
  }
}
