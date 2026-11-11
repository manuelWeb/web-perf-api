# Exploiter l’API sur mini-forum

## Préparer la première installation

Cloner le dépôt sur mini-forum sous le compte qui exécute le runner. Le
frontend utilise `/opt/apps/web-perf-lab`. Le dossier proposé pour l’API
est `/opt/apps/web-perf-api`. Le compte du runner doit pouvoir mettre à
jour ce dépôt, lire `.env.production` et utiliser Docker. Limiter l’accès
à ce compte, car l’accès au démon Docker donne des droits étendus sur l’hôte.

Depuis le dossier de l’API, sur une première installation :

```bash
umask 077
cp .env.production.example .env.production
chmod 600 .env.production
docker volume create web-perf-api-production-postgres
```

Dans `.env.production`, renseigner un mot de passe unique et conserver
`API_HOST_PORT=3050`, le port validé sur mini-forum. PostgreSQL utilise un volume Docker externe.
Le conteneur initialise lui-même les permissions du volume à la première
utilisation. Garder le même nom de volume entre les livraisons et conserver
l’accès à ce volume sur l’hôte. Compose ne supprime pas un volume externe,
même lors d’un `down --volumes`.

`DD_TRACE_ENABLED` peut rester à `false` tant que l’Agent n’est pas prêt.
Pour l’activer, renseigner l’URL du récepteur joignable depuis le conteneur.
Configurer la clé Datadog sur l’Agent uniquement.

## Installer le routage HTTPS

Le [modèle Nginx](../deploy/nginx/api.webperfs.webdesignord.fr.conf.template)
reprend la structure du frontend. Le proxy utilise `127.0.0.1:3050`,
comme `API_HOST_PORT`. Renseigner les deux chemins TLS. Le certificat
doit couvrir `api.webperfs.webdesignord.fr`. Si aucun certificat ne le
couvre encore, obtenir le certificat via Certbot selon la méthode de
validation retenue pour mini-forum avant d’installer le bloc HTTPS.

Installer la configuration rendue sous
`/etc/nginx/conf.d/api.webperfs.webdesignord.fr.conf`, vérifier avec
`sudo nginx -t`, puis recharger avec `sudo systemctl reload nginx`.
Une fois l’API démarrée, vérifier la redirection HTTP et les routes
HTTPS `/health` et `/products`. Nginx joint l’API via la boucle locale.
PostgreSQL est isolé sur un réseau Docker interne.

## Livrer une mise à jour

Configurer le runner du dépôt API sur mini-forum avec le label
`mini-forum`. Dans l’environnement GitHub `mini-forum`, définir
`WEB_PERF_API_DEPLOY_DIR` sur le dossier du clone et limiter le déploiement
à `main`. Protéger `main` avec une PR et le contrôle `Validate`.
Le workflow de livraison se lance manuellement depuis `main`. Il vérifie
que le SHA demandé est en tête de `main` et que le clone est propre.

Pour une livraison manuelle depuis la révision approuvée :

```bash
export DD_VERSION="$(git rev-parse --short=7 HEAD)"
bash scripts/deploy-production.sh
```

Le script construit l’image, attend PostgreSQL, applique les migrations
via un conteneur ponctuel, puis démarre l’API et vérifie l’accès à
`/products`. Préparer une sauvegarde avant les migrations et rendre les
migrations compatibles avec l’API en service durant la transition. En
cas d’échec, consulter les journaux avant de relancer. Un retour à une
ancienne image nécessite un schéma compatible ou une restauration
planifiée.

## Sauvegarder et restaurer PostgreSQL

Depuis le dossier de l’API sur mini-forum :

```bash
export DD_VERSION="$(git rev-parse --short=7 HEAD)"
dc() { docker compose --env-file .env.production -f compose.production.yaml "$@"; }

umask 077
backup="catalogue-$(date -u +%Y%m%dT%H%M%SZ).dump"
dc exec -T db sh -c 'pg_dump -Fc -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > "$backup"
dc exec -T db pg_restore --list < "$backup" > /dev/null
```

Conserver une copie protégée en dehors du serveur. Tester la restauration
sur une base séparée avant de l’utiliser pour un incident :

```bash
dc exec -T db sh -c 'createdb -U "$POSTGRES_USER" web_perf_restore'
dc exec -T db sh -c 'pg_restore --exit-on-error -U "$POSTGRES_USER" -d web_perf_restore' < "$backup"
dc exec -T db sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d web_perf_restore -c "SELECT count(*) FROM products"'
```

Comparer le résultat avec la sauvegarde attendue. Pour basculer en production
sur la base restaurée, arrêter les écritures, vérifier les données et les
droits, puis reconfigurer l’API avec le nom de la base restaurée et vérifier
`/products`. Le dump contient le schéma et les données de la base, dont
l’historique des migrations. Les rôles et mots de passe PostgreSQL sont
configurés séparément.
