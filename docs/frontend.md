# Raccorder le frontend

Configurer l’origine de l’API dans le frontend selon son environnement.

| Environnement | Origine API |
| --- | --- |
| Développement local | `http://127.0.0.1:3050` |
| Mini-forum | `https://api.webperfs.webdesignord.fr` |

En local, le frontend peut garder `http://localhost:3000`. Dans le
`.env` du backend, mettre dans `CORS_ORIGINS`
l’origine exacte que le navigateur affiche pour le frontend, port compris,
puis recréer le conteneur API. Sur mini-forum, les origines
`https://webperfs.webdesignord.fr` et `https://www.webperfs.webdesignord.fr`
sont autorisées par défaut. Une requête exécutée côté serveur Next.js ne
passe pas par le contrôle CORS du navigateur.

Appeler `GET /products` depuis le frontend. Gérer une liste vide et un statut
HTTP d’erreur avant d’afficher le catalogue. Pour les champs et les limites,
consulter la [référence API](api.md).

## Corréler RUM et APM

Ajouter ce réglage à l’initialisation existante du Browser SDK. Pour un essai
RUM local, utiliser l’origine locale de l’API dans le prédicat.

```ts
allowedTracingUrls: [
  {
    match: (url) =>
      new URL(url).origin === 'https://api.webperfs.webdesignord.fr',
    propagatorTypes: ['tracecontext'],
  },
],
```

Le SDK transmet `traceparent` et `tracestate` sur les requêtes échantillonnées.
Le backend autorise ces deux en-têtes dans les prérequêtes CORS. Régler
`traceSampleRate` selon la phase de test et générer un appel Fetch ou XHR dans
le navigateur avec la collecte RUM active. Dans RUM Explorer, ouvrir la
ressource `/products`, suivre le lien APM, puis repérer le span SQL.
L’API doit envoyer ses traces à un Agent Datadog joignable.

- [Configurer et vérifier Datadog APM](apm.md)
- [Documentation Datadog RUM et APM](https://docs.datadoghq.com/real_user_monitoring/connect_rum_and_traces/)
