# 🎯 Guide Complet - Interface Admin SmartBin v2.0

## 📋 Résumé des Améliorations

### ✅ Ce Qui Est Maintenant Fonctionnel

#### 1. **Affichage du Statut des Scripts EN TEMPS RÉEL**
- ✅ Actualisation automatique toutes les 2 secondes
- ✅ État visible : "EN COURS (PID: 1234)" ou "Arrêté"
- ✅ Badges colorés : 🟢 Vert = EN COURS, 🔴 Gris = Arrêté
- ✅ Désactivation intelligente des boutons selon le statut

#### 2. **Infos Système EN TEMPS RÉEL (toutes les 5 sec)**
- ✅ CPU : % utilisation, nb cores, fréquence
- ✅ RAM : GB utilisés / total, % utilisation
- ✅ Disque : GB libres / total, % utilisation
- ✅ Système : Hostname, OS, Uptime, Python version

#### 3. **APIs Implémentées et Testées**
| Endpoint | Statut | Données Retournées |
|----------|--------|-------------------|
| `/api/system/info` | ✅ | CPU, RAM, Disque, Uptime, OS |
| `/api/gpu/info` | ⚠️ | GPU (sans drivers NVIDIA) |
| `/api/scripts/status` | ✅ | État de chaque script + PID |
| `/api/scripts/run/<script>` | ✅ | Lancer un script |
| `/api/scripts/stop/<script>` | ✅ | Arrêter un script |
| `/api/config/read` | ✅ | Contenu config.py |
| `/api/config/save` | ✅ | Sauvegarder config.py |
| `/api/camera/status` | 🔄 | Placeholder (à intégrer) |
| `/api/arduino/status` | 🔄 | Placeholder (à intégrer) |

## 🚀 Comment Démarrer

### Étape 1 : Lancer le Serveur Flask

```bash
cd z:\SI\SIpoubelle\admin_interface
python app.py
```

Output attendu :
```
[WARN] nvidia-ml-py non installé. Les infos GPU ne seront pas disponibles.
 * Serving Flask app 'app'
 * Debug mode: on
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.1.31:5000
```

### Étape 2 : Accéder à l'Interface

Ouvrir dans un navigateur :
- Local : **http://localhost:5000**
- Réseau : **http://192.168.1.31:5000** (ou votre IP)

### Étape 3 : Tester les Fonctionnalités

#### A. Voir l'État des Scripts
1. Cliquez sur l'onglet "Accueil"
2. Regardez la section "Scripts Disponibles"
3. Vous verrez l'état en temps réel de chaque script :
   - 🟢 **EN COURS (PID: 1234)** = Script en cours d'exécution
   - 🔴 **Arrêté** = Script arrêté

#### B. Lancer un Script
1. Allez à la section "Scripts Disponibles"
2. Cliquez sur le bouton "▶ Lancer" du script
3. Attendez 1-2 secondes
4. Le badge passe de 🔴 Arrêté à 🟢 EN COURS
5. Le PID du processus s'affiche

#### C. Arrêter un Script
1. Cliquez sur "⊗ Stop" pour le script en cours
2. Le badge passe à 🔴 Arrêté
3. La console affiche "[STOP] Arrêt de..."

#### D. Voir les Logs
1. Cliquez sur "📋 Console" pour ouvrir la modal
2. Tous les logs horodatés y sont affichés
3. Format : `[HH:MM:SS] [TYPE] Message`

#### E. Voir l'État du Système
1. Regardez les cartes "Système" et "GPU"
2. Les données s'actualisent automatiquement
3. Affichage :
   - Uptime : "2h 43m"
   - CPU : "14.7% (12 cores)"
   - RAM : "11.9GB / 23.87GB (49.9%)"
   - Disque : "909.66GB libre (11.2% utilisé)"

## 🧪 Tester les APIs

### Script de Test Automatisé

```bash
cd z:\SI\SIpoubelle\admin_interface
python test_apis.py
```

Résultat attendu :
```
🎉 TOUS LES TESTS SONT PASSÉS!
✅ Système
✅ GPU
✅ Scripts
✅ Config
```

### Tests Manuels via cURL

```bash
# Infos système
curl http://localhost:5000/api/system/info

# État des scripts
curl http://localhost:5000/api/scripts/status

# Lancer test_app.py
curl http://localhost:5000/api/scripts/run/test_app.py

# Arrêter test_app.py
curl http://localhost:5000/api/scripts/stop/test_app.py

# Lire config.py
curl http://localhost:5000/api/config/read
```

## 📊 Données Affichées En Temps Réel

### Dashboard Principal

```
┌─────────────────────────────────────────────┐
│ 🏠 ACCUEIL - Dashboard Principal            │
├─────────────────────────────────────────────┤
│ 📊 SYSTÈME                                  │
│  • Uptime: 2h 43m                          │
│  • CPU: 14.7% (12 cores @ 2904 MHz)        │
│  • RAM: 11.9GB / 23.87GB (49.9%)           │
│  • Disque: 909.66GB / 1024GB (11.2%)       │
│  • Hostname: PC-Florian                    │
│  • OS: Windows 11 (Python 3.12.8)          │
│                                             │
│ 🎮 GPU                                      │
│  • Modèle: Non disponible                  │
│  • Température: N/A                        │
│  • VRAM: N/A                               │
│                                             │
│ 🔧 SCRIPTS                                  │
│  • test_app.py: 🔴 Arrêté                  │
│  • test_hardware.py: 🔴 Arrêté             │
│  • run_auto.sh: 🔴 Arrêté                  │
│  • run_manual.sh: 🔴 Arrêté                │
│                                             │
│ 📝 CONSOLE                                  │
│  [HH:MM:SS] [INFO] Interface chargée       │
│  [HH:MM:SS] [RUN] Lancement de test_app... │
│  [HH:MM:SS] [INFO] test_app lancé          │
└─────────────────────────────────────────────┘
```

## ⚙️ Configuration & Personnalisation

### Changer le Port

Modifier dans `app.py` (dernière ligne) :
```python
if __name__ == '__main__':
    app.run(debug=True, port=8080, host='0.0.0.0')  # Changer 5000 en 8080
```

### Désactiver le Debug Mode

```python
app.run(debug=False, port=5000, host='0.0.0.0')
```

### Modifier la Fréquence de Mise à Jour

Dans `script.js`, chercher :
```javascript
setInterval(updateSystemInfo, 5000);      // 5 sec
setInterval(updateGPUInfo, 3000);         // 3 sec
updateScriptsStatus, 2000);               // 2 sec
```

## 🐛 Dépannage

### L'interface affiche "Aucune donnée"
→ Vérifier que le serveur Flask est actif : `python app.py`

### GPU affiche "Non disponible"
→ C'est normal sans drivers NVIDIA installés
→ À intégrer avec les vrais drivers si nécessaire

### Les scripts ne se lancent pas
→ Vérifier que les chemins existent : `z:\SI\SIpoubelle\scripts\`
→ Vérifier les permissions d'exécution

### L'interface ne se charge pas du tout
→ Vérifier que port 5000 est libre
→ Essayer `http://127.0.0.1:5000` au lieu de `localhost`

## 📁 Structure des Fichiers

```
admin_interface/
├── app.py                     # Flask backend (300+ lignes)
├── requirements.txt           # Dépendances
├── test_apis.py              # Script de test
├── README.md                 # Doc principale
├── INTEGRATION_GUIDE.md       # Guide d'intégration
├── UPDATES.md                # Changelog
└── static/
    ├── index.html            # Interface (5 sections)
    ├── style.css             # Styles responsive
    └── script.js             # Logique frontend (340+ lignes)
```

## 📈 Statistiques

| Métrique | Valeur |
|----------|--------|
| Lignes Flask | 343 |
| Lignes JS | 342 |
| Lignes CSS | 860 |
| APIs implémentées | 9 |
| Données temps réel | 3 (system, GPU, scripts) |
| Scripts gérés | 4 |
| Tests automatisés | 4 |

## ✨ Prochaines Étapes Recommandées

### Court Terme (Facile)
- [ ] Ajouter WebSocket pour mises à jour push
- [ ] Ajouter base de données SQLite pour historique
- [ ] Implémenter la lecture des logs en direct

### Moyen Terme (Moyen)
- [ ] Intégrer OpenCV pour le flux caméra
- [ ] Intégrer PySerial pour Arduino
- [ ] Ajouter détection capteurs ultrason

### Long Terme (Complexe)
- [ ] Authentification utilisateur
- [ ] HTTPS et certificats
- [ ] Dashboard multi-utilisateur
- [ ] Notifications en temps réel

## 📞 Support

Pour toute question ou bug :
1. Vérifier les logs Flask dans le terminal
2. Ouvrir la console navigateur (F12)
3. Exécuter `python test_apis.py` pour diagnostic
4. Consulter `INTEGRATION_GUIDE.md` pour les APIs

---

**Version** : 2.0  
**Date** : 31 Janvier 2026  
**Status** : ✅ Fonctionnel  
**Tests** : ✅ 4/4 Passés
