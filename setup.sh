#!/bin/bash

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Installation de ZombieLand ===${NC}"

# Vérification de Docker et Docker Compose
if ! command -v docker &> /dev/null; then
    echo "Docker n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "Docker Compose n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

# Clonage des dépôts
echo -e "${YELLOW}Clonage des dépôts GitHub...${NC}"
git clone https://github.com/creach-t/ZombieLand-back.git
git clone https://github.com/creach-t/ZombieLand-front.git

# Démarrage des conteneurs avec Docker Compose
echo -e "${YELLOW}Démarrage des conteneurs Docker...${NC}"
docker compose up -d

# Affichage des informations d'accès
echo -e "${GREEN}=== Installation terminée avec succès ! ===${NC}"
echo -e "${GREEN}L'application ZombieLand est désormais accessible :${NC}"
echo -e "- Frontend : http://localhost:5173"
echo -e "- Backend API : http://localhost:3000"
echo -e "- Base de données PostgreSQL : localhost:5432"
echo -e ""
echo -e "${YELLOW}Pour arrêter les conteneurs :${NC} docker compose down"
echo -e "${YELLOW}Pour voir les logs :${NC} docker compose logs -f"
echo -e "${YELLOW}Pour redémarrer :${NC} docker compose restart"
