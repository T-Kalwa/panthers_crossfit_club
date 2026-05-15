class PlanDetails {
  final double price;
  final int days;
  final String description;

  PlanDetails({
    required this.price,
    required this.days,
    required this.description,
  });
}

class PanthersPricing {
  static PlanDetails getPlanDetails(String activite, String duree, bool avecCoach) {
    final act = activite.toUpperCase();
    final dur = duree.toLowerCase();

    if (act == 'CROSSFIT') {
      switch (dur) {
        case '1 séance':
          return PlanDetails(price: 15.0, days: 1, description: '1 Séance CrossFit');
        case '10 jours':
          return PlanDetails(price: avecCoach ? 60.0 : 50.0, days: 10, description: 'Pack 10 Jours CrossFit');
        case '1 mois':
          return PlanDetails(price: avecCoach ? 160.0 : 130.0, days: 30, description: 'Abonnement Mensuel CrossFit');
        case '3 mois':
          return PlanDetails(price: avecCoach ? 460.0 : 370.0, days: 90, description: 'Abonnement Trimestriel CrossFit');
        case '6 mois':
          return PlanDetails(price: avecCoach ? 920.0 : 740.0, days: 180, description: 'Abonnement Semestriel CrossFit');
        case 'annuel':
          return PlanDetails(price: avecCoach ? 1760.0 : 1400.0, days: 365, description: 'Abonnement Annuel CrossFit');
      }
    } else if (act == 'BOXE') {
      switch (dur) {
        case '1 séance':
          return PlanDetails(price: 10.0, days: 1, description: '1 Séance Boxe');
        case '1 mois':
          return PlanDetails(price: 90.0, days: 30, description: 'Abonnement Mensuel Boxe');
        case '3 mois':
          return PlanDetails(price: 250.0, days: 90, description: 'Abonnement Trimestriel Boxe');
        case '6 mois':
          return PlanDetails(price: 500.0, days: 180, description: 'Abonnement Semestriel Boxe');
      }
    } else if (act == 'ZUMBA' || act == 'ZUMBA / AÉRO') {
      switch (dur) {
        case '1 séance':
          return PlanDetails(price: 15.0, days: 1, description: '1 Séance Zumba');
        case '1 mois':
          return PlanDetails(price: 100.0, days: 30, description: 'Abonnement Mensuel Zumba');
      }
    }

    // Default fallback
    return PlanDetails(price: 0.0, days: 0, description: 'Plan Inconnu');
  }

  static DateTime calculateExpiryDate(DateTime startDate, int daysToAdd) {
    return startDate.add(Duration(days: daysToAdd));
  }
}
