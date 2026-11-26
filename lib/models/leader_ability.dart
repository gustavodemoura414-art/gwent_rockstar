import 'package:gwent_gta6/models/game_card.dart';

enum LeaderAbilityType {
  leonidaRush, // GTA VI: +5 na fileira de Alcance (ou Proximo)
  malibuEmpire, // Vice City: limpa clima e +3 no Combate Proximo
  losSantosChaos, // GTA V: queima maior unidade nao-heroi (>= 7)
  groveRespect, // San Andreas: compra 1 carta e +2 no Combate Proximo
  thePlan, // RDR2: +2 para todas as unidades nao-heroi do jogador
}

class LeaderAbility {
  final LeaderAbilityType type;
  final String leaderName;
  final String title;
  final String description;

  const LeaderAbility({
    required this.type,
    required this.leaderName,
    required this.title,
    required this.description,
  });

  static LeaderAbility forDeck(RockStarDeck deck) {
    switch (deck) {
      case RockStarDeck.gta6:
        return const LeaderAbility(
          type: LeaderAbilityType.leonidaRush,
          leaderName: 'Jason & Lucia',
          title: 'Golpe em Leonida',
          description: '+5 de forca na sua fileira de Alcance (ou Proximo).',
        );
      case RockStarDeck.viceCity:
        return const LeaderAbility(
          type: LeaderAbilityType.malibuEmpire,
          leaderName: 'Tommy Vercetti',
          title: 'Imperio de Malibu',
          description: 'Limpa o clima e da +3 de forca no Combate Proximo.',
        );
      case RockStarDeck.gta5:
        return const LeaderAbility(
          type: LeaderAbilityType.losSantosChaos,
          leaderName: 'Michael & Trevor',
          title: 'Caos em Los Santos',
          description:
              'Destroi a(s) unidade(s) nao-heroi mais forte(s) (>= 7).',
        );
      case RockStarDeck.sanAndreas:
        return const LeaderAbility(
          type: LeaderAbilityType.groveRespect,
          leaderName: 'Carl "CJ" Johnson',
          title: 'Respeito de Grove Street',
          description: 'Compra 1 carta e da +2 no Combate Proximo.',
        );
      case RockStarDeck.rdr2:
        return const LeaderAbility(
          type: LeaderAbilityType.thePlan,
          leaderName: 'Dutch van der Linde',
          title: 'O Plano',
          description: '+2 de forca para todas as suas unidades nao-heroi.',
        );
    }
  }
}
