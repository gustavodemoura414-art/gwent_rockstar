enum RockStarDeck {
  gta6,
  viceCity,
  gta5,
  sanAndreas,
  rdr2;

  String get displayName {
    switch (this) {
      case RockStarDeck.gta6:
        return 'GTA VI';
      case RockStarDeck.viceCity:
        return 'Vice City';
      case RockStarDeck.gta5:
        return 'GTA V';
      case RockStarDeck.sanAndreas:
        return 'San Andreas';
      case RockStarDeck.rdr2:
        return 'Red Dead 2';
    }
  }
}

enum CombatRow {
  close, // Combate Proximo
  ranged, // Alcance / Tiro
  siege, // Cerco / Caos & Veiculos
}

enum CardAbility {
  none,
  moralBoost, // +1 de forca para outras cartas nao-heroi da mesma fileira
  spy, // Joga no campo inimigo; voce compra 2 cartas do baralho
  medic, // Revive 1 carta nao-heroi do seu cemiterio ao jogar
  scorch, // Destroi a(s) carta(s) nao-heroi mais forte(s) em campo (se maior forca >= 8)
  weather, // Reduz a forca base das cartas nao-heroi de uma fileira para 1
  clearWeather, // Limpa todos os efeitos de clima ativos
}

class GameCard {
  final String id;
  final String name;
  final RockStarDeck deck;
  final CombatRow row;
  final int basePower;
  final bool isHero;
  final CardAbility ability;
  final CombatRow? weatherTargetRow;
  final String description;
  final String? imageAsset;

  const GameCard({
    required this.id,
    required this.name,
    required this.deck,
    required this.row,
    required this.basePower,
    this.isHero = false,
    this.ability = CardAbility.none,
    this.weatherTargetRow,
    required this.description,
    this.imageAsset,
  });

  String get gameOrigin => deck.displayName;

  /// Caminho principal esperado em assets/cards/<id>.png
  String get cardAssetPath => 'assets/cards/$id.png';

  /// Caminho secundario por baralho/habilidade caso o arquivo individual ainda nao exista
  String get fallbackAssetPath {
    if (ability == CardAbility.weather) {
      return 'assets/cards/weather_storm.png';
    }
    if (ability == CardAbility.clearWeather) {
      return 'assets/cards/weather_clear.png';
    }
    switch (deck) {
      case RockStarDeck.gta6:
        return 'assets/cards/deck_gta6.png';
      case RockStarDeck.viceCity:
        return 'assets/cards/deck_vice_city.png';
      case RockStarDeck.gta5:
        return 'assets/cards/deck_gta5.png';
      case RockStarDeck.sanAndreas:
        return 'assets/cards/deck_san_andreas.png';
      case RockStarDeck.rdr2:
        return 'assets/cards/deck_rdr2.png';
    }
  }

  String get resolvedImageAsset {
    final explicit = imageAsset;
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    return cardAssetPath;
  }

  GameCard copyWith({
    String? id,
    String? imageAsset,
  }) {
    return GameCard(
      id: id ?? this.id,
      name: name,
      deck: deck,
      row: row,
      basePower: basePower,
      isHero: isHero,
      ability: ability,
      weatherTargetRow: weatherTargetRow,
      description: description,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }
}
