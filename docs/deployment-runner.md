# Installer le runner de déploiement du backend

Le job `Validate` tourne sur un runner hébergé par GitHub à l’ouverture,
à la réouverture ou à la mise à jour d’une PR vers `main`. Exiger ce contrôle
dans la protection de `main` pour bloquer le merge tant qu’il ne réussit pas.

Le workflow `Deploy to mini-forum` démarre à chaque push sur `main`, y compris
après le merge d’une PR. Il utilise un runner auto-hébergé pour construire
l’image et lancer Docker sur le serveur.

## 1. Vérifier le compte de déploiement

Sur mini-forum, ouvre une session avec le compte qui exécutera le runner.
Le dépôt API est déjà installé sur le serveur. Vérifie que ce compte peut
lire sa configuration, accéder à Docker et récupérer `main` sur GitHub.

```bash
cd /opt/apps/web-performance-lab/web-perf-api
test -r .env.production
git status --short --branch
git ls-remote --exit-code origin refs/heads/main >/dev/null
docker info --format '{{.ServerVersion}}'
docker compose version
```

Le clone doit être propre. Il peut encore être sur la branche de la première
livraison. Le workflow récupérera `main` et s’y placera au premier lancement.
L’accès à Docker donne des droits étendus sur le serveur. Garde le runner
réservé aux workflows de livraison approuvés.

## 2. Installer et enregistrer le runner

Dans le dépôt GitHub **backend**, ouvre **Settings → Actions → Runners →
New self-hosted runner**. Sélectionne **Linux** et l’architecture du serveur
(`uname -m` indique `x86_64` ou `aarch64`).

Crée un dossier dédié pour cette instance :

```bash
mkdir -p ~/actions-runners/web-perf-api
cd ~/actions-runners/web-perf-api
```

Depuis ce dossier, exécute les commandes de téléchargement, de vérification
et d’extraction affichées par GitHub. Lance ensuite la commande
d’enregistrement fournie par GitHub. Choisis un nom reconnaissable, par
exemple `miniforum-web-perf-api`, et saisis `mini-forum` à l’invite des
labels supplémentaires. Garde le dossier de travail proposé.

Utilise le jeton temporaire dans ta session serveur. Conserve le jeton et les
fichiers d’enregistrement hors du dépôt et des journaux partagés.

Installe et démarre ensuite le service avec le compte vérifié à l’étape 1 :

```bash
sudo ./svc.sh install "$(id -un)"
sudo ./svc.sh start
sudo ./svc.sh status
```

Dans **Settings → Actions → Runners**, vérifie que le nouveau runner est
**Idle** et qu’il porte les labels `self-hosted` et `mini-forum`.

## 3. Configurer l’environnement GitHub

Dans **Settings → Environments**, crée ou ouvre `mini-forum`.
Dans **Deployment branches and tags**, limite les déploiements à la branche
`main` si cette option est disponible pour le dépôt. Le workflow vérifie
également que la branche sélectionnée est `main`.

Sous **Environment variables**, ajoute
`WEB_PERF_API_DEPLOY_DIR` avec la valeur
`/opt/apps/web-performance-lab/web-perf-api`. Le mot de passe PostgreSQL
reste dans le fichier `.env.production` sur le serveur.

## 4. Vérifier la première livraison

Après le merge, ouvre **Actions → Deploy to mini-forum**. Vérifie que
l’exécution correspond au commit arrivé sur `main`, que le runner backend
prend le job et que celui-ci se termine en succès. Pour relancer une livraison
à la demande, utilise **Run workflow** et sélectionne `main`.
Puis teste les routes publiques :

```bash
curl -fsS https://api.webperfs.webdesignord.fr/health
curl -fsS 'https://api.webperfs.webdesignord.fr/products?limit=2'
```

Si le job reste en attente, vérifie le statut du service, le label
`mini-forum` et l’enregistrement auprès du dépôt backend. S’il démarre
mais échoue avant le build, vérifie la variable de l’environnement GitHub,
l’accès Git sous le compte du runner et l’état du clone. Si `main` a
avancé depuis le lancement, relance le workflow depuis la nouvelle
révision approuvée.

Pour les migrations, sauvegardes et restaurations, consulte le
[guide d’exploitation](operations.md).

- [Ajouter un runner auto-hébergé](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners)
- [Configurer un runner comme service](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/configure-the-application-as-a-service)
