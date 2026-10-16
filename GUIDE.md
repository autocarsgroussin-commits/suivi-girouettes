# Suivi des girouettes : mise en place

Ce dossier contient une petite application web à héberger vous-même. Les données sont enregistrées dans une base Supabase qui vous appartient, et l'application s'ouvre par une adresse, sur téléphone comme sur ordinateur. Ce qui est saisi sur un appareil apparaît sur les autres en quelques secondes.

Comptez 20 à 30 minutes pour la première mise en place. Deux comptes gratuits sont nécessaires : Supabase (la base de données) et Netlify (l'hébergement de la page).

> **Déjà fait pour vous :** le projet Supabase « suivi-girouettes » a été créé (région Paris, offre gratuite), la table `cars` et ses règles de sécurité sont en place, et `config.js` est déjà rempli. **Passez directement à l'étape 3**, puis aux étapes 5 à 7. Les étapes 1, 2 et 4 restent décrites ci-dessous pour mémoire.

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `index.html` | L'application |
| `config.js` | Adresse et clé de votre projet Supabase, **à compléter** |
| `schema.sql` | Création de la table et des règles de sécurité, à coller dans Supabase |
| `sw.js`, `manifest.webmanifest`, icônes | Installation sur l'écran d'accueil et ouverture sans réseau |
| `vendor/supabase.js` | Bibliothèque de connexion à Supabase, incluse pour ne dépendre d'aucun service tiers |

## Étape 1 : créer le projet Supabase

1. Créez un compte sur supabase.com, **avec l'adresse e-mail que vous utiliserez pour vous connecter à l'application** (voir l'encadré de l'étape 3).
2. Créez un nouveau projet. Choisissez une région en Europe (Paris si elle est proposée) et notez le mot de passe de la base dans un endroit sûr.
3. Attendez que le projet soit prêt (une à deux minutes).

## Étape 2 : créer la table

1. Dans le menu de gauche, ouvrez **SQL Editor**.
2. Collez tout le contenu de `schema.sql`, puis cliquez sur **Run**.
3. Le message « Success » doit s'afficher. Dans **Table Editor**, une table `cars` est apparue.

Ce script crée la table, active les règles de sécurité (chaque compte ne voit que ses propres données) et active la mise à jour en temps réel.

## Étape 3 : déclarer l'adresse du site

La connexion se fait par **adresse e-mail et mot de passe**. Pour la toute première connexion (ou en cas d'oubli), l'application envoie un **lien** par e-mail ; ce lien doit ramener vers votre site.

1. Ouvrez **Authentication > URL Configuration**.
2. **Site URL** : `https://suivi-girouettes.netlify.app`, puis enregistrez.
3. **Redirect URLs** : ajoutez `https://suivi-girouettes.netlify.app/**`.

Aucun serveur d'envoi (SMTP) n'est nécessaire : le service d'e-mail intégré de Supabase suffit, car il ne sert qu'à envoyer ce lien de temps en temps. Il n'envoie qu'aux adresses des membres de votre compte Supabase, et seulement quelques messages par heure.

## Étape 4 : renseigner config.js

1. Dans Supabase, ouvrez **Project Settings**, puis **API Keys** et **Data API**.
2. Copiez l'**URL du projet** (de la forme `https://xxxx.supabase.co`).
3. Copiez la **clé publishable** (commence par `sb_publishable_`). Si seule une clé `anon public` est proposée, elle convient aussi.
4. Ouvrez `config.js` avec un éditeur de texte (Bloc-notes suffit) et remplacez les deux valeurs :

```js
window.GIROUETTES_CONFIG = {
  supabaseUrl: "https://xxxx.supabase.co",
  supabaseKey: "sb_publishable_xxxxxxxx"
};
```

> **Ne mettez jamais la clé `secret` ou `service_role`** dans ce fichier : elle donne tous les droits sur la base et serait visible de tous. La clé publishable, elle, peut être publique : la sécurité repose sur les règles créées à l'étape 2.

## Étape 5 : mettre l'application en ligne (Netlify)

1. Créez un compte gratuit sur netlify.com.
2. Ajoutez un nouveau site en choisissant le **déploiement manuel** (glisser-déposer).
3. Glissez **le dossier entier** `girouettes-app` (celui qui contient `index.html`) dans la zone de dépôt.
4. Netlify vous donne une adresse du type `https://nom-au-hasard.netlify.app`. Vous pouvez la personnaliser dans les réglages du site (par exemple `girouettes-xxx.netlify.app`).

Ouvrez cette adresse : l'écran de connexion s'affiche. S'il indique « Configuration à terminer », revoyez l'étape 4.

*Autre possibilité :* GitHub Pages ou Cloudflare Pages fonctionnent aussi. Sur GitHub Pages en offre gratuite, le dépôt doit être public : le code serait visible, mais pas vos données.

## Étape 6 : première connexion et mot de passe

1. Sur l'adresse du site, saisissez votre e-mail, puis « Recevoir un lien de connexion par e-mail ».
2. Ouvrez le lien reçu (vérifiez les courriers indésirables). L'application s'ouvre et vous propose de **définir votre mot de passe** : faites-le.
3. Sur vos autres appareils, connectez-vous simplement avec e-mail et mot de passe. L'icône en forme de clé, en haut de l'application, permet de le changer.
4. Dans Supabase, **Authentication > Sign In / Providers** : désactivez **« Allow new users to sign up »**, pour que personne d'autre ne puisse créer de compte.

## Étape 7 : installer sur le téléphone et l'ordinateur

- **iPhone (Safari)** : ouvrez l'adresse, bouton Partager, puis « Sur l'écran d'accueil ».
- **Android (Chrome)** : ouvrez l'adresse, menu ⋮, puis « Installer l'application » ou « Ajouter à l'écran d'accueil ».
- **Ordinateur (Chrome ou Edge)** : icône d'installation dans la barre d'adresse, ou simple favori.

Connectez-vous une fois sur chaque appareil. La session est conservée ensuite.

## Ajouter un collègue

Le parc est commun : tous les membres de l'équipe voient et modifient les mêmes cars. Chaque modification garde le nom de son auteur.

1. Dans l'application, icône **Équipe** (visible par les administrateurs) : saisissez l'e-mail et le prénom du collègue, choisissez son rôle, puis **Ajouter**.
2. Dans Supabase, **Authentication > Users > Add user > Create new user** : même e-mail, un mot de passe provisoire, et cochez **Auto Confirm User**. Aucun e-mail n'est envoyé.
3. Transmettez-lui l'adresse du site et ce mot de passe provisoire ; il le change ensuite avec l'icône clé.

Pour retirer l'accès à quelqu'un, icône **Équipe**, puis **Retirer l'accès** : c'est immédiat. Un compte créé sans figurer dans l'équipe voit seulement le message « Accès non autorisé ».

## Alertes e-mail aux administrateurs

À chaque nouvelle panne déclarée, les administrateurs actifs reçoivent un e-mail (sauf celui qui l'a déclarée lui-même). Les e-mails partent par Brevo.

1. Créez un compte gratuit sur brevo.com.
2. Déclarez l'adresse d'expédition (menu Expéditeurs) et validez-la avec le code reçu.
3. Créez une clé API (menu SMTP & API > Clés API) et copiez-la.
4. Dans Supabase, **SQL Editor**, exécutez : `select vault.create_secret('VOTRE-CLE', 'brevo_api_key');`
5. Si l'adresse d'expédition n'est pas celle du premier administrateur, exécutez aussi : `select vault.create_secret('expediteur@domaine.fr', 'brevo_sender');`

Pour couper les alertes : `delete from vault.secrets where name = 'brevo_api_key';`

## Conducteurs

Les conducteurs ont un écran simplifié, pensé pour le téléphone : choisir le car, toucher le problème constaté (« Girouette éteinte », « Mauvaise destination »…), choisir la gravité, envoyer. Ils voient l'historique de leurs signalements, avec « Réparé » dès que la panne est marquée résolue. Ils n'ont accès à rien d'autre.

Chaque signalement devient automatiquement une panne dans la fiche du car (étiquette « Signalement conducteur »), et les administrateurs reçoivent l'e-mail d'alerte. Une plaque inconnue crée le car. Sans réseau, le signalement reste sur le téléphone et part tout seul au retour du réseau.

Ajouter un conducteur :
1. Icône **Équipe** : e-mail, prénom, rôle **Conducteur**, car habituel (pré-rempli dans son formulaire).
2. Il ouvre l'adresse du site, choisit « Créer un compte » avec cette même adresse, puis confirme son e-mail. Les adresses personnelles (Gmail…) sont acceptées dès qu'elles ont été ajoutées dans l'Équipe.

Important : ajoutez le conducteur dans l'Équipe **avant** qu'il crée son compte. Une adresse @autocars-groussin.com inscrite sans avoir été ajoutée devient « Membre » (accès complet) ; changez alors son rôle.

## Au quotidien

- **Synchronisation** : l'indicateur en haut affiche « Synchronisé », « Enregistrement… », « Hors ligne » ou « Erreur de synchro ». Hors ligne, vos modifications sont gardées sur l'appareil et envoyées automatiquement au retour du réseau. En cas d'erreur, touchez l'indicateur pour réessayer.
- **Déconnexion** : si des modifications ne sont pas encore envoyées, l'application vous prévient avant qu'elles soient perdues.
- **Export** : le bouton d'export télécharge un fichier CSV des pannes, lisible dans Excel.
- **Sauvegarde complète** : l'offre gratuite de Supabase ne propose pas de sauvegarde automatique téléchargeable. Exportez régulièrement la table depuis **Table Editor > cars > Export to CSV** (elle contient tout : pannes, tâches, demandes SAV, notes).
- **Mise en pause** : un projet Supabase gratuit sans activité pendant 7 jours est mis en pause. Avec un usage régulier, cela n'arrive pas. Sinon, réactivez-le depuis le tableau de bord Supabase ; aucune donnée n'est perdue.

## Mettre à jour l'application

Pour publier une nouvelle version, dans Netlify, ouvrez l'onglet des déploiements du site et glissez à nouveau le dossier complet (avec votre `config.js` rempli). La nouvelle version est prise en compte à la réouverture de l'application. Les données, elles, restent dans Supabase et ne sont pas touchées.

## Dépannage

| Symptôme | Cause probable |
|---|---|
| « Configuration à terminer » | `config.js` non rempli, ou mauvais fichier envoyé sur Netlify |
| Aucun code reçu | Courriers indésirables ; adresse différente de celle du compte Supabase ; limite d'envois atteinte (attendez une heure) |
| « Adresse non autorisée » | Les inscriptions sont fermées et cette adresse n'a pas de compte |
| « Code incorrect ou expiré » | Utilisez le dernier code reçu, ou demandez-en un nouveau |
| Le code reçu est un lien et non des chiffres | Étape 3 non faite, ou seul un des deux modèles a été modifié |
| « Erreur de synchro » persistante | Projet Supabase en pause, ou script de l'étape 2 non exécuté |
| Les modifications n'apparaissent pas sur l'autre appareil | Rouvrez l'application : elle se resynchronise à chaque ouverture |
