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
- Container für ein Projekt erstellen und Aufgaben zu einem Container hinzufügen;
  Container werden nach ID sortiert, neue Container erscheinen rechts
- Ein einheitlicher Aufgaben-Dialog zum Erstellen und Bearbeiten mit Titel,
  Beschreibung, Status (`open`, `in_progress`, `done`) und optionaler Frist
- Standardstatus neuer Aufgaben ist `open`; ein leerer Status wird als „Offen“ angezeigt
- Gruppen einer Aufgabe per Dropdown zuweisen oder entfernen; bei neuen Aufgaben
  wird die Auswahl vorgemerkt und nach dem Erstellen übernommen
- Neue Gruppen direkt aus dem Aufgaben-Dialog mit Name und Mitgliederauswahl anlegen
- Persönliche Gruppen werden mit dem Benutzernamen statt „Personal user {id}“ angezeigt
- Datei-Anhänge für Aufgaben auswählen, hochladen und anzeigen
- Upload-Dateien vor dem Senden nach Endung, Größe und Binärinhalt prüfen
- Profilbilder sicher hochladen und nach einem App-Neustart wieder anzeigen
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
│   ├── files/     Wiederverwendbare Datei- und Inhaltsprüfung
│   ├── routing/   Routen und Navigation
│   └── theme/     Farben, Abstände, Themes und GlassContainer
├── features/
│   ├── auth/      Auth-Gate, Startscreen, Login, Registrierung und Repository
│   ├── home/      Home-Screen, Sidebar und Projektübersicht
│   ├── projects/  Projektmodell, Repository, lokaler Store, Controller und Liste
│   ├── settings/  Einstellungsdialog
│   ├── user/      Benutzermodelle (inkl. GroupUser), Profilzustand und Profilbild-Upload
│   └── tasks/     Aufgaben-, Container- und Gruppenmodelle, Repositories,
│                  Controller, Container-Ansicht, TaskDialog und CreateGroupDialog
└── main.dart      Einstiegspunkt und Auto-Login-Prüfung
```

## Aufgaben und Gruppen

`showTaskDialog` in `lib/features/tasks/presentation/task_dialog.dart` ist die
gemeinsame Maske für neue und bestehende Aufgaben (ersetzt die früheren
`task_create_dialog.dart` und `task_detail_dialog.dart`). Beim Bearbeiten
werden Gruppenänderungen sofort über die API übernommen; beim Erstellen werden
sie gesammelt und nach dem Anlegen der Aufgabe zugewiesen.

Über `CreateGroupDialog` lässt sich eine neue Gruppe anlegen. Dafür lädt die App
die Benutzer über `GET /api/users` und sendet `POST /api/groups` mit `name` und
`user_ids`. Persönliche Gruppen erkennt das Frontend an `personal_user_id`
(Fallback: Name „Personal user {id}“) und zeigt `personal_user_name` als
Anzeigenamen an. Gruppenlisten werden nach diesem Anzeigenamen sortiert.

## Sicherheit

- Bei einer nicht autorisierten Antwort wird das Token gelöscht.
- Passwörter werden nicht lokal gespeichert.
- Profilbilder werden im Frontend und verbindlich im Backend anhand von Größe,
  Dateiendung und Binärformat geprüft. Erlaubt sind JPG und PNG bis 5 MB.
- Die zuletzt ausgewählte Projekt-ID wird lokal gespeichert; sie ist reiner
  Client-Zustand und wird nicht mit dem Backend synchronisiert.

## Benutzerprofil

Beim Laden der Home-Ansicht ruft die App `GET /api/me` auf und zeigt Name,
E-Mail-Adresse sowie das gespeicherte Profilbild in der Sidebar an. Über
**Einstellungen** > **Profil** kann ein JPG- oder PNG-Bild ausgewählt werden.
Der Upload erfolgt als Multipart-Anfrage an `POST /api/me/picture`; nach einem
erfolgreichen Upload wird die Vorschau sofort aktualisiert und das Bild beim
nächsten Start über den vom Backend gelieferten Pfad geladen.

## Noch offen

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

Die Backend-Basis-URL wird in `lib/core/api/api_endpoints.dart` zusammengesetzt.
Für ein physisches Android-Gerät muss der Rechner und das Gerät im selben WLAN
sein. Starte die App mit der LAN-IP des Rechners und dem Apache-Port:

```text
flutter run --dart-define=API_SERVER_BASE_URL=http://192.168.1.25:8080/BienenPlanBackend/backend/public
```

Ersetze `192.168.1.25:8080` durch die Ausgabe von `ipconfig` (IPv4-Adresse)
und den in XAMPP verwendeten Apache-Port. Bei Standard-Apache-Port 80 entfällt
`:8080`. Die Windows-Firewall muss eingehende Verbindungen zu diesem Port
zulassen.
Wenn ein Apache-VirtualHost direkt auf `backend/public` zeigt, gib
statt des Projektpfads nur den Host und ggf. Port an, z. B.
`API_SERVER_BASE_URL=http://192.168.1.25:8080`.

## Backend

Das zugehörige REST-Backend basiert auf Slim Framework, PHP und MySQL:
<https://github.com/Ahmadizaldeen/BienenPlan>
