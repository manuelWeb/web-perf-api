# Prise en main du backend

Prérequis locaux : Docker avec Compose. Pour lancer les contrôles npm sur
l’hôte, utiliser Node.js 24.

## Démarrer avec Docker

Depuis la racine du dépôt, créer `.env` lors de la première installation.
L’exemple fournit des valeurs de démonstration destinées au poste local.

```bash
cp .env.example .env
docker compose up -d --build --wait
docker compose exec api npm run migrate
docker compose exec -e NODE_ENV=development api npm run seed:dev
curl -fsS http://127.0.0.1:3050/products
```

La migration crée le schéma. Le seed facultatif insère deux produits fictifs et
peut être rejoué sans doublon. L’API écoute sur `127.0.0.1:3050` côté hôte.
Elle rejoint PostgreSQL par le nom `db` sur le réseau Compose. PostgreSQL
n’a aucun port publié.

Compose lit `.env` sur l’hôte et transmet les variables nécessaires aux
conteneurs. Le message `.env not found. Continuing without it.` émis par
les commandes npm dans l’image est attendu dans ce mode.

## Arrêter ou reconstruire

`docker compose down` arrête le projet en conservant le volume. L’option
`--volumes` supprime la base locale. Après un changement de code, relancer
`docker compose up -d --build --wait` puis appliquer les migrations
explicitement.

Si le mot de passe change après l’initialisation du volume, le mettre à jour
dans PostgreSQL avec `\password` dans `psql`, puis dans `.env`, et relancer
`docker compose up -d --wait`. Un changement de variable seul agit uniquement
sur une initialisation neuve.

## Reproduire les contrôles CI

```bash
npm ci
npm run lint
npm run format:check
npm run typecheck
npm run build
npm test
```

`npm test` construit l’image et utilise un projet Compose et un volume
temporaires. Il vérifie le catalogue, les migrations et la persistance.
Le port de test par défaut est 31987. Pour le changer, passer
`SMOKE_TEST_PORT=<port libre>` à la commande.
