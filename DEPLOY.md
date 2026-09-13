# Déploiement — ZombieLand (tunnel Cloudflare)

Pipeline : `.github/workflows/cicd.yml` construit les images **front** et **back**,
les pousse sur **GHCR**, puis se connecte au VPS **en SSH à travers Cloudflare Access**
(le VPS n'expose aucun port SSH public) pour `docker compose pull && up -d`.

```
push main ──▶ build front+back ──▶ push GHCR ──▶ ssh (via cloudflared) ──▶ VPS: compose pull + up -d
```

Ingress applicatif : le **tunnel Cloudflare pointe vers `https://traefik-central:443`**.
Le Traefik central (stack séparée) route par `Host` vers les conteneurs de ce projet,
qui sont rattachés au réseau Docker externe `traefik-public`. Aucun Traefik ni
Let's Encrypt n'est géré dans ce dépôt.

- `zombieland.creachtheo.fr` → conteneur `frontend` (port 5173)
- `api-zombieland.creachtheo.fr` → conteneur `backend` (port 3666)

> Le domaine de l'API est **`api-zombieland`** (et non `api.zombieland`) : un sous-domaine
> plat reste couvert par le certificat wildcard `*.creachtheo.fr`, contrairement à un
> sous-sous-domaine.

## Secrets GitHub requis (repo `ZombieLand-docker`)

| Secret | Rôle |
|---|---|
| `GHCR_PAT` | PAT (scopes `write:packages`, `read:packages`, `repo`) — push des images en CI + `docker login` sur le VPS + checkout des repos front/back |
| `SSH_HOSTNAME` | Hostname SSH publié dans Cloudflare Access (ex. `ssh.creachtheo.fr`) |
| `VPS_USER` | Utilisateur SSH sur le VPS |
| `VPS_SSH_KEY` | Clé privée SSH (contenu complet) autorisée sur le VPS |
| `VPS_DEPLOY_PATH` | Dossier du `docker-compose.yml` sur le VPS |
| `CF_ACCESS_CLIENT_ID` | Service token Cloudflare Access (`...access`) |
| `CF_ACCESS_CLIENT_SECRET` | Secret du service token Cloudflare Access |

## Fichier `.env` sur le VPS (secrets applicatifs) ⚠️

Le `docker-compose.yml` **ne contient plus aucun secret en clair** : il lit les valeurs
depuis un fichier `.env` situé **dans le même dossier que le compose sur le VPS**
(`VPS_DEPLOY_PATH`). Ce fichier n'est **jamais** committé. À créer une fois, puis à
protéger (`chmod 600 .env`) :

```bash
# $VPS_DEPLOY_PATH/.env  (sur le VPS, jamais dans git)
POSTGRES_PASSWORD=<mot de passe Postgres fort>
JWT_SECRET=<openssl rand -hex 32>
SESSION_SECRET=<openssl rand -hex 32>
JWT_EXPIRY=7d                     # optionnel (défaut 7d)
ADMIN_EMAIL=admin@zombieland.fr   # optionnel
ADMIN_PASSWORD=<mot de passe admin fort>   # optionnel : sinon généré au seed et affiché dans les logs
MAIL=<compte SMTP>                # optionnel (envoi de mails)
MAIL_PASSWORD=<mot de passe SMTP> # optionnel
VITE_NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=<clé Stripe>   # optionnel
VITE_NEXT_PUBLIC_STRIPE_PRICE_ID=<price id Stripe>     # optionnel
```

`docker compose` **refuse de démarrer** si `POSTGRES_PASSWORD`, `JWT_SECRET` ou
`SESSION_SECRET` sont absents (variables marquées `:?` dans le compose) — c'est
volontaire, pour ne jamais déployer avec des secrets par défaut.

> **Rotation :** si des secrets ont pu fuiter (ex. anciens placeholders committés),
> régénérez `JWT_SECRET`/`SESSION_SECRET` et changez le mot de passe admin. Le compte
> admin par défaut historique (`admin@zombieland.fr` / `password`) doit être changé
> immédiatement sur toute base déjà déployée : le seed ne s'exécutant que sur une base
> **vide**, il ne corrige pas un admin existant.

## Prérequis Cloudflare (une seule fois)

1. **App Access "SSH"** sur `SSH_HOSTNAME`.
2. Une **policy `Service Auth`** (⚠️ *pas* `Allow`) attachée à cette app, autorisant le
   **service token** utilisé par la CI (`CF_ACCESS_CLIENT_ID` / `CF_ACCESS_CLIENT_SECRET`).
   Une policy `Allow` exigerait une authentification interactive et ferait échouer le CI.
3. Côté VPS, `cloudflared` doit exposer le service SSH (tunnel `ssh://localhost:22`
   sur le hostname `SSH_HOSTNAME`).

> `cloudflared` est **épinglé à `2026.5.1`** dans le workflow : la `2026.6.0` casse
> l'authentification par service token (cloudflare/cloudflared#1673).

## Prérequis VPS (une seule fois)

### Réseau du Traefik central
Le réseau externe doit exister avant le premier déploiement :
```bash
docker network create traefik-public   # si pas déjà créé par la stack traefik-central
```

### Egress des conteneurs (Stripe + SMTP)
Le backend appelle des API externes (Stripe, envoi de mails via `nodemailer`). Si une
règle `DOCKER-USER` **DROP** le trafic sortant 80/443, ces appels échouent. Autoriser
l'egress des réseaux Docker, **en tête** de la chaîne, puis persister :

```bash
# À exécuter en root sur le VPS, une seule fois
iptables -C DOCKER-USER -s 172.16.0.0/12 -j RETURN 2>/dev/null \
  || iptables -I DOCKER-USER 1 -s 172.16.0.0/12 -j RETURN
# Persister (paquet iptables-persistent)
iptables-save > /etc/iptables/rules.v4
```

## Déploiement

Automatique à chaque `push` sur `main`, ou manuel via *Actions → CI/CD → Run workflow*.

## Notes / points d'attention

- Le backend démarre avec `node src/migrations/checkDb.js || npm run db:reset; npm run dev` :
  la base n'est initialisée (create + seed) que si elle est **vide** (garde idempotente
  `checkDb`). Une base existante n'est jamais wipée. Pour un vrai environnement de prod,
  préférer des migrations versionnées + `npm start` (au lieu de `npm run dev` en watch).
- Les images sont privées sur GHCR : le `docker login` sur le VPS (via `GHCR_PAT`) est
  donc nécessaire au `docker compose pull`.
- Le routage TLS est assuré par le Traefik central (`tls.certresolver=myresolver` conservé
  sur les routers). Le tunnel Cloudflare re-chiffre vers `https://traefik-central:443`.
- PostgreSQL publie le port hôte `5433:5432` (conforme au compose actuel). Le retirer si
  l'accès direct depuis l'hôte n'est pas nécessaire.
