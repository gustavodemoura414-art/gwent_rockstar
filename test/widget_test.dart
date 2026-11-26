import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_gta6/engine/gwent_engine.dart';
import 'package:gwent_gta6/models/game_card.dart';
import 'package:gwent_gta6/models/match_state.dart';

void main() {
  group('Mulligan e Habilidade de Lider', () {
    test('mulligan troca carta da mao e reduz mulligansLeft', () {
      var state = GwentEngine.createMatch(
        GameMode.vsAi,
        p1DeckType: RockStarDeck.gta6,
        p2DeckType: RockStarDeck.rdr2,
      );

      expect(state.isMulliganPhase, isTrue);
      expect(state.p1.mulligansLeft, GwentEngine.mulligansPerRound);

      final removedCard = state.p1.hand.first;
      state = GwentEngine.mulliganCard(state, removedCard);

      expect(state.p1.mulligansLeft, GwentEngine.mulligansPerRound - 1);
      expect(state.p1.hand.length, GwentEngine.initialHandSize);
      expect(state.p1.hand.any((c) => c.id == removedCard.id), isFalse);

      state = GwentEngine.finishMulligan(state);
      expect(state.isMulliganPhase, isFalse);
    });

    test('habilidade de lider de San Andreas compra 1 carta e marca liderUsed',
        () {
      var state = GwentEngine.createMatch(
        GameMode.vsAi,
        p1DeckType: RockStarDeck.sanAndreas,
        p2DeckType: RockStarDeck.viceCity,
      );
      state = GwentEngine.finishMulligan(state);

      final initialHandCount = state.p1.hand.length;
      state = GwentEngine.activateLeaderAbility(state);

      expect(state.p1.leaderUsed, isTrue);
      expect(state.p1.hand.length, initialHandCount + 1);
    });
  });
}
