# Guide d'Intégration des APIs SmartBin

Ce document explique comment intégrer les APIs réelles dans l'interface administrateur.

## État Actuel

### APIs Implémentées ✅
- `/api/system/info` - Infos système réelles (CPU, RAM, disque, uptime)
- `/api/gpu/info` - Infos GPU Nvidia réelles (modèle, température, VRAM)
- `/api/scripts/run/<script>` - Lancer les scripts
- `/api/scripts/stop/<script>` - Arrêter les scripts
- `/api/processes` - Liste des processus
- `/api/config/read` - Lire config.py
- `/api/config/save` - Écrire config.py

### APIs Placeholders ⏳
- `/api/camera/status` - À intégrer avec le code caméra
- `/api/arduino/status` - À intégrer avec le code Arduino

## Guide d'Intégration

### 1. Intégration Caméra (OpenCV/Streaming)

**Fichier à modifier** : `app.py`

```python
import cv2
from threading import Thread
import time

class CameraManager:
    def __init__(self, device_id=0):
        self.cap = cv2.VideoCapture(device_id)
        self.frame = None
        self.is_running = False
    
    def read_frames(self):
        while self.is_running:
            ret, frame = self.cap.read()
            if ret:
                self.frame = frame
            time.sleep(0.03)  # ~30 FPS
    
    def start(self):
        self.is_running = True
        Thread(target=self.read_frames, daemon=True).start()
    
    def stop(self):
        self.is_running = False

camera = CameraManager()

@app.route('/api/camera/frame')
def get_camera_frame():
    """Retourne la frame caméra en MJPEG"""
    def gen():
        while True:
            if camera.frame is not None:
                ret, jpg = cv2.imencode('.jpg', camera.frame)
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n'
                       b'Content-Length: ' + str(len(jpg)).encode() + b'\r\n\r\n' 
                       + jpg.tobytes() + b'\r\n')
            time.sleep(0.03)
    return Response(gen(), mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/api/camera/status', methods=['GET'])
def camera_status_updated():
    """Retourne le statut réel de la caméra"""
    return jsonify({
        'success': True,
        'connected': camera.cap.isOpened(),
        'resolution': f"{int(camera.cap.get(3))}x{int(camera.cap.get(4))}",
        'fps': int(camera.cap.get(5)),
        'device': '/dev/video0',
        'last_frame': datetime.now().isoformat() if camera.frame is not None else None
    })
```

### 2. Intégration Arduino (PySerial)

**Fichier à modifier** : `app.py`

```python
import serial
from serial.tools import list_ports

class ArduinoManager:
    def __init__(self, port=None, baudrate=9600):
        self.port = port
        self.baudrate = baudrate
        self.ser = None
        self.is_connected = False
        self.connect()
    
    def find_port(self):
        """Trouve automatiquement le port Arduino"""
        ports = list_ports.comports()
        for p in ports:
            if 'Arduino' in p.description or 'USB' in p.description:
                return p.device
        return None
    
    def connect(self):
        try:
            port = self.port or self.find_port()
            if port:
                self.ser = serial.Serial(port, self.baudrate, timeout=5)
                self.is_connected = True
                self.port = port
        except Exception as e:
            self.is_connected = False
            print(f"Erreur connexion Arduino: {e}")
    
    def send_command(self, command):
        """Envoie une commande à Arduino"""
        if self.is_connected and self.ser:
            try:
                self.ser.write(f"{command}\n".encode())
                return True
            except Exception as e:
                print(f"Erreur envoi: {e}")
                return False
        return False
    
    def read_response(self):
        """Lit la réponse d'Arduino"""
        if self.is_connected and self.ser:
            try:
                response = self.ser.readline().decode().strip()
                return response
            except Exception as e:
                print(f"Erreur lecture: {e}")
                return None
        return None

arduino = ArduinoManager()

@app.route('/api/arduino/status')
def arduino_status_updated():
    """Statut réel d'Arduino"""
    return jsonify({
        'success': True,
        'connected': arduino.is_connected,
        'port': arduino.port,
        'baudrate': arduino.baudrate,
        'motor_status': 'Fonctionnel' if arduino.is_connected else 'Déconnecté',
        'last_communication': datetime.now().isoformat()
    })

@app.route('/api/arduino/command/<cmd>')
def send_arduino_command(cmd):
    """Envoie une commande Arduino"""
    if arduino.send_command(cmd):
        response = arduino.read_response()
        return jsonify({'success': True, 'response': response})
    return jsonify({'success': False, 'error': 'Commande non envoyée'})
```

### 3. Intégration YOLO (Détections)

**Fichier à modifier** : `app.py`

```python
from src.yolo_detector import YOLODetector

detector = YOLODetector('yolov5s.pt')

@app.route('/api/detections/latest')
def get_latest_detections():
    """Récupère les dernières détections YOLO"""
    detections = detector.get_last_detections(limit=10)
    return jsonify({
        'success': True,
        'detections': [
            {
                'id': d.id,
                'class': d.class_name,
                'confidence': d.confidence,
                'bbox': d.bbox,
                'timestamp': d.timestamp.isoformat()
            }
            for d in detections
        ]
    })

@app.route('/api/detections/count')
def get_detections_count():
    """Compte des détections par classe"""
    counts = detector.get_detections_count()
    return jsonify({
        'success': True,
        'counts': counts
    })
```

### 4. Intégration Niveaux des Bacs (Capteurs Ultrason)

**Fichier à modifier** : `app.py`

```python
# Importer depuis le code existant
from src.waste_classifier import BinLevelSensor

class BinManager:
    def __init__(self):
        self.bins = {
            'yellow': BinLevelSensor(pin=25),     # Recyclage
            'green': BinLevelSensor(pin=24),      # Compost
            'brown': BinLevelSensor(pin=23)       # Général
        }
    
    def get_levels(self):
        return {
            'yellow': {
                'name': 'Recyclage',
                'level': self.bins['yellow'].get_level(),
                'is_full': self.bins['yellow'].is_full()
            },
            'green': {
                'name': 'Compost',
                'level': self.bins['green'].get_level(),
                'is_full': self.bins['green'].is_full()
            },
            'brown': {
                'name': 'Général',
                'level': self.bins['brown'].get_level(),
                'is_full': self.bins['brown'].is_full()
            }
        }

bin_manager = BinManager()

@app.route('/api/bins/levels')
def get_bins_levels():
    """Récupère les niveaux réels des bacs"""
    try:
        levels = bin_manager.get_levels()
        return jsonify({
            'success': True,
            'levels': levels
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})
```

### 5. Base de Données (Erreurs et Corrections)

**Fichier à créer** : `database.py`

```python
import sqlite3
from datetime import datetime

class Database:
    def __init__(self, db_path='smartbin.db'):
        self.db_path = db_path
        self.init_db()
    
    def init_db(self):
        """Initialise la base de données"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Table des erreurs
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS errors (
                    id INTEGER PRIMARY KEY,
                    timestamp DATETIME,
                    description TEXT,
                    image_path TEXT,
                    user_feedback TEXT
                )
            ''')
            
            # Table des corrections
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS corrections (
                    id INTEGER PRIMARY KEY,
                    error_id INTEGER,
                    correct_class TEXT,
                    confidence FLOAT,
                    timestamp DATETIME,
                    FOREIGN KEY(error_id) REFERENCES errors(id)
                )
            ''')
            
            conn.commit()
    
    def add_error(self, description, image_path=None):
        """Ajoute une erreur"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                'INSERT INTO errors VALUES (NULL, ?, ?, ?, NULL)',
                (datetime.now().isoformat(), description, image_path)
            )
            conn.commit()
            return cursor.lastrowid
    
    def add_correction(self, error_id, correct_class, confidence=1.0):
        """Ajoute une correction"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                'INSERT INTO corrections VALUES (NULL, ?, ?, ?, ?)',
                (error_id, correct_class, confidence, datetime.now().isoformat())
            )
            conn.commit()
    
    def get_errors(self, limit=50):
        """Récupère les erreurs"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                'SELECT * FROM errors ORDER BY timestamp DESC LIMIT ?',
                (limit,)
            )
            return cursor.fetchall()

# Dans app.py
from database import Database
db = Database()

@app.route('/api/errors/list')
def list_errors():
    """Liste les erreurs enregistrées"""
    errors = db.get_errors()
    return jsonify({
        'success': True,
        'errors': [
            {
                'id': e[0],
                'timestamp': e[1],
                'description': e[2],
                'image': e[3],
                'feedback': e[4]
            }
            for e in errors
        ]
    })

@app.route('/api/errors/correct', methods=['POST'])
def correct_error():
    """Enregistre une correction"""
    data = request.get_json()
    error_id = data.get('error_id')
    correct_class = data.get('correct_class')
    
    db.add_correction(error_id, correct_class)
    return jsonify({'success': True, 'message': 'Correction enregistrée'})
```

## Checklist d'Intégration

- [ ] Intégrer OpenCV pour le flux caméra
- [ ] Intégrer PySerial pour Arduino
- [ ] Tester `/api/camera/frame` avec un stream MJPEG
- [ ] Tester `/api/arduino/command/<cmd>` avec des commandes réelles
- [ ] Intégrer YOLO détections
- [ ] Intégrer capteurs ultrason bacs
- [ ] Créer base de données SQLite
- [ ] Tester toutes les APIs en temps réel
- [ ] Ajouter logging/debugging
- [ ] Implémenter WebSockets pour actualisations en direct

## Notes

- Modifier `script.js` pour utiliser `/api/camera/frame` au lieu du placeholder
- Ajouter un manager pour les connexions persistantes (caméra, Arduino)
- Implémenter le reconnexion automatique en cas d'erreur
- Ajouter des timeouts et gestion d'erreurs robustes
