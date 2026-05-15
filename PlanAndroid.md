1. Crée une version web pour l'admin ( elle va exploiter firetore + et Hive storage ) pour la rapidité de scanne 
2. Crée une version juste android juste pour l'authentifacation des clients et du staff
3. FONCTIONNEMENT GENERAL DE L'APPLICATION ( VERSION DEMO )
    - Syteme d'authentification : une fois inscrit et que le paiement est validé par l'admin ou le staff , il faut générer un code QR unique pour chaque client. 
    - ce code QR sera stocké dans le cloud firestore et expirera selon le type d'abonnement du client
    - si le code QR est valide et non expiré, afficher un message de bienvenue et autoriser l'accès à la salle
    - si le code QR est expiré ou invalide, afficher un message d'erreur et refuser l'accès à la salle
    - le Qr code doit etre partageable et telechargeable ( en format png ou jpeg ou pdf  avec le type ou ladte d'aabonnement ecris dessus , et le logo de la salle ) pour qu'il puisse etre utilisé 
    - il n'y aura pas de vesrion pour le client , et c'est poyr ca que lui aura seulment a s'ecrit aupres de la salle pour obtenir son code QR et attendre que l'on lui envoie soit par whatsapp ou par mail ou par sms ou par bluetooth
     il peut exploiter les donnes qui sont dans le firebase du projet 
4. VERSION WEB 
    4.1 le compte admin sur le web pour acceder a tout les fonctionnalités du systeme et du projet
    crée l'architecture de base de l'application web 
    4.2 il va exploiter firebase pour cree les membre du staffes et inscrire des clients

