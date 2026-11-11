# Référence API

Les routes renvoient du JSON. L’origine locale est `http://127.0.0.1:3050`.
L’origine prévue sur mini-forum est `https://api.webperfs.webdesignord.fr`.

| Requête | Réponse |
| --- | --- |
| `GET /health` | `200` avec `{"status":"ok"}`. Vérifie que le processus HTTP répond. |
| `GET /products?limit=20` | `200` avec un tableau trié par identifiant. `limit` vaut 20 par défaut et accepte les entiers de 1 à 100. |
| `GET /products/:id` | `200` avec la fiche. L’identifiant est un entier de 1 à 2 147 483 647. |
| `GET /apm-demo/slow` | `200` après environ 300 ms lorsque les routes de démo sont activées. |
| `GET /apm-demo/error` | `500` contrôlé lorsque les routes de démo sont activées. |

Une entrée invalide renvoie `400`. Un produit absent renvoie `404`. Un
catalogue vide renvoie `200` avec `[]`.

```json
{
  "id": 1,
  "sku": "demo-notebook",
  "name": "Carnet démo",
  "price_cents": 690
}
```

`price_cents` est un entier en centimes. La table `users` est réservée à une
évolution ultérieure et n’a aucune route publique.

Avant d’introduire des comptes, définir les règles d’accès et les données
personnelles réellement nécessaires. Prévoir le hachage des mots de passe
avec Argon2id, des sessions à durée limitée et révocables, des contrôles
d’autorisation côté serveur, une limite sur les tentatives et des tests
d’accès entre utilisateurs. Exclure mots de passe, jetons et données
personnelles des logs et des traces.
