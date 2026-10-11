# BienenPlan Flutter Frontend

BienenPlan ist eine plattformübergreifende Flutter-Anwendung zur gemeinsamen
Planung und Verwaltung von Projekten, Containern und Aufgaben. Die Daten werden
über eine REST-API aus dem BienenPlan-Backend geladen und verwaltet.

Frontend-Repository: <https://github.com/Ahmadizaldeen/bienenplan_frontend>

## Aktueller Stand

- Startscreen mit Navigation zu Anmeldung und Registrierung
- Login mit E-Mail und Passwort sowie JWT-Sitzung in `flutter_secure_storage`
- Automatischer Login beim App-Start, Abmelden und Löschen der lokalen Sitzung
- Prüfung der Backend-Erreichbarkeit direkt vom Startscreen
- Home-Ansicht mit Sidebar, Projektübersicht und zentralem Pull-to-Refresh
- Automatische Aktualisierung über den Änderungs-Feed des Backends:
  Polling alle 5 Sekunden, stilles Neuladen bei Änderungen und sichtbare
  Fehlerhinweise mit Wiederholungsmöglichkeit
- Projekte über die REST-API laden, erstellen und auswählen
- Projektaktionen verwenden die API-Rechte `can_edit`, `can_delete` und
  `can_manage_groups`, nicht die Eigentümeranzeige. Admins können dadurch alle
  aktiven Projekte bearbeiten und archivieren.
- Projektgruppen-Auswahl zeigt nur lokale Gruppen dieses Projekts und globale
  Gruppen; persönliche, fremde lokale und nicht zugeordnete Altgruppen fehlen.
- Admin-Bereich in der aufgeklappten Profil-Sidebar: „Projektarchiv“ mit
  archivierten Projektkarten, Datum, schreibgeschützter Ansicht der Container,
  Aufgaben und Unteraufgaben sowie authentifiziertem Anhang-Download.
  Wiederherstellen erfordert eine Bestätigung und aktualisiert die aktive Liste.
  Bearbeiten bleibt im Archiv gesperrt; entfernte Daten/Mitgliedschaften bleiben entfernt.
- Zuletzt ausgewähltes Projekt lokal speichern und beim Laden wiederherstellen
- Aufgaben des ausgewählten Projekts nach Containern gruppiert anzeigen
- Container für ein Projekt erstellen und Aufgaben zu einem Container hinzufügen;
  Container werden nach ID sortiert, neue Container erscheinen rechts
- Ein einheitlicher Aufgaben-Dialog zum Erstellen und Bearbeiten mit einem
  freien Textfeld (Titel und Beschreibung werden automatisch abgeleitet),
  Status (`open`, `in_progress`, `done`) und optionaler Frist
- Aufgabenkarten zeigen den Titel in der ersten Zeile und darunter die
  Beschreibung, ohne den Titel zu wiederholen
- Aufgaben im Bearbeitungsdialog nach einer Bestätigung löschen
- Teilaufgaben-Bereich beim Erstellen und Bearbeiten direkt unter der Frist;
  bei gespeicherten Aufgaben: Checkliste, Lazy Loading, sofortiges Speichern und Soft-Delete
- Standardstatus neuer Aufgaben ist `open`; ein leerer Status wird als „Offen“ angezeigt
- Gruppen einer Aufgabe per Dropdown zuweisen oder entfernen; bei neuen Aufgaben
  wird die Auswahl vorgemerkt und nach dem Erstellen übernommen
- Neue lokale Gruppen in der Projektverwaltung mit Name und Mitgliederauswahl
  anlegen; der Aufgaben-Dialog verwendet nur bereits zugeordnete Projektgruppen
- Persönliche Gruppen werden mit dem Benutzernamen statt „Personal user {id}“ angezeigt
- Mehrere Datei-Anhänge für Aufgaben auswählen, hochladen, in einer Liste anzeigen und authentifiziert herunterladen; nur Uploader oder Projekt-Eigentümer können löschen
- Upload-Dateien vor dem Senden nach Endung, Größe und Binärinhalt prüfen
- Profilbilder sicher hochladen und nach einem App-Neustart wieder anzeigen
- API-Client mit GET, POST, PUT, DELETE und Multipart-Upload
- Light- und Dark-Theme mit wiederverwendbaren Glass-UI-Komponenten
- Responsive Darstellung der Home- und Aufgabenansicht für schmale Smartphone-Displays

## Domänenmodell

```text
Benutzer
  └── Projekt
        └── Container
              └── Aufgaben
                    ├── Gruppen-Zuweisungen
                    ├── Teilaufgaben
                    └── Anhänge
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
│   ├── subtasks/  Teilaufgabenmodell, Repository, Controller und Checkliste
│   ├── sync/      Änderungs-Feed, Repository und ChangePoller
│   ├── user/      Benutzermodelle (inkl. GroupUser), Profilzustand und Profilbild-Upload
│   └── tasks/     Aufgaben-, Container- und Gruppenmodelle, Repositories,
│                  Controller, Container-Ansicht, TaskDialog und CreateGroupDialog
└── main.dart      Einstiegspunkt und Auto-Login-Prüfung
```

## Automatische Aktualisierung

Die Home-Ansicht verwendet `ChangePoller` aus
[`lib/features/sync/application/change_poller.dart`](lib/features/sync/application/change_poller.dart).
Das injizierbare `ChangeRepository` fragt den authentifizierten Endpunkt
`GET /api/changes` ab. Dafür muss das Backend den Änderungs-Feed unterstützen.
Es handelt sich um Polling, nicht um WebSockets oder eine Offline-Synchronisierung.

- Vor dem initialen Laden wird ohne Cursor eine Baseline abgefragt. Weitere
  Abfragen senden den vom Backend gelieferten, opaken `next_cursor` als
  `after`-Parameter unverändert zurück; der Cursor bleibt nur im Speicher.
- Im Normalbetrieb erfolgt die nächste Abfrage nach 5 Sekunden. Entscheidend
  für ein Neuladen ist `refresh_required`, nicht die Auswertung einzelner
  Einträge in `changes`.
- Bei erforderlicher Aktualisierung werden Projekte, Aufgaben, Container und
  das Benutzerprofil still neu geladen. Bisherige Daten bleiben währenddessen
  sichtbar, ohne zusätzlichen Ladeindikator. Manuelles Aktualisieren per Button
  oder Pull-to-Refresh bleibt verfügbar und zeigt weiterhin den Ladezustand.
- Der neue Cursor wird erst nach einem vollständig erfolgreichen Refresh
  übernommen. Nach fehlgeschlagener Baseline oder fehlgeschlagenem initialem
  Laden wird ein erneuter Refresh eingeplant, damit Änderungen nicht verloren gehen.
- Offene Aufgaben-Dialoge behalten ihre Eingaben. Geänderte Berechtigungen oder
  eine nicht mehr sichtbare Aufgabe werden durch einen Hinweis angezeigt;
  die verbindliche Rechteprüfung bleibt beim Backend.
- Bei inaktiver App pausiert das Polling; beim Fortsetzen wird sofort abgefragt.
  Abmelden beendet das Polling, beim Entfernen der Home-Ansicht werden Timer
  und Listener aufgeräumt.
- Fehler erscheinen in der Home-Ansicht mit „Jetzt versuchen“. Automatische
  Wiederholungen verwenden exponentiellen Backoff bis maximal 60 Sekunden;
  Feed-Anfragen haben ein Timeout von 15 Sekunden.
- Ein ungültiger Cursor (`400`) führt zu einer neuen Baseline mit anschließendem
  Refresh. Bei abgelaufener Sitzung (`401`) stoppt das Polling mit dem Hinweis,
  sich erneut anzumelden.

Die Logik und ihre Home-/Dialog-Integration sind durch
[`test/change_poller_test.dart`](test/change_poller_test.dart) und
[`test/home_change_polling_test.dart`](test/home_change_polling_test.dart) abgedeckt:

```bash
flutter test test/change_poller_test.dart test/home_change_polling_test.dart
```

## Aufgaben und Gruppen

`showTaskDialog` in `lib/features/tasks/presentation/task_dialog.dart` ist die
gemeinsame Maske für neue und bestehende Aufgaben (ersetzt die früheren
`task_create_dialog.dart` und `task_detail_dialog.dart`). Beim Bearbeiten
werden Gruppenänderungen sofort über die API übernommen; beim Erstellen werden
sie gesammelt und nach dem Anlegen der Aufgabe zugewiesen.
Bestehende Aufgaben lassen sich aus dem Dialog nach einer Bestätigung löschen.

Mitglieder einer einer Aufgabe zugeordneten Projektgruppe dürfen Datei-Anhänge
hochladen und herunterladen, ohne die Aufgabe selbst bearbeiten zu dürfen.
Uploads und Downloads verwenden eigene Anhang-Endpunkte. Beim Speichern ohne
Änderungen an Aufgabentext, Status oder Frist wird kein Aufgaben-Update gesendet;
das gilt auch für Wiederholungen eines fehlgeschlagenen Anhang-Uploads.

Nach Änderungen an Projektgruppen lädt die Home-Ansicht Projekte, Container und
Aufgaben neu, da sich auch Zugriffsrechte und Aufgabenzuweisungen ändern können.
Fehlgeschlagene Gruppenabfragen werden im Dialog angezeigt und können erneut
geladen werden; sie werden nicht als leere Gruppenliste behandelt.

Projektaktionen unterscheiden einen fehlgeschlagenen Schreibvorgang von einer
erfolgreichen Änderung mit fehlgeschlagener Listenaktualisierung. Im zweiten Fall
schließt der Editor mit einer Warnung und bietet nur das erneute Laden an, damit
die bereits gespeicherte Änderung nicht nochmals gesendet wird. Beim Neuladen
bleibt die zuletzt geladene Projektliste bis zum nächsten erfolgreichen Abruf
erhalten; ein Fehler wird ausdrücklich angezeigt.

### Freitext → Titel und Beschreibung

Der Dialog hat nur ein Textfeld „Aufgabe“. Die reinen Funktionen in
`lib/features/tasks/application/task_text_parser.dart` übernehmen die Aufteilung:

- `parseTaskText`: Text wird getrimmt, `\r\n` zu `\n` normalisiert.
  - Titel = erste Zeile, maximal 85 Zeichen (`taskTitleMaxLength`).
  - Beschreibung = `null`, wenn der Text einzeilig und höchstens 85 Zeichen lang ist;
    sonst der komplette getrimmte Text. Das Frontend sendet dann `''`.
  - Leerer Text ergibt `null`; das Formular zeigt eine Validierungsmeldung.
- `composeTaskText`: baut beim Bearbeiten aus Titel und Beschreibung wieder den
  Freitext zusammen (auch für ältere Aufgaben, deren Beschreibung nicht mit dem
  Titel beginnt).
- `taskDescriptionBody`: entfernt für die Anzeige den am Anfang wiederholten Titel.

Hinweise: Die Länge zählt UTF-16-Einheiten; ein Emoji wird beim Kürzen nicht
halbiert, zusammengesetzte Emojis können aber getrennt werden. 85 Einheiten passen
sicher in `VARCHAR(100)`. Ältere Aufgaben erhalten beim ersten Speichern den Titel
zusätzlich am Anfang der Beschreibung.

Über „Projektgruppen verwalten“ im Projekteditor lässt sich eine neue lokale
Gruppe anlegen. Dafür lädt die App die Benutzer über `GET /api/users` und sendet
`POST /api/projects/{projectId}/groups` mit `name` und `user_ids`. Die Gruppe wird
dabei auch dem Projekt zugeordnet. Globale Gruppen können zusätzlich zugeordnet
werden; die Aufgabenauswahl lädt nur zugeordnete Gruppen über
`GET /api/projects/{projectId}/groups`. Beim Entfernen einer Projektgruppe entfernt
das Backend auch ihre Gruppenzuweisungen zu Aufgaben dieses Projekts.

Bei genau einem ausgewählten Benutzer ist der Gruppenname optional: Ein leerer
Name wird beim Erstellen durch den Benutzernamen ersetzt; ein eingegebener Name
wird beibehalten. Bei mehreren Benutzern ist ein Gruppenname erforderlich.
Auch mit einem Teilnehmer entsteht eine normale lokale Projektgruppe, keine
persönliche Benutzergruppe.

Lokale Gruppen lassen sich im Projektgruppen-Dialog über das Stift-Symbol
bearbeiten: Name und vorausgewählte Mitglieder können vom Projekt-Eigentümer
oder App-Admin geändert werden. Globale Gruppen werden dort nicht bearbeitet.
Die API speichert Name und Mitglieder gemeinsam über
`PUT /api/projects/{projectId}/groups/{groupId}`.

Gruppenlisten liefern `member_count` als Anzahl aktiver Mitglieder. Mitglieder
zugewiesener lokaler Gruppen sowie der Eigentümer einer zugewiesenen
persönlichen Gruppe dürfen Titel, Beschreibung und Frist bearbeiten,
unabhängig von der Mitgliederzahl. Das Backend liefert dafür
`can_edit` und `can_edit_title_deadline`; der Aufgaben-Dialog gibt das normale
mehrzeilige Feld „Aufgabe“ inklusive Beschreibung und die Friststeuerung frei.
Titel und Beschreibung werden wie bisher aus dem Freitext abgeleitet und über
den normalen Aufgaben-Endpunkt gespeichert. `can_manage_groups` erlaubt
zusätzlich lokale und globale, dem Projekt zugeordnete Gruppen zuzuweisen und
zu entfernen. `can_manage_local_groups` bleibt als kompatibles API-Feld erhalten.
Globale Gruppenmitgliedschaft allein erlaubt keine Gruppenzuweisungen.
Unteraufgaben können vollständig verwaltet werden. Task-Löschrechte bleiben
unverändert. Beim Entfernen einer eigenen Zuweisung können Aufgabenrechte und
Zugriff entfallen, sofern keine andere Berechtigungsgrundlage bestehen bleibt.
Der Aufgaben-Dialog enthält eine aufklappbare Übersicht „Deine Rechte“.
Beim Entfernen der eigenen letzten Ein-Personen-Zuweisung erscheint eine
Bestätigung; nach erfolgreichem Entfernen wird die Aufgabenliste aktualisiert
und der Dialog geschlossen, damit keine veralteten Rechte angezeigt werden.
Die API liefert dafür `member_count` und `is_current_user_member` in Projektgruppen.
Die Gruppenbearbeitung zeigt vor dem Speichern einen Hinweis, wenn eine
Mitgliederänderung Aufgabenrechte beeinflusst.
Reine Statusänderungen verwenden weiterhin
ihren eigenen Endpunkt.

Persönliche Gruppen erkennt das Aufgabenmodell an `personal_user_id`
(Fallback: Name „Personal user {id}“) und zeigt `personal_user_name` als
Anzeigenamen an. Gruppenlisten werden nach diesem Anzeigenamen sortiert.

## Teilaufgaben

Das getrennte Feature `lib/features/subtasks/` enthält ein unveränderliches Modell,
ein injizierbares Repository, einen Provider-/ChangeNotifier-Controller und das
Widget `SubtaskSection`. Der Task-Dialog zeigt den Bereich auch beim Erstellen;
ohne gespeicherte Task-ID erscheint ein statischer, nicht aufklappbarer Hinweis:
„Teilaufgaben können nach dem Erstellen der Aufgabe hinzugefügt und bearbeitet
werden.“ Es erfolgen keine Subtask-Anfragen. Aufgabenkarten zeigen keine Teilaufgaben.

Der Bereich startet eingeklappt und lädt bei gespeicherten Aufgaben beim ersten
Öffnen. Reihenfolge: ID.
Projektgruppen-Mitgliedschaft allein macht Aufgaben nicht sichtbar. Mitglieder
sehen Aufgaben nur, wenn eine ihrer Gruppen direkt der Aufgabe zugewiesen ist;
dort können sie Teilaufgaben erstellen und abhaken. Task-Titel von Teilaufgaben
ändern und löschen können sie nur mit den bisherigen aufgabenspezifischen
Rechten. Admin, Projekt-Eigentümer, berechtigte Task-Ersteller und zugewiesene
Ein-Personen-Gruppen können Teilaufgaben hinzufügen; Admin, Projekt-Eigentümer
und Task-Ersteller behalten ihre Löschrechte, berechtigte
Ein-Personen-Zuweisungen dürfen eigene Unteraufgaben löschen. Die API liefert
die jeweiligen Berechtigungen.

Änderungen werden unabhängig von „Speichern“ sofort übernommen; Schließen des
Task-Dialogs nimmt sie nicht zurück. Der Status der Hauptaufgabe bleibt unabhängig.
Bei Fehlern bleiben die bisherigen Daten erhalten und erneutes Laden ist möglich.
Das Backend benötigt zuvor die Subtask-Migration `003_add_subtask_permissions.sql`
(bei einem frischen Schema nicht erforderlich).

Tests: `flutter test test/subtask_feature_test.dart test/task_delete_dialog_test.dart`.

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

## Farben und Themes

Die zwoelf Basisfarben stehen ausschliesslich in `AppPalette` in
[`lib/core/theme/app_theme.dart`](lib/core/theme/app_theme.dart):

| Bereich | Basisfarben |
| --- | --- |
| Hell | `lightBackground`, `lightSurface`, `lightText`, `lightMuted` |
| Dunkel | `darkBackground`, `darkSurface`, `darkText`, `darkMuted` |
| Akzente und Status | `accent`, `accentLight`, `warning`, `danger` |

Der helle Modus verwendet Off-White, der dunkle Modus neutrales Dunkelgrau.
Rahmen, Container, Statusfarben und Animationen werden aus diesen Basisfarben
abgeleitet. Fuer eine neue Farbgestaltung nur diese zwoelf Werte bearbeiten.
Nach Aenderungen an den `const`-Werten einen Hot Restart ausfuehren.

Widgets verwenden `Theme.of(context).colorScheme` statt eigener Farbwerte.
`AppColors` bleibt als Kompatibilitaets-API erhalten; neue Widgets verwenden
die semantischen Rollen wie `surfaceContainer`, `onSurface`, `primary`
und `error`. Die Theme-Tests pruefen Kontraste und verhindern weitere feste
Farben ausserhalb der zentralen Palette.

## Noch offen

- Suche und Kennzahlen der Projektübersicht mit echten Daten verknüpfen
- Kommentare zu Aufgaben unterstützen
- Container bearbeiten oder löschen
- Darstellung der Gruppenberechtigungen, Rollen und Zugriffsrechte weiter ausbauen
- Responsive Darstellung für Web und Desktop weiter verfeinern

## Voraussetzungen

- Flutter SDK mit Dart SDK passend zur SDK-Vorgabe `^3.13.2` in `pubspec.yaml`
- Laufendes BienenPlan-Backend mit Unterstützung für `GET /api/changes`
- Chrome oder ein anderes unterstütztes Flutter-Zielgerät

Flutter installieren: <https://docs.flutter.dev/install/manual>

Die aktuell verwendeten Versionen und Abhängigkeiten stehen in
`pubspec.yaml`. Das Projekt verwendet unter anderem `http`,
`flutter_secure_storage`, `file_picker`, `provider` und `flutter_animate`.

## Installation und Start

```bash
git clone https://github.com/Ahmadizaldeen/bienenplan_frontend.git
cd bienenplan_frontend
flutter pub get
flutter run -d chrome
```

Für einen lokalen Qualitätscheck:

```bash
flutter analyze
flutter test
```

Die Backend-Basis-URL wird in
[`lib/core/api/api_endpoints.dart`](lib/core/api/api_endpoints.dart) zusammengesetzt.
Sie lässt sich beim Starten und beim Release-Build über
`--dart-define=API_SERVER_BASE_URL=...` überschreiben. Die Adresse enthält den
Backend-Pfad, aber kein abschließendes `/api`; diesen Präfix ergänzt die App.
Ohne Build-Parameter gelten die plattformspezifischen Vorgaben aus dieser Datei.
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

## Web-Deployment

Der Workflow
[`.github/workflows/jekyll-gh-pages.yml`](.github/workflows/jekyll-gh-pages.yml)
baut bei einem Push auf `main` oder manueller Ausführung die Flutter-Web-App und
veröffentlicht sie auf GitHub Pages. Die App verwendet den Basispfad
`/bienenplan_frontend/`. Die Backend-Adresse wird im Build-Schritt über
`API_SERVER_BASE_URL` gesetzt und muss für die Zielumgebung erreichbar sein.
Für eine über HTTPS ausgelieferte Web-App muss auch das Backend über HTTPS
erreichbar sein und Anfragen vom Frontend-Origin erlauben.

## Backend

Das zugehörige REST-Backend basiert auf Slim Framework, PHP und MySQL:
<https://github.com/Ahmadizaldeen/BienenPlan>

[![Deploy Flutter Web to GitHub Pages](https://github.com/Ahmadizaldeen/bienenplan_frontend/actions/workflows/jekyll-gh-pages.yml/badge.svg)](https://github.com/Ahmadizaldeen/bienenplan_frontend/actions/workflows/jekyll-gh-pages.yml)
