# BienenPlan Flutter Frontend

BienenPlan ist eine plattformübergreifende Flutter-Anwendung zur gemeinsamen
Planung und Verwaltung von Aufgaben. Aufgaben gehören zu einem Container und
werden über eine REST-API aus dem BienenPlan-Backend geladen.

## Aktueller Stand

- Startscreen mit Navigation zu Anmeldung und Registrierung
- Login mit E-Mail und Passwort
- JWT-Sitzung mit sicherer Speicherung über `flutter_secure_storage`
- Automatischer Login beim App-Start, wenn ein gültiges Token vorhanden ist
- Abmelden und Löschen der lokalen Sitzung
- Prüfung, ob die Backend-API erreichbar ist, direkt vom Startscreen
- Laden der Aufgaben über die REST-API
- Aktualisieren der Aufgabenliste per Button oder Pull-to-Refresh
- Anzeige von Titel, Beschreibung, Container, Ersteller, Status- Anzeige von Lade-, Fehler- und Leerzuständen
- Light- und Dark-Theme mit wiederverwendbaren Glass-UI-Komponenten
- Tests für Routing, Controller und Dependency Injection


## Domänenmodell

```text
Benutzer (Projekt owner, personal Groupe)
  └── Projekt  
        └── Gruppen
              └── Containers
                    └── Aufgaben (an Gruppen zugewissen )
                        └── Teil-Aufgaben 
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
│   └── tasks/     Modell, Repository, Controller, Liste und Task-Widget
└── main.dart      Einstiegspunkt und Auto-Login-Prüfung
```

## Sicherheit

- Bei einer nicht autorisierten Antwort wird das Token gelöscht.
- Passwörter werden nicht lokal gespeichert.

## Noch offen

### Aufgabenverwaltung

- Statusänderung direkt in der Task-Karte ermöglichen
- Statusänderung über das vorhandene API-Repository ausführen
- Erfolgs- und Fehlermeldungen in der Oberfläche anzeigen
- Ladezustände während einer Statusänderung absichern

### Container-Ansicht

- Aufgaben nach `containerId` gruppieren
- Pro Container eine eigene Bereich
- Container-Kopf mit Titel und Aufgabenanzahl anzeigen

### Home-Ansicht (Layout nach dem Login)

- Profil-Widget mit Benutzerinformationen
- Projekt-Spalte zur Projektauswahl
- Container-Ansicht als zentrales Element
- Eigenes `ProjectModel`/`ProjectRepository`

### Task-Detail-Ansicht

- Neues, interaktives Widget für alle Task-Details (statt Kurzansicht)
- Subtasks mit einfachem Status (offen/erledigt)
- Kommentare zu einer Aufgabe anzeigen und hinzufügen
- Anhänge (Dateien oder Bilder) hochladen und anzeigen
- Gruppen zu einer Aufgabe erstellen und anzeigen

### Aufgaben erstellen und bearbeiten

- Formular zum Erstellen einer Aufgabe, vo Container-Widget zugriffbar
- Bearbeiten und Löschen mit Bestätigungsdialog

### Projekt- und Gruppenverwaltung

- Projekte und Container laden und auswählen
- Gruppenberechtigungen sichtbar machen
- Rollen und Zugriffsrechte in der Oberfläche berücksichtigen

### Qualität und Release

- Responsive Darstellung für Web, Desktop und mobile Geräte
- Konfigurierbare Backend-URL für Entwicklungs- und Produktionsumgebungen

## Voraussetzungen

- Flutter SDK mit Dart SDK
- Laufendes BienenPlan-Backend
- Chrome oder ein anderes unterstütztes Flutter-Zielgerät

Flutter installieren: <https://docs.flutter.dev/install/manual>

Die aktuell verwendeten Versionen und Abhängigkeiten stehen in
`pubspec.yaml`. Das Projekt verwendet unter anderem `http` und
`flutter_secure_storage`.

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
