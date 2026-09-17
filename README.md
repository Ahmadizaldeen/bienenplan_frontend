# BienenPlan Flutter Frontend

BienenPlan ist eine plattformübergreifende Flutter-Anwendung zur gemeinsamen
Planung und Verwaltung von Projekten, Containern und Aufgaben. Die Daten werden
über eine REST-API aus dem BienenPlan-Backend geladen und verwaltet.

## Aktueller Stand

- Startscreen mit Navigation zu Anmeldung und Registrierung
- Login mit E-Mail und Passwort sowie JWT-Sitzung in `flutter_secure_storage`
- Automatischer Login beim App-Start, Abmelden und Löschen der lokalen Sitzung
- Prüfung der Backend-Erreichbarkeit direkt vom Startscreen
- Home-Ansicht mit Sidebar, Projektübersicht und zentralem Pull-to-Refresh
- Projekte über die REST-API laden, erstellen und auswählen
- Zuletzt ausgewähltes Projekt lokal speichern und beim Laden wiederherstellen
- Aufgaben des ausgewählten Projekts nach Containern gruppiert anzeigen
- Container für ein Projekt erstellen und Aufgaben zu einem Container hinzufügen
- Aufgaben mit Titel, Beschreibung, Status und optionaler Frist erstellen und bearbeiten
- Gruppen einer Aufgabe laden sowie zuweisen oder entfernen
- Datei-Anhänge für Aufgaben auswählen, hochladen und anzeigen
- API-Client mit GET, POST, PUT, DELETE und Multipart-Upload
- Light- und Dark-Theme mit wiederverwendbaren Glass-UI-Komponenten

## Domänenmodell

```text
Benutzer
  └── Projekt
        └── Container
              └── Aufgaben
                    ├── Gruppen-Zuweisungen
                    └── Anhang
```


## Projektstruktur

```text
lib/
├── core/
│   ├── api/       HTTP-Client, Endpunkte und API-Fehler
│   ├── routing/   Routen und Navigation
│   └── theme/     Farben, Abstände, Themes und GlassContainer
├── features/
│   ├── auth/      Auth-Gate, Startscreen, Login, Registrierung und Repository
│   ├── home/      Home-Screen, Sidebar und Projektübersicht
│   ├── projects/  Projektmodell, Repository, lokaler Store, Controller und Liste
│   └── tasks/     Aufgaben-, Container- und Gruppenmodelle, Repositories,
│                  Controller, Container-Ansicht und Dialoge
└── main.dart      Einstiegspunkt und Auto-Login-Prüfung
```

## Sicherheit

- Bei einer nicht autorisierten Antwort wird das Token gelöscht.
- Passwörter werden nicht lokal gespeichert.
- Die zuletzt ausgewählte Projekt-ID wird lokal gespeichert; sie ist reiner
  Client-Zustand und wird nicht mit dem Backend synchronisiert.

## Noch offen

- Echte Profildaten statt der derzeitigen Platzhalterdaten anzeigen
- Suche und Kennzahlen der Projektübersicht mit echten Daten verknüpfen
- Teilaufgaben und Kommentare zu Aufgaben unterstützen
- Aufgaben und Container bearbeiten oder löschen
- Gruppenberechtigungen, Rollen und Zugriffsrechte in der Oberfläche abbilden
- Responsive Darstellung für Web, Desktop und mobile Geräte weiter verfeinern
- Konfigurierbare Backend-URL für Entwicklungs- und Produktionsumgebungen

## Voraussetzungen

- Flutter SDK mit Dart SDK
- Laufendes BienenPlan-Backend
- Chrome oder ein anderes unterstütztes Flutter-Zielgerät

Flutter installieren: <https://docs.flutter.dev/install/manual>

Die aktuell verwendeten Versionen und Abhängigkeiten stehen in
`pubspec.yaml`. Das Projekt verwendet unter anderem `http`,
`flutter_secure_storage` und `file_picker`.

## Installation und Start

```bash
flutter pub get
flutter run -d chrome
```

Für einen lokalen Qualitätscheck:

```bash
flutter analyze
flutter test
```

Die Backend-Basis-URL ist aktuell in
`lib/core/api/api_endpoints.dart` auf die lokale XAMPP-Adresse gesetzt:

```text
http://localhost/BienenPlan/backend/public/api
```

## Backend

Das zugehörige REST-Backend basiert auf Slim Framework, PHP und MySQL:
<https://github.com/Ahmadizaldeen/BienenPlan>
