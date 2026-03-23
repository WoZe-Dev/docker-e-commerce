# Docker E-Commerce — Application Microservices

Application e-commerce basee sur une architecture microservices, conteneurisee avec Docker et orchestree via Docker Compose.

---

## Architecture

```
                    ┌──────────────┐
                    │   Frontend   │ :8080 (expose)
                    │  Vue.js SPA  │
                    │ Nginx proxy  │
                    └──────┬───────┘
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
      ┌────────────┐ ┌──────────┐ ┌───────────┐
      │auth-service│ │product-  │ │order-     │
      │   :3001    │ │service   │ │service    │
      │            │ │  :3000   │ │  :3002    │
      └─────┬──────┘ └────┬─────┘ └─────┬─────┘
            │              │             │
            └──────────────┼─────────────┘
                           ▼
                    ┌─────────────┐
                    │   MongoDB   │ :27017
                    │  (mongo:7)  │
                    └─────────────┘
```

| Service | Description | Port | Healthcheck |
|---------|-------------|------|-------------|
| `mongodb` | Base de donnees NoSQL | 27017 | `mongosh ping` |
| `auth-service` | Authentification et gestion JWT | 3001 | `/api/health` |
| `product-service` | Catalogue de produits et panier | 3000 | `/api/health` |
| `order-service` | Gestion des commandes | 3002 | `/api/health` |
| `frontend` | Vue.js SPA servie par Nginx (prod) / Express (dev) | 8080 | `wget localhost` |
| `product-init` | Conteneur d'initialisation des donnees | — | — |

---

## Prerequis

- **Docker** >= 20.10
- **Docker Compose** >= 2.0 (plugin `docker compose`)
- **Git**

---

## Demarrage rapide

### Mode developpement

```bash
docker compose up --build
```

Acces : [http://localhost:8080](http://localhost:8080)

**Caracteristiques du mode dev :**
- Build target `development` pour tous les services
- `NODE_ENV=development` sur tous les services
- Frontend servi par Express (`server.cjs`) avec proxy API
- Volumes montes pour le hot-reload (`./services/*/src` -> `/app/src`)
- Ports de tous les services exposes sur l'hote (3000, 3001, 3002, 8080, 27017)
- MongoDB accessible directement depuis l'hote pour le debogage

### Mode production (avec Docker Secrets)

**1. Creer les fichiers de secrets :**

```bash
mkdir -p secrets
echo "votre_secret_jwt" > secrets/jwt_secret.txt
echo "admin" > secrets/mongo_user.txt
echo "votre_mot_de_passe_mongo" > secrets/mongo_password.txt
```

**2. Lancer :**

```bash
docker compose -f docker-compose.prod.yml up --build -d
```

Acces : [http://localhost:8080](http://localhost:8080)

**Caracteristiques du mode prod :**
- Build target `production` pour tous les services
- `NODE_ENV=production` sur tous les services
- Frontend servi par **Nginx** (serveur web leger, ~7 Mo) avec reverse proxy
- Secrets Docker pour JWT et MongoDB (montes via `/run/secrets/`)
- Authentification MongoDB activee
- Seul le port 8080 (frontend) est expose sur l'hote
- Limites de ressources CPU/memoire par service
- Rotation des logs configuree (10 Mo max, 3 fichiers)
- Aucun volume de developpement monte
- Images optimisees via builds multi-stage

---

## Configuration par environnement

| Aspect | Developpement (`docker-compose.yml`) | Production (`docker-compose.prod.yml`) |
|--------|--------------------------------------|----------------------------------------|
| Build target | `development` | `production` |
| `NODE_ENV` | `development` | `production` |
| Frontend | Express + proxy (`server.cjs`) | **Nginx** + reverse proxy |
| Secrets | Variables d'environnement en clair | Docker Secrets (`/run/secrets/`) |
| Ports exposes | Tous (3000, 3001, 3002, 8080, 27017) | Frontend uniquement (8080) |
| MongoDB auth | Desactivee | Activee (via secrets) |
| Volumes | Montage source pour hot-reload | Aucun (code copie dans l'image) |
| Ressources | Pas de limites | CPU et memoire limites |
| Logs | Par defaut | Rotation json-file (10m x 3) |

---

## Tester les services

### Verifier que tous les services sont en bonne sante

```bash
docker compose ps
```

### Tester les endpoints de sante

```bash
# Auth service
curl http://localhost:3001/api/health

# Product service
curl http://localhost:3000/api/health

# Order service
curl http://localhost:3002/api/health

# Frontend
curl http://localhost:8080
```

### Lancer les tests unitaires

```bash
./scripts/run-tests.sh
```

### Scanner les images Docker avec Trivy

```bash
# Installer Trivy (si non installe)
# macOS: brew install trivy
# Debian: sudo apt-get install trivy

# Scanner chaque image apres build
docker compose -f docker-compose.prod.yml build

trivy image docker-e-commerce-auth-service
trivy image docker-e-commerce-product-service
trivy image docker-e-commerce-order-service
trivy image docker-e-commerce-frontend

# Scanner avec un seuil de severite
trivy image --severity HIGH,CRITICAL docker-e-commerce-auth-service
```

---

## Registry privee

Pour pousser les images vers une registry privee (ex: GitLab Container Registry) :

```bash
# Se connecter a la registry
docker login registry.gitlab.com

# Tagger les images
docker tag docker-e-commerce-auth-service registry.gitlab.com/<groupe>/<projet>/auth-service:latest
docker tag docker-e-commerce-product-service registry.gitlab.com/<groupe>/<projet>/product-service:latest
docker tag docker-e-commerce-order-service registry.gitlab.com/<groupe>/<projet>/order-service:latest
docker tag docker-e-commerce-frontend registry.gitlab.com/<groupe>/<projet>/frontend:latest

# Pousser les images
docker push registry.gitlab.com/<groupe>/<projet>/auth-service:latest
docker push registry.gitlab.com/<groupe>/<projet>/product-service:latest
docker push registry.gitlab.com/<groupe>/<projet>/order-service:latest
docker push registry.gitlab.com/<groupe>/<projet>/frontend:latest
```

---

## Structure du projet

```
docker-e-commerce/
├── docker-compose.yml              # Compose developpement (target: development)
├── docker-compose.prod.yml         # Compose production (target: production)
├── .env                            # Variables d'environnement
├── .gitignore
├── frontend/
│   ├── Dockerfile                  # Multi-stage : build -> dev (Express) | prod (Nginx)
│   ├── nginx.conf                  # Configuration Nginx (reverse proxy + static)
│   ├── .dockerignore
│   ├── server.cjs                  # Serveur Express + proxy API (dev uniquement)
│   ├── src/                        # Code source Vue.js
│   └── package.json
├── services/
│   ├── auth-service/
│   │   ├── Dockerfile              # Multi-stage : deps -> dev | prod (non-root)
│   │   ├── .dockerignore
│   │   ├── docker-entrypoint.sh    # Lecture des Docker Secrets
│   │   ├── src/
│   │   └── package.json
│   ├── product-service/
│   │   ├── Dockerfile
│   │   ├── .dockerignore
│   │   ├── docker-entrypoint.sh
│   │   ├── src/
│   │   └── package.json
│   └── order-service/
│       ├── Dockerfile
│       ├── .dockerignore
│       ├── docker-entrypoint.sh
│       ├── src/
│       └── package.json
├── scripts/
│   ├── init-products.sh            # Seed des produits
│   ├── run-tests.sh                # Suite de tests
│   ├── setup.sh                    # Setup bare-metal (legacy)
│   └── deploy.sh                   # Deploiement PM2 (legacy)
└── secrets/                        # (non versionne) Fichiers de secrets
    ├── jwt_secret.txt
    ├── mongo_user.txt
    └── mongo_password.txt
```

---

## Bonnes pratiques Docker appliquees

### 1. Builds multi-stage avec targets dev/prod

Chaque Dockerfile contient plusieurs stages : `development` et `production`. Le Docker Compose selectionne le target adapte a l'environnement via `build.target`. Cela permet d'utiliser un seul Dockerfile pour les deux environnements.

### 2. Nginx pour la production

En production, le frontend est servi par **Nginx** (`nginx:stable-alpine`, ~7 Mo) au lieu de Node.js (~130 Mo). Nginx sert les fichiers statiques et agit comme reverse proxy vers les microservices backend. En developpement, Express (`server.cjs`) est utilise pour permettre le hot-reload.

### 3. Images Alpine

Toutes les images sont basees sur `node:20-alpine` (backend) et `nginx:stable-alpine` (frontend prod), reduisant significativement la taille et la surface d'attaque.

### 4. Fichiers `.dockerignore`

Chaque service dispose d'un `.dockerignore` excluant `node_modules`, fichiers de test, `.git`, `.env`, etc. Cela accelere le build et empeche les fuites de fichiers sensibles.

### 5. Nettoyage du cache npm

Tous les Dockerfiles executent `npm cache clean --force` apres l'installation des dependances pour supprimer les fichiers temporaires inutiles et reduire la taille de l'image.

### 6. Utilisateur non-root

En production, tous les conteneurs backend s'executent avec un utilisateur dedie (`appuser`) au lieu de `root`, limitant l'impact d'une eventuelle compromission.

### 7. Docker Secrets

En production, les donnees sensibles (JWT, identifiants MongoDB) sont gerees via Docker Secrets plutot que des variables d'environnement en clair. Un script `docker-entrypoint.sh` dans chaque service lit les fichiers secrets au demarrage.

### 8. Healthchecks

Tous les services definissent des healthchecks permettant a Docker de surveiller leur etat et de gerer correctement l'ordre de demarrage via `depends_on: condition: service_healthy`.

### 9. Separation dev/prod

Deux fichiers Docker Compose distincts avec des configurations adaptees : volumes et ports ouverts en dev, secrets et limites de ressources en prod. Les Dockerfiles utilisent des `target` differents.

### 10. Limites de ressources

En production, chaque conteneur est limite en CPU et memoire pour eviter qu'un service defaillant ne consomme toutes les ressources de l'hote.

### 11. Rotation des logs

La configuration de logging `json-file` avec `max-size` et `max-file` previent la saturation du disque en production.

### 12. Reseau isole

Tous les services communiquent via un reseau Docker Bridge dedie (`app-network`), isole du reseau de l'hote.

---

## Scans de securite (Trivy)

Trivy est utilise pour scanner les images Docker a la recherche de vulnerabilites connues :

```bash
# Scanner toutes les images du projet
for img in auth-service product-service order-service frontend; do
  echo "=== Scanning $img ==="
  trivy image --severity HIGH,CRITICAL "docker-e-commerce-$img"
done
```

Les resultats permettent d'identifier les CVE presentes dans les images de base et les dependances, et de prendre des mesures correctives (mise a jour des images, patch des dependances).

---

## Commandes utiles

```bash
# Construire sans cache
docker compose build --no-cache

# Voir les logs d'un service
docker compose logs -f auth-service

# Arreter et supprimer tout (volumes inclus)
docker compose down -v

# Generer le fichier de logs des commits
git log --pretty=format:"%h %ad | %s%d [%an]" --date=short > logs_projet.txt

# Inspecter la taille des images
docker images | grep docker-e-commerce
```

---

## Auteurs

Projet realise dans le cadre du cours **Docker Avance et Infrastructure** — Master 1 (4IW2).
