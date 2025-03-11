# ZombieLand Docker

Cette configuration Docker permet de lancer l'ensemble de l'application ZombieLand (frontend et backend) en une seule commande.

## Prérequis

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Git](https://git-scm.com/downloads)

## Installation rapide

Exécutez simplement le script d'installation :

```bash
git clone https://github.com/creach-t/ZombieLand-docker.git
cd ZombieLand-docker
chmod +x setup.sh
./setup.sh
```

## Installation manuelle

1. Clonez ce dépôt et les dépôts de l'application :

```bash
# Cloner le dépôt Docker
git clone https://github.com/creach-t/ZombieLand-docker.git
cd ZombieLand-docker

# Cloner les dépôts de l'application
git clone https://github.com/creach-t/ZombieLand-back.git
git clone https://github.com/creach-t/ZombieLand-front.git
```

2. Lancez les conteneurs avec Docker Compose :

```bash
docker compose up -d
```

## Structure des services

La configuration Docker comprend trois services :

1. **postgres** : Base de données PostgreSQL
   - Port : 5432
   - Utilisateur : zombieland
   - Mot de passe : zombieland
   - Base de données : zombieland

2. **backend** : API Node.js/Express
   - Port : 3000
   - URL : http://localhost:3000

3. **frontend** : Application React/Vite
   - Port : 5173
   - URL : http://localhost:5173

## Personnalisation

Vous pouvez personnaliser les variables d'environnement dans le fichier `docker-compose.yml` pour adapter l'application à vos besoins.

### Variables d'environnement importantes :

#### Backend
- `JWT_SECRET` : Clé secrète pour les tokens JWT
- `SESSION_SECRET` : Clé secrète pour les sessions
- `MAIL` et `MAIL_PASSWORD` : Configuration e-mail
- `VITE_NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` et `VITE_NEXT_PUBLIC_STRIPE_PRICE_ID` : Configuration Stripe

#### Frontend
- `VITE_API_URL` : URL de l'API backend
- `VITE_NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` et `VITE_NEXT_PUBLIC_STRIPE_PRICE_ID` : Configuration Stripe

## Commandes utiles

- Démarrer les conteneurs : `docker compose up -d`
- Arrêter les conteneurs : `docker compose down`
- Voir les logs : `docker compose logs -f`
- Redémarrer tous les services : `docker compose restart`
- Redémarrer un service spécifique : `docker compose restart <service>` (ex: `docker compose restart backend`)

## Mode développement

Les conteneurs sont configurés en mode développement, avec rechargement à chaud des modifications de code :

- Le code du backend se trouve dans `./ZombieLand-back`
- Le code du frontend se trouve dans `./ZombieLand-front`

## Réinitialisation de la base de données

Pour réinitialiser la base de données, exécutez :

```bash
docker compose exec backend npm run db:reset
```

## Problèmes courants

### Le frontend ne peut pas se connecter au backend

Assurez-vous que la variable d'environnement `VITE_API_URL` dans le service frontend pointe vers l'URL correcte de l'API.

### Erreur de connexion à la base de données

Si le backend ne peut pas se connecter à la base de données, essayez de redémarrer le service postgres :

```bash
docker compose restart postgres
```
