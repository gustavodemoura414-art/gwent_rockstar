import 'package:flutter/material.dart';
import 'package:gwent_gta6/data/rockstar_decks.dart';
import 'package:gwent_gta6/models/game_card.dart';
import 'package:gwent_gta6/models/match_state.dart';
import 'package:gwent_gta6/screens/gwent_board_screen.dart';

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  RockStarDeck _p1Deck = RockStarDeck.gta6;
  RockStarDeck _p2Deck = RockStarDeck.viceCity;

  Color _deckColor(RockStarDeck deck) {
    switch (deck) {
      case RockStarDeck.gta6:
        return const Color(0xFFFF3B8D);
      case RockStarDeck.viceCity:
        return const Color(0xFF33E1ED);
      case RockStarDeck.gta5:
        return const Color(0xFF4ADE80);
      case RockStarDeck.sanAndreas:
        return const Color(0xFFFACC15);
      case RockStarDeck.rdr2:
        return const Color(0xFFF59E0B);
    }
  }

  void _startMatch(GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GwentBoardScreen(
          mode: mode,
          p1Deck: _p1Deck,
          p2Deck: _p2Deck,
        ),
      ),
    );
  }

  Widget _buildDeckSelector({
    required String title,
    required RockStarDeck selected,
    required Color accent,
    required ValueChanged<RockStarDeck> onSelect,
  }) {
    final cardCount = RockstarDecks.cardsForDeck(selected).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161E33), Color(0xFF0F1524)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cardCount cartas',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RockStarDeck.values.map((deck) {
              final isSelected = deck == selected;
              final deckTint = _deckColor(deck);
              return ChoiceChip(
                label: Text(deck.displayName),
                selected: isSelected,
                selectedColor: deckTint,
                backgroundColor: const Color(0xFF1B2338),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? deckTint : Colors.white12,
                  ),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (_) => onSelect(deck),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.2,
            colors: [
              Color(0xFF1D1736),
              Color(0xFF0A0D16),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B8D).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF3B8D).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.style_rounded,
                      size: 46,
                      color: Color(0xFFFF3B8D),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ROCKSTAR GWENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'GTA VI  •  VICE CITY  •  GTA V  •  SAN ANDREAS  •  RED DEAD 2',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Color(0xFF33E1ED),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDeckSelector(
                    title: 'BARALHO DO JOGADOR 1',
                    selected: _p1Deck,
                    accent: _deckColor(_p1Deck),
                    onSelect: (deck) => setState(() => _p1Deck = deck),
                  ),
                  const SizedBox(height: 12),
                  _buildDeckSelector(
                    title: 'BARALHO DO ADVERSARIO (IA / JOGADOR 2)',
                    selected: _p2Deck,
                    accent: _deckColor(_p2Deck),
                    onSelect: (deck) => setState(() => _p2Deck = deck),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B8D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _startMatch(GameMode.vsAi),
                      icon: const Icon(Icons.smart_toy_rounded),
                      label: const Text(
                        'JOGAR CONTRA IA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF33E1ED),
                        side: const BorderSide(
                          color: Color(0xFF33E1ED),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _startMatch(GameMode.twoPlayersLocal),
                      icon: const Icon(Icons.people_alt_rounded),
                      label: const Text(
                        '2 JOGADORES (PASSAR A VEZ)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
