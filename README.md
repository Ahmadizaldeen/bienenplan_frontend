# 🌱 Bienen Plan Flutter UI 

Eine plattformübergreifende Projekt-Management-Anwendung für das Verwatung von Aufgaben in Übergeordente Contienern.
Benutzerverwaltung und authenirern und für Team mit gruppierung von Benutzen.

User
 │
 ├── Gruppen (m:n über users_gruppen)
 │
 └── Projekte (Zugriff über projekt_gruppen)
       │
       └── Container (1:n)
             │
             └── Aufgaben (1:n)

Hinweis: Ein Projekt gehört keiner einzelnen Gruppe fest, sondern kann von mehreren beteiligten Gruppen eingesehen werden. Der Projekt-Ersteller ist automatisch Mitglied und kann weitere Gruppen hinzufügen.

install Flutter : https://docs.flutter.dev/install/manual
extrahieren und path in Umgebungsvariable eintagren , flutten/bin

in Termional:
 flutter --version

flutter pub get
flutter create .
flutter pub add http
flutter pub add flutter_secure_storage
flutter run -d chrome

install SDK : https://dart.dev/get-dart



📁 Projektstruktur
BienenPlan_frontend/
├───lib/
├── core/
│   ├── api/           → ApiClient (HTTP + JWT), ApiEndpoints (URLs)
│   └── constants/     → AppColors
├── features/
│   ├── auth/           → login_screen.dart ↔ auth_repository.dart
│   └── tasks/          → task_list_screen.dart ↔ task_repository.dart ↔ task_model.dart
└── main.dart           → Einstieg + Auto-Login-Check




# BienenPlan Flutter Frontend

BienenPlan ist eine plattformübergreifende Flutter-Anwendung zur gemeinsamen
Planung und Verwaltung von Aufgaben. Aufgaben gehören zu einem Container und
werden über eine REST-API aus dem BienenPlan-Backend geladen.

## Aktueller Funktionsumfang

- Startscreen mit Navigation zu Anmeldung und Registrierung
- Login mit E-Mail und Passwort
- JWT-Sitzung mit sicherer Speicherung über `flutter_secure_storage`
- Automatischer Login beim App-Start, wenn ein gültiges Token vorhanden ist
- Abmelden und Löschen der lokalen Sitzung
- Prüfung, ob die Backend-API erreichbar ist
- Laden der Aufgaben über die REST-API
- Aktualisieren der Aufgabenliste per Button oder Pull-to-Refresh
- Anzeige von Titel, Beschreibung, Container, Ersteller, Status und Frist
- Anzeige von Lade-, Fehler- und Leerzuständen
- Light- und Dark-Theme mit wiederverwendbaren Glass-UI-Komponenten

Die aktuelle Aufgabenansicht ist eine flache Liste. Der Container wird pro
Aufgabe angezeigt, die gruppierte Container-Ansicht ist als nächster
UI-Meilenstein geplant.

## Domänenmodell

```text
Benutzer
  └── Gruppen (m:n)
        └── Projekte (m:n über Projektberechtigungen)
              └── Container (1:n)
                    └── Aufgaben (1:n)
```

Ein Projekt kann von mehreren beteiligten Gruppen eingesehen werden. Der
Ersteller eines Projekts ist automatisch Mitglied und kann weitere Gruppen
hinzufügen.

## Projektstruktur

```text
lib/
├── core/
│   ├── api/       HTTP-Client, Endpunkte und API-Fehler
│   └── theme/     Farben, Abstände, Themes und GlassContainer
├── features/
│   ├── auth/      Startscreen, Login, Registrierung und AuthRepository
│   └── tasks/     Task-Modell, Repository, Liste und Task-Widget
└── main.dart      Einstiegspunkt und Auto-Login-Prüfung
```

## Voraussetzungen und Start

- Flutter SDK mit Dart SDK
- Laufendes BienenPlan-Backend
- Chrome oder ein anderes unterstütztes Flutter-Zielgerät

Flutter installieren: <https://docs.flutter.dev/install/manual>

```bash
flutter --version
flutter pub get
flutter run -d chrome
```

Die Backend-Basis-URL ist aktuell in
`lib/core/api/api_endpoints.dart` auf die lokale XAMPP-Adresse gesetzt:

```text
http://localhost/BienenPlan/backend/public/api
```

Für ein anderes Gerät oder eine andere Backend-Umgebung muss diese URL
angepasst werden.

## Sicherheit

- JWT-Tokens werden über `flutter_secure_storage` gespeichert.
- API-Aufrufe senden das Token als `Authorization: Bearer <token>`.
- Bei einer nicht autorisierten Antwort wird das Token gelöscht.
- Passwörter werden nicht lokal gespeichert.

## Geplante Meilensteine

### Meilenstein 1: Aufgabenverwaltung vervollständigen

- Statusänderung direkt in der Task-Karte ermöglichen
- Statusänderung über das vorhandene API-Repository ausführen
- Erfolgs- und Fehlermeldungen in der Oberfläche anzeigen
- Ladezustände während einer Statusänderung absichern

### Meilenstein 2: Container-Ansicht

- Aufgaben nach `containerId` gruppieren
- Pro Container eine eigene Spalte beziehungsweise einen eigenen Bereich
- Container-Kopf mit Titel und Aufgabenanzahl anzeigen
- Leere Container und lange Container-Namen sauber behandeln

### Meilenstein 3: Aufgaben erstellen und bearbeiten

- Formular zum Erstellen einer Aufgabe
- Container-Auswahl
- Fristenauswahl und optionale Beschreibung
- Bearbeiten und Löschen mit Bestätigungsdialog

### Meilenstein 4: Projekt- und Gruppenverwaltung

- Projekte und Container laden und auswählen
- Gruppenberechtigungen sichtbar machen
- Rollen und Zugriffsrechte in der Oberfläche berücksichtigen

### Meilenstein 5: Qualität und Release

- Unit-Tests für Model, Repository und Authentifizierung
- Widget-Tests für Login-, Fehler- und Container-Ansicht
- Responsive Darstellung für Web, Desktop und mobile Geräte
- Konfigurierbare Backend-URL für Entwicklungs- und Produktionsumgebungen

## Technischer Status

| Bereich | Status |
| --- | --- |
| Flutter-Grundgerüst und Themes | ✅ Vorhanden |
| Login und JWT-Authentifizierung | ✅ Vorhanden |
| Auto-Login und Abmelden | ✅ Vorhanden |
| Aufgaben laden und aktualisieren | ✅ Vorhanden |
| Aufgaben nach Container gruppieren | ⏳ Geplant |
| Aufgabenstatus in der UI ändern | ⏳ Geplant |
| Aufgabe erstellen und bearbeiten | ⏳ Geplant |
| Projekt- und Gruppenverwaltung | ⏳ Geplant |
| Automatisierte Tests | ⏳ Ausbauen |

## Backend

Das zugehörige REST-Backend basiert auf Slim Framework, PHP und MySQL:
<https://github.com/Ahmadizaldeen/BienenPlan>