# Météo 7 Jours (macOS)

Application de barre de menus macOS qui affiche, **directement dans la barre de menu**, la météo du jour
(icône + température) de votre ville de résidence, et un panneau avec les **prévisions sur les 7 prochains
jours** (températures min/max, pictogramme, probabilité de pluie) pour **plusieurs villes** au choix.

Toutes les données proviennent de **Météo-France** (mêmes prévisions que l'application officielle :
recherche de lieux, prévisions horaires/quotidiennes, observation en temps réel).

## Prérequis

- macOS 13 (Ventura) ou ultérieur
- Xcode 15 ou ultérieur
- Un jeton d'accès Météo-France (gratuit, voir ci-dessous)

## Obtenir un jeton Météo-France (gratuit)

1. Créez un compte sur le portail des API de Météo-France :
   [portail-api.meteofrance.fr](https://portail-api.meteofrance.fr/web/fr/)
2. Dans « Mes API », créez une application puis générez un **jeton d'accès longue durée** (durée illimitée).
3. Lancez l'application, ouvrez les réglages (engrenage dans le panneau), collez le jeton dans
   « Connexion Météo-France » et cliquez sur **Enregistrer le jeton**.

Le jeton est stocké localement dans le **trousseau** macOS ; il n'est jamais embarqué dans l'application.

## Compilation et exécution

1. Ouvrez `Meteo7Jours.xcodeproj` dans Xcode.
2. Sélectionnez votre équipe de développement dans *Signing & Capabilities* (ou laissez la signature
   automatique locale).
3. Lancez avec **⌘R** (schéma *Meteo7Jours*, destination *Mon Mac*).

L'application n'apparaît que dans la barre de menus (pas d'icône dans le Dock).

## Utilisation

- **Barre de menus** : température actuelle et pictogramme météo de votre ville de résidence
  (rafraîchie toutes les 15 minutes et à chaque clic sur « Rafraîchir »).
- **Clic sur l'icône de la barre de menus** : panneau avec la météo du jour (température ressentie,
  températures min/max) et la liste des 7 prochains jours.
- **Sélecteur de ville** en haut du panneau : choisissez parmi vos villes enregistrées.
- **Réglages (engrenage)** :
  - enregistrer le jeton Météo-France ;
  - rechercher et ajouter des villes (nom ou code postal), les supprimer, et définir celle de
    **domicile** (bouton « Domicile ») utilisée par défaut dans la barre de menus ;
  - activer « Ouvrir au démarrage » pour lancer l'app à l'ouverture de session.

## Structure du projet

```
Meteo7Jours.xcodeproj/     Projet Xcode
Meteo7Jours/
  Meteo7JoursApp.swift     Point d'entrée SwiftUI (@main) + MenuBarExtra
  AppDelegate.swift        Rafraîchissement périodique (toutes les 15 min)
  ForecastView.swift       Panneau : météo du jour + prévisions 7 jours + sélecteur de ville
  SettingsView.swift       Réglages : jeton, villes (domicile par défaut), démarrage auto
  WeatherViewModel.swift   Logique de rafraîchissement (ville sélectionnée + ville de résidence)
  MeteoFranceClient.swift  Client HTTP de l'API Météo-France (webservice.meteofrance.com)
  Models.swift             Modèles Codable (lieux, prévisions horaires/quotidiennes, observation)
  CityStore.swift          Villes favorites + ville par défaut (UserDefaults)
  KeychainStore.swift      Stockage sécurisé du jeton (Security.framework)
  WeatherIcon.swift        Conversion pictogrammes Météo-France → SF Symbols
  Info.plist               LSUIElement (app barre de menus uniquement)
  Meteo7Jours.entitlements Sandbox + accès réseau client
```

## API utilisée

L'application appelle le service web de Météo-France (`https://webservice.meteofrance.com`) avec votre
jeton passé en paramètre `token` :

- `GET /places?q=…` : recherche de villes (nom ou code postal) ;
- `GET /forecast?lat=…&lon=…&lang=fr` : prévisions horaires et quotidiennes (jusqu'à 15 jours) ;
- `GET /v2/observation?lat=…&lon=…&lang=fr` : observation en temps réel (température actuelle, temps).

## Données et confidentialité

- Les prévisions affichées sont celles produites par Météo-France.
- Le jeton reste sur votre Mac (trousseau). Les villes enregistrées restent dans les réglages locaux
  de l'app. Aucune donnée n'est envoyée ailleurs qu'à l'API de Météo-France.
- Pensez à créditer la source dans toute redistribution : « Source : Météo-France ».
