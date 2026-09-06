# 🌱 Bienen Plan Flutter UI 

Eine plattformübergreifende Projekt-Management-Anwendung für das Verwatung von Aufgaben in Übergeordente Contienern.
Benutzerverwaltung und authenirern und für Team mit gruppierung von Benutzen.

Programm Hierarchie:

User
 │
 ├── Groups
 │
 └── Projects
       │
       └── Containers
             │
             └── Tasks
                   │
                   └── Subtasks

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
├───lib
    ├───core
    │   ├───api
    │   └───constants
    └───features
        ├───auth
        │   ├───data
        │   └───presentation
        └───tasks
            ├───data
            └───presentation

# Backend (REST-API , Slim - PHP)
https://github.com/Ahmadizaldeen/BienenPlan.git