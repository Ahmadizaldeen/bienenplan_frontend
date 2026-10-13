import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum LegalDocument { imprint, privacy }

class LegalInformationScreen extends StatelessWidget {
  const LegalInformationScreen({required this.document, super.key});

  final LegalDocument document;

  bool get _isPrivacy => document == LegalDocument.privacy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sections = _isPrivacy ? _privacySections : _imprintSections;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPrivacy ? 'Datenschutzerklärung' : 'Impressum'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: SelectionArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'BienenPlan Legal Information',
                      style: TextStyle(color: scheme.onTertiaryContainer),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final section in sections) ...[
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      section.body,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

const _imprintSections = [
  _LegalSection(
    'Projekt- und Kontaktangaben (Lernprojekt)',
    'Dies ist ein privates Lern- und Portfolio-Projekt im Rahmen einer Umschulung '
        'und dient ausschließlich Ausbildungs- und Demonstrationszwecken.\n\n'
        'Ahmad Izaldeen\n'
        'Flebbestraße 7\n'
        '21077 Hamburg\n'
        'Deutschland\n\n'
        'E-Mail: aizaldeen.dev@gmail.com',
  ),
  _LegalSection(
    'Hinweis zum kommerziellen Betrieb',
    'Es handelt sich hierbei um kein kommerzielles Angebot und keine geschäftsmäßige '
        'Webseite im Sinne des Digitale-Dienste-Gesetzes (DDG). Es werden keine '
        'kostenpflichtigen Dienste angeboten.',
  ),
];
const _privacySections = [
  _LegalSection(
    '1. Hinweis zum Projektstatus',
    'Diese Webanwendung wird von mir (Ahmad Izaldeen) als privates Lern- '
        'und Testprojekt im Rahmen meiner Umschulung betrieben. Das System dient '
        'ausschließlich dem Erlernen von Softwareentwicklung und Web-Technologien.',
  ),
  _LegalSection(
    '2. Datenverarbeitung & Testumgebung',
    'Da es sich um ein Testsystem handelt, werden Daten (wie Test-Registrierungen '
        'oder Aufgaben-Einträge) ausschließlich zu Entwicklungs- und Testzwecken '
        'verarbeitet. \n\n'
        '• Frontend-Hosting: GitHub Pages (technische Protokollierung von IP-Adressen '
        'durch GitHub im Rahmen des Hosting-Betriebs).\n'
        '• Backend & Datenbank: Das Backend läuft zu Testzwecken lokal (XAMPP/MySQL) '
        'und wird temporär über einen ngrok-Tunnel erreichbar gemacht.\n\n'
        'Es findet keine kommerzielle Auswertung oder Weitergabe von Daten statt.',
  ),
  _LegalSection(
    '3. Fragen zum Projekt',
    'Da es sich um ein privates Ausbildungsprojekt handelt, erreichst du mich '
        'bei Fragen oder Hinweisen direkt per E-Mail unter aizaldeen.dev@gmail.com.',
  ),
];

