import 'package:flutter/material.dart';
import 'package:gwent_gta6/engine/gwent_engine.dart';
import 'package:gwent_gta6/models/game_card.dart';
import 'package:gwent_gta6/models/match_state.dart';

class GwentBoardScreen extends StatefulWidget {
  final GameMode mode;
  final RockStarDeck p1Deck;
  final RockStarDeck p2Deck;

  const GwentBoardScreen({
    super.key,
    required this.mode,
    this.p1Deck = RockStarDeck.gta6,
    this.p2Deck = RockStarDeck.viceCity,
  });

  @override
  State<GwentBoardScreen> createState() => _GwentBoardScreenState();
}

class _GwentBoardScreenState extends State<GwentBoardScreen> {
  late MatchState _state;
  GameCard? _selectedCard;
  bool _aiThinking = false;

  @override
  void initState() {
    super.initState();
    _state = GwentEngine.createMatch(
      widget.mode,
      p1DeckType: widget.p1Deck,
      p2DeckType: widget.p2Deck,
    );
  }

  void _restartMatch() {
    setState(() {
      _selectedCard = null;
      _aiThinking = false;
      _state = GwentEngine.createMatch(
        widget.mode,
        p1DeckType: widget.p1Deck,
        p2DeckType: widget.p2Deck,
      );
    });
  }

  Future<void> _triggerAiIfNeeded() async {
    if (_state.isMulliganPhase ||
        _state.mode != GameMode.vsAi ||
        _state.currentTurn != PlayerSide.player2 ||
        _state.matchWinner != null ||
        _aiThinking) {
      return;
    }

    setState(() => _aiThinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _state = GwentEngine.performAiTurn(_state);
      _aiThinking = false;
    });

    if (_state.currentTurn == PlayerSide.player2 &&
        _state.matchWinner == null &&
        !_state.isMulliganPhase) {
      await _triggerAiIfNeeded();
    }
  }

  void _onPlaySelectedCard() {
    final card = _selectedCard;
    if (card == null) return;

    setState(() {
      _state = GwentEngine.playCard(_state, card);
      _selectedCard = null;
    });

    _triggerAiIfNeeded();
  }

  void _onActivateLeader() {
    setState(() {
      _selectedCard = null;
      _state = GwentEngine.activateLeaderAbility(_state);
    });

    _triggerAiIfNeeded();
  }

  void _onMulliganSelectedCard() {
    final card = _selectedCard;
    if (card == null) return;

    setState(() {
      _state = GwentEngine.mulliganCard(_state, card);
      _selectedCard = null;
    });
  }

  void _onFinishMulligan() {
    setState(() {
      _selectedCard = null;
      _state = GwentEngine.finishMulligan(_state);
    });
  }

  void _onPassRound() {
    setState(() {
      _selectedCard = null;
      _state = GwentEngine.passTurn(_state);
    });

    _triggerAiIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final isTwoPlayers = _state.mode == GameMode.twoPlayersLocal;
    final viewingSide = isTwoPlayers ? _state.currentTurn : PlayerSide.player1;
    final bottomPlayer = _state.playerState(viewingSide);
    final topPlayer = viewingSide == PlayerSide.player1 ? _state.p2 : _state.p1;

    final bottomTotal =
        GwentEngine.calculateTotalScore(bottomPlayer, _state.activeWeather);
    final topTotal =
        GwentEngine.calculateTotalScore(topPlayer, _state.activeWeather);

    final canAct = !_aiThinking &&
        _state.matchWinner == null &&
        !_state.awaitingHandover &&
        (isTwoPlayers || _state.currentTurn == PlayerSide.player1);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121726),
        foregroundColor: Colors.white,
        title: Text(
          'Rodada ${_state.roundNumber}  •  ${_state.lastActionLog}',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          if (_state.activeWeather.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF33E1ED).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF33E1ED)),
                ),
                child: Text(
                  'Clima: ${_state.activeWeather.map((w) => w.name.toUpperCase()).join(', ')}',
                  style: const TextStyle(
                    color: Color(0xFF33E1ED),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Reiniciar Partida',
            onPressed: _restartMatch,
            icon: const Icon(Icons.refresh_rounded),
          ),
          
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _PlayerScoreBanner(
                player: topPlayer,
                totalScore: topTotal,
                accentColor: const Color(0xFFFF3B8D),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    children: [
                      Expanded(
                        child: _CombatRowBar(
                          label: 'CERCO (OPONENTE)',
                          row: CombatRow.siege,
                          cards: topPlayer.siegeRow,
                          activeWeather: _state.activeWeather,
                          leaderBonus: topPlayer.leaderBonusSiege,
                        ),
                      ),
                      Expanded(
                        child: _CombatRowBar(
                          label: 'ALCANCE (OPONENTE)',
                          row: CombatRow.ranged,
                          cards: topPlayer.rangedRow,
                          activeWeather: _state.activeWeather,
                          leaderBonus: topPlayer.leaderBonusRanged,
                        ),
                      ),
                      Expanded(
                        child: _CombatRowBar(
                          label: 'COMBATE PROXIMO (OPONENTE)',
                          row: CombatRow.close,
                          cards: topPlayer.closeRow,
                          activeWeather: _state.activeWeather,
                          leaderBonus: topPlayer.leaderBonusClose,
                        ),
                      ),
                      const Divider(height: 8, color: Color(0xFF33E1ED)),
                      Expanded(
                        child: _CombatRowBar(
                          label: 'COMBATE PROXIMO',
                          row: CombatRow.close,
                          cards: bottomPlayer.closeRow,
                          activeWeather: _state.activeWeather,
                          leaderBonus: bottomPlayer.leaderBonusClose,
                        ),
                      ),
                      Expanded(
                        child: _CombatRowBar(
                          label: 'ALCANCE',
                          row: CombatRow.ranged,
                          cards: bottomPlayer.rangedRow,
                          activeWeather: _state.activeWeather,
                          leaderBonus: bottomPlayer.leaderBonusRanged,
                        ),
                      ),
                      Expanded(
                        child: _CombatRowBar(
                          label: 'CERCO',
                          row: CombatRow.siege,
                          cards: bottomPlayer.siegeRow,
                          activeWeather: _state.activeWeather,
                          leaderBonus: bottomPlayer.leaderBonusSiege,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _PlayerScoreBanner(
                player: bottomPlayer,
                totalScore: bottomTotal,
                accentColor: const Color(0xFF33E1ED),
                trailing: _state.isMulliganPhase
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedCard != null &&
                              bottomPlayer.mulligansLeft > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF33E1ED),
                                  side: const BorderSide(
                                    color: Color(0xFF33E1ED),
                                  ),
                                ),
                                onPressed: _onMulliganSelectedCard,
                                icon: const Icon(Icons.swap_horiz_rounded,
                                    size: 18),
                                label: Text(
                                  'Trocar (${bottomPlayer.mulligansLeft})',
                                ),
                              ),
                            ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD166),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _onFinishMulligan,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Confirmar Mao'),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message:
                                '${bottomPlayer.leaderAbility.title} (${bottomPlayer.leaderAbility.leaderName}): ${bottomPlayer.leaderAbility.description}',
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFFD166),
                                side: BorderSide(
                                  color: bottomPlayer.leaderUsed
                                      ? Colors.white24
                                      : const Color(0xFFFFD166),
                                ),
                              ),
                              onPressed: (canAct && !bottomPlayer.leaderUsed)
                                  ? _onActivateLeader
                                  : null,
                              icon: const Icon(Icons.auto_awesome_rounded,
                                  size: 17),
                              label: Text(
                                bottomPlayer.leaderUsed
                                    ? 'Lider Usado'
                                    : 'Lider: ${bottomPlayer.leaderAbility.title}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_selectedCard != null && canAct)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF33E1ED),
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: _onPlaySelectedCard,
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 18),
                                label: Text('Jogar ${_selectedCard!.name}'),
                              ),
                            ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF3B8D),
                              side: const BorderSide(color: Color(0xFFFF3B8D)),
                            ),
                            onPressed: canAct ? _onPassRound : null,
                            child: const Text('Passar Rodada'),
                          ),
                        ],
                      ),
              ),
              Container(
                height: 248,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF131B2E), Color(0xFF0C111D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: bottomPlayer.hand.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final card = bottomPlayer.hand[index];
                    final isSelected = _selectedCard?.id == card.id;
                    return _HandCardTile(
                      card: card,
                      isSelected: isSelected,
                      onTap: (canAct || _state.isMulliganPhase)
                          ? () {
                              setState(() {
                                _selectedCard = isSelected ? null : card;
                              });
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
          if (_state.awaitingHandover && _state.matchWinner == null)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xF5070A12),
                child: Center(
                  child: Card(
                    color: const Color(0xFF151C2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFF33E1ED)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.swap_horiz_rounded,
                            size: 52,
                            color: Color(0xFF33E1ED),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Vez de ${_state.playerState(_state.currentTurn).label}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Passe o controle para o proximo jogador antes de revelar as cartas.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF33E1ED),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _state = GwentEngine.confirmHandover(_state);
                              });
                            },
                            child: const Text('Mostrar Minha Mao'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_state.matchWinner != null)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xE6070A12),
                child: Center(
                  child: Card(
                    color: const Color(0xFF151C2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side:
                          const BorderSide(color: Color(0xFFFF3B8D), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 56,
                            color: Color(0xFFFFD166),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_state.playerState(_state.matchWinner!).label} Venceu!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Placar de Rodadas: ${_state.p1.roundsWon} x ${_state.p2.roundsWon}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF3B8D),
                                ),
                                onPressed: _restartMatch,
                                child: const Text('Jogar Novamente'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Menu Principal'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderPortraitAvatar extends StatelessWidget {
  final RockStarDeck deck;
  final double size;

  const _LeaderPortraitAvatar({
    required this.deck,
    this.size = 34,
  });

  String _leaderAssetPath(RockStarDeck deck) {
    switch (deck) {
      case RockStarDeck.gta6:
        return 'assets/cards/jason_duval.png';
      case RockStarDeck.viceCity:
        return 'assets/cards/tommy_vercetti.png';
      case RockStarDeck.gta5:
        return 'assets/cards/michael_de_santa.png';
      case RockStarDeck.sanAndreas:
        return 'assets/cards/carl_johnson.png';
      case RockStarDeck.rdr2:
        return 'assets/cards/arthur_morgan.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            _leaderAssetPath(deck),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF25324E),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: Color(0xFFFFD166),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardArtwork extends StatelessWidget {
  final GameCard card;
  final double height;

  const _CardArtwork({
    required this.card,
    this.height = 124,
  });

  IconData _fallbackIcon() {
    switch (card.ability) {
      case CardAbility.weather:
        return Icons.ac_unit_rounded;
      case CardAbility.clearWeather:
        return Icons.wb_sunny_rounded;
      case CardAbility.spy:
        return Icons.visibility_rounded;
      case CardAbility.medic:
        return Icons.medical_services_rounded;
      case CardAbility.scorch:
        return Icons.local_fire_department_rounded;
      case CardAbility.moralBoost:
        return Icons.military_tech_rounded;
      case CardAbility.none:
        return card.isHero ? Icons.stars_rounded : Icons.person_rounded;
    }
  }

  String _abilityTag() {
    switch (card.ability) {
      case CardAbility.weather:
        return 'CLIMA';
      case CardAbility.clearWeather:
        return 'LIMPAR';
      case CardAbility.spy:
        return 'ESPIAO';
      case CardAbility.medic:
        return 'MEDICO';
      case CardAbility.scorch:
        return 'QUEIMA';
      case CardAbility.moralBoost:
        return 'MORAL +1';
      case CardAbility.none:
        return card.isHero ? 'HEROI' : 'TROPA';
    }
  }

  Widget _buildStyledFallback() {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: card.isHero
              ? [const Color(0xFF523618), const Color(0xFF22160A)]
              : [const Color(0xFF253454), const Color(0xFF101626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: card.isHero
              ? const Color(0xFFFFD166).withValues(alpha: 0.45)
              : Colors.white12,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _fallbackIcon(),
              size: 36,
              color: card.isHero
                  ? const Color(0xFFFFD166)
                  : const Color(0xFF33E1ED),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _abilityTag(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          card.resolvedImageAsset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) {
            if (card.resolvedImageAsset != card.fallbackAssetPath) {
              return Image.asset(
                card.fallbackAssetPath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) =>
                    _buildStyledFallback(),
              );
            }
            return _buildStyledFallback();
          },
        ),
      ),
    );
  }
}

class _PlayerScoreBanner extends StatelessWidget {
  final PlayerBoardState player;
  final int totalScore;
  final Color accentColor;
  final Widget? trailing;

  const _PlayerScoreBanner({
    required this.player,
    required this.totalScore,
    required this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF141B2D),
      child: Row(
        children: [
          _LeaderPortraitAvatar(deck: player.selectedDeck, size: 34),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor),
            ),
            child: Text(
              '$totalScore PTS',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            player.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.workspace_premium_rounded,
            size: 18,
            color: player.roundsWon >= 1
                ? const Color(0xFFFFD166)
                : Colors.white24,
          ),
          Icon(
            Icons.workspace_premium_rounded,
            size: 18,
            color: player.roundsWon >= 2
                ? const Color(0xFFFFD166)
                : Colors.white24,
          ),
          const SizedBox(width: 10),
          Text(
            'Mao: ${player.hand.length}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          if (player.hasPassed) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PASSOU',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _CombatRowBar extends StatelessWidget {
  final String label;
  final CombatRow row;
  final List<GameCard> cards;
  final Set<CombatRow> activeWeather;
  final int leaderBonus;

  const _CombatRowBar({
    required this.label,
    required this.row,
    required this.cards,
    required this.activeWeather,
    this.leaderBonus = 0,
  });

  @override
  Widget build(BuildContext context) {
    final rowScore = GwentEngine.calculateRowScore(
      cards,
      row,
      activeWeather,
      leaderBonus: leaderBonus,
    );
    final hasWeather = activeWeather.contains(row);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: hasWeather ? const Color(0xFF162C3D) : const Color(0xFF111726),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasWeather ? const Color(0xFF33E1ED) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '$rowScore',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const VerticalDivider(color: Colors.white12),
          Expanded(
            child: cards.isEmpty
                ? Text(
                    hasWeather ? '$label (CLIMA ATIVO)' : label,
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, idx) {
                      final c = cards[idx];
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c.isHero
                                ? const Color(0xFF3B2814)
                                : const Color(0xFF1E273D),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: c.isHero
                                  ? const Color(0xFFFFD166)
                                  : Colors.white24,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Image.asset(
                                    c.resolvedImageAsset,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.white10,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${c.basePower}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${c.basePower}  ${c.name}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (leaderBonus > 0 && cards.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+$leaderBonus Lider',
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HandCardTile extends StatelessWidget {
  final GameCard card;
  final bool isSelected;
  final VoidCallback? onTap;

  const _HandCardTile({
    required this.card,
    required this.isSelected,
    this.onTap,
  });

  String _rowLabel(CombatRow row) {
    switch (row) {
      case CombatRow.close:
        return 'Proximo';
      case CombatRow.ranged:
        return 'Alcance';
      case CombatRow.siege:
        return 'Cerco';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 152,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF233252) : const Color(0xFF171F33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF33E1ED)
                : (card.isHero ? const Color(0xFFFFD166) : Colors.white24),
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF33E1ED).withValues(alpha: 0.24),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: card.isHero
                      ? const Color(0xFFFFD166)
                      : const Color(0xFFFF3B8D),
                  child: Text(
                    '${card.basePower}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _rowLabel(card.row),
                  style: const TextStyle(
                    color: Color(0xFF33E1ED),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _CardArtwork(card: card, height: 124),
            const SizedBox(height: 6),
            Text(
              card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              card.gameOrigin,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Text(
              card.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
