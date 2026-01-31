# SmartBin - Interface Administrateur

## 📋 Vue d'ensemble

Interface administrative complète pour le système SmartBin. Permet de :
- ✅ Visualiser l'état du système en temps réel (CPU, RAM, Disque)
- ✅ Monitorer les GPU Nvidia (température, VRAM, utilisation)
- ✅ Gérer les niveaux de remplissage des bacs
- ✅ Lancer/arrêter les scripts de surveillance
- ✅ Consulter les détections YOLO
- ✅ Accéder à un bouton d'arrêt d'urgence
- ✅ Éditer les paramètres (config.py)
- ✅ Enregistrer les corrections d'erreurs IA

## 🎯 Fonctionnalités Implémentées

### Dashboard Principal (Accueil)
- Vue d'ensemble du système avec infos temps réel
- Infos du CPU (% utilisation, nb cores, fréquence)
- Infos de la RAM (GB utilisés, % utilisation)
- Infos du disque (GB libres, % utilisation)
- Infos de l'uptime du système
- Infos GPU Nvidia (modèle, température °C, VRAM, utilisation)
- État des équipements (Caméra, Arduino)
- Niveaux de remplissage des 3 bacs
- Console des scripts en cours
- Bouton d'arrêt d'urgence

### Gestion des Bacs
- Affichage des 3 bacs (Recyclage, Compost, Général)
- Visualisation des niveaux (%)
- Statuts de chaque bac

### Détections YOLO
- Tableau des dernières détections
- Confiance, classe, coordonnées
- Timestamps

### Erreurs & Corrections
- Enregistrement des erreurs signalées par les utilisateurs
- Images attachées
- Correction et enregistrement pour l'IA

### Paramètres
- Éditeur de config.py en temps réel
- Mode maintenance
- Activation/désactivation des fonctionnalités

## 📦 Installation

### Prérequis
- Python 3.7+
- pip

### Étapes d'installation

1. **Accéder au répertoire**
```bash
cd z:\SI\SIpoubelle\admin_interface
```

2. **Installer les dépendances**
```bash
pip install -r requirements.txt
```

Si vous avez une carte GPU Nvidia :
```bash
pip install nvidia-ml-py3
```

## 🚀 Exécution de l'Application

### Démarrer le serveur Flask

```bash
python app.py
```

Vous verrez un résultat comme :
```
 * Serving Flask app 'app'
 * Debug mode: on
 * Running on http://127.0.0.1:5000
```

## 🌐 Accès à l'Interface

### Via navigateur local
1. Ouvrez votre navigateur web
2. Allez à l'adresse : **http://127.0.0.1:5000** ou **http://localhost:5000**

### Via autre ordinateur du réseau (même réseau)
1. Trouvez l'IP locale de votre machine :
   ```bash
   ipconfig
   ```
   Cherchez l'adresse IPv4 (ex: 192.168.1.100)

2. Accédez à : **http://<VOTRE_IP>:5000** (ex: http://192.168.1.100:5000)

## 📊 APIs Disponibles

### Informations Système
```
GET /api/system/info
```
Retourne : hostname, OS, uptime, CPU%, RAM (GB et %), Disque (GB et %)

### Informations GPU
```
GET /api/gpu/info
```
Retourne : Nom GPU, Température °C, VRAM utilisée (GB), % utilisation

### Gestion des Scripts
```
GET /api/processes
```
Liste des processus Python en cours

```
GET /api/scripts/run/<script_name>
```
Lance un script (ex: test_app.py, run_auto.sh)

```
GET /api/scripts/stop/<script_name>
```
Arrête un script en cours d'exécution

### Configuration
```
GET /api/config/read
```
Récupère le contenu du config.py

```
POST /api/config/save
```
Enregistre les modifications du config.py
Body: `{"content": "# configuration content"}`

### Équipements (Placeholders)
```
GET /api/camera/status
```
État de la caméra

```
GET /api/arduino/status
```
État d'Arduino

## 🎨 Interface

La page d'accueil affiche :
- **Barre latérale** : Navigation entre les 5 sections
- **En-tête** : Statut du système + Bouton arrêt d'urgence
- **Dashboard** :
  - Grille d'état des équipements (Caméra, Arduino, GPU, Système)
  - Informations système détaillées (CPU, RAM, Disque, Uptime)
  - Console de gestion des scripts
  - Visualisation des niveaux des bacs
  - Tableau des détections YOLO
  - Section erreurs avec corrections IA
  - Éditeur de configuration

## 🛠️ Fonctionnalités Implémentées

### Arrêt d'Urgence
- ✅ Arrête tous les scripts lancés
- ✅ Confirmation avant exécution

### Gestion des Scripts
- ✅ Lance les scripts (test_app.py, test_hardware.py, run_auto.sh, run_manual.sh)
- ✅ Arrête les scripts en cours
- ✅ Console avec logs horodatés

### Mise à Jour en Temps Réel
- ✅ Infos système toutes les 5 secondes
- ✅ Infos GPU toutes les 3 secondes

### Config.py
- ✅ Lecture du fichier config.py
- ✅ Édition dans l'interface
- ✅ Enregistrement des modifications

## 🎮 Navigation

Menu principal :
- 🏠 **Accueil** - Dashboard complet
- 📦 **Gestion des Bacs** - Vue détaillée des 3 bacs
- 📋 **Détections** - Historique YOLO
- ⚠️ **Erreurs** - Signalements utilisateurs et corrections
- ⚙️ **Paramètres** - Configuration et maintenance

## 🔐 Notes de Sécurité

⚠️ **Attention** : Cette version est sans authentification
Avant la production :
- Ajouter un système de login
- Implémenter HTTPS
- Ajouter des contrôles d'accès
- Sécuriser l'API

## 📞 Prochaines Étapes

1. ✅ Interface UI complète
2. ⏳ Backend Flask avec API
3. ⏳ Base de données (SQLite ou autre)
4. ⏳ Intégration Arduino/ESP32
5. ⏳ Système d'authentification
6. ⏳ Déploiement en production

## 💡 Aide

En cas de problème :
1. Vérifiez que Flask est installé : `pip list | grep Flask`
2. Vérifiez le port 5000 n'est pas utilisé : `netstat -ano | findstr :5000`
3. Changez le port dans app.py si nécessaire
4. Consultez la console pour les erreurs

---

**Développé pour SmartBin - Janvier 2026**
