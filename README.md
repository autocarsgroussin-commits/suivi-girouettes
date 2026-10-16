# Suivi des girouettes

Application web (PWA) de suivi des pannes de girouettes des cars d'Autocars Groussin.

- **Bureau (admin / membre)** : parc des cars, pannes, tâches, demandes SAV, notes, journal des signalements, gestion de l'équipe, export CSV.
- **Conducteurs** : écran de signalement simplifié (n° du car, cause, gravité, précisions), historique et annulation de leurs signalements, envoi différé hors réseau.
- **Alertes** : e-mail aux administrateurs à chaque nouveau signalement ou annulation (Brevo).

En ligne : https://suivi-girouettes.netlify.app

## Structure

| Chemin | Rôle |
|---|---|
| `index.html` | Application complète (HTML, CSS, JS sans dépendance de build) |
| `config.js` | URL du projet Supabase et clé publique (`sb_publishable_…`) |
| `sw.js`, `manifest.webmanifest`, `icon*` | Installation sur téléphone et cache hors ligne |
| `vendor/supabase.js` | supabase-js embarqué |
| `netlify.toml` | Publication Netlify (aucune étape de build) |
| `supabase/schema.sql` | Tables, règles d'accès (RLS), déclencheurs et fonctions |
| `emails/` | Modèles d'e-mail Supabase en français |
| `GUIDE.md` | Guide de mise en place et d'administration |

## Sécurité

`config.js` ne contient que la clé **publique** : la sécurité repose sur les règles RLS de la base.
Ne jamais ajouter au dépôt la clé `service_role`/`secret` de Supabase ni les clés Brevo (elles sont dans le coffre Supabase Vault).

## Publier

Netlify publie le dossier racine tel quel (`publish = "."`). Relier ce dépôt au site Netlify `suivi-girouettes` permet une publication automatique à chaque push.
