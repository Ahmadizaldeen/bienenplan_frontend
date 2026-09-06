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




# Sicherheit :
- JWT in flutter_secure_storage gespeichet (nutzt auf Android den Keystore und auf iOS die Keychain)
- API-Requests senden das Token als Authorization: Bearer <token>-Header
- Bei einer 401-Antwort wird das Token automatisch gelöscht und der Nutzer muss sich neu anmelden

# 🚧 Projektstatus
Feature         	                Status
Login / Authentifizierung (JWT)	    ✅ Fertig
Aufgabenübersicht (Liste laden)	    ✅ Fertig
Aufgabe erstellen (Frontend)	    ⏳ Offen
Status ändern (Task-UI-Button)	    ⏳ Offen
Projekte / Container-Ansicht	    ⏳ Offen
Getestet auf	                    Chrome (Web)

🔗 Backend
REST-API (Slim Framework, PHP, MySQL): https://github.com/Ahmadizaldeen/BienenPlan.git