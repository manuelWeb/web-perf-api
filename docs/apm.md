# Traces Datadog

L’API charge `dd-trace/init` avant NestJS, Express et le pilote `pg`.
`DD_SERVICE`, `DD_ENV` et `DD_VERSION` identifient le service, son
environnement et la version livrée. En production, utiliser le SHA déployé
pour `DD_VERSION`.

Pour tester en local, préparer un Datadog Agent avec APM activé et rendre son
récepteur accessible depuis le conteneur API. Sur Docker Desktop,
`http://host.docker.internal:8126` cible l’Agent de l’hôte. Limiter l’accès
au récepteur aux clients de confiance. Configurer la clé API et le site
Datadog EU sur l’Agent uniquement. Dans le fichier local `.env`, renseigner
`DD_TRACE_AGENT_URL` et mettre `DD_TRACE_ENABLED=true`, puis recréer l’API
avec `docker compose up -d --build --wait`.

| Requête | Trace attendue |
| --- | --- |
| `GET /health` | Réponse rapide, sans requête SQL |
| `GET /apm-demo/slow` | Réponse après environ 300 ms |
| `GET /apm-demo/error` | Réponse HTTP 500 contrôlée |
| `GET /products` | Requête HTTP avec un span PostgreSQL enfant, après migration |

Les routes `/apm-demo/*` sont inscrites uniquement si
`APM_DEMO_ENABLED=true`. Laisser ce réglage désactivé en production.

Dans **APM → Trace Explorer**, sélectionner une fenêtre récente et filtrer
avec `service:web-perf-api env:development`. Ouvrir une trace de
`GET /products` et chercher l’opération `pg.query` dans le graphe de la
trace. Utiliser Live Search pendant les essais pour voir les traces reçues
sans attendre leur indexation. Si aucune trace ne remonte, vérifier que
l’API peut joindre le récepteur APM et que l’Agent envoie au bon site.

## Corrélation depuis le navigateur

Lors d’une prochaine phase, ajouter ce réglage à la configuration existante
du Browser SDK et définir un `traceSampleRate` adapté à la phase de test.

```ts
allowedTracingUrls: [
  {
    match: (url) =>
      new URL(url).origin === 'https://api.webperfs.webdesignord.fr',
    propagatorTypes: ['tracecontext'],
  },
],
```

Le SDK utilisera les en-têtes W3C `traceparent` et `tracestate`.
L’API les autorise sur les prérequêtes CORS. Pour le déploiement, renseigner
`CORS_ORIGINS=https://webperfs.webdesignord.fr,https://www.webperfs.webdesignord.fr`.
Pour un essai depuis le frontend local, renseigner son origine exacte,
port compris. Dans RUM Explorer, ouvrir une ressource Fetch ou XHR
échantillonnée et suivre le lien vers sa trace APM.

- [Instrumentation Node.js](https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/nodejs/)
- [Corrélation RUM et APM](https://docs.datadoghq.com/real_user_monitoring/connect_rum_and_traces/)
