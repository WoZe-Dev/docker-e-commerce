# Docker E-Commerce

Application e-commerce microservices avec Docker Compose.

## Services

| Service | Description | Port |
|---------|-------------|------|
| `mongodb` | Base de données MongoDB | 27017 |
| `auth-service` | Authentification JWT | 3001 |
| `product-service` | Gestion des produits | 3000 |
| `order-service` | Gestion des commandes | 3002 |
| `frontend` | Interface utilisateur | 8080 |

---

## Lancer le projet

### Mode développement

```bash
docker compose up --build
```

Accès : http://localhost:8080

### Mode production (avec Docker Secrets)

Créer le fichier de secret JWT avant le premier lancement :

```bash
mkdir secrets
```

```bash
echo "ton mdp secret" > secrets/jwt_secret.txt
```

Puis lancer :

```bash
docker compose -f docker-compose.prod.yml up --build
```

Accès : http://localhost:8080

