#!/bin/bash
# ============================================
# Smart Bin SI - Installation
# ============================================
# Stack : YOLOv5 via torch.hub (modèle custom best.pt ou fallback yolov5s)
# Pas d'Ultralytics YOLOv8.
# Compatible : Linux, NVIDIA Jetson Nano

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
log_step()  { echo -e "\n${CYAN}[STEP]${NC} $1"; }

# --- En-tête ---
echo -e "${CYAN}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════╗
║   Smart Bin SI - Installation (YOLOv5 torch.hub)     ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

[ "$EUID" -eq 0 ] && log_error "Ne pas lancer avec sudo."

# --- Plateforme ---
log_step "Détection de la plateforme..."
if [ -f /etc/nv_tegra_release ]; then
    PLATFORM="jetson"
    log_info "NVIDIA Jetson détecté"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    log_info "Linux générique"
else
    PLATFORM="linux"
    log_warn "Plateforme inconnue, installation Linux standard"
fi

# --- Mise à jour système ---
log_step "Mise à jour des paquets..."
sudo apt-get update -qq

# --- Dépendances système ---
log_step "Installation des dépendances système..."
sudo apt-get install -y \
    python3-pip python3-dev python3-tk \
    build-essential git curl wget \
    libhdf5-dev libatlas-base-dev libopenblas-dev liblapack-dev \
    libjpeg-dev zlib1g-dev libpython3-dev \
    libavcodec-dev libavformat-dev libswscale-dev

# --- Python ---
PYVER=$(python3 --version 2>&1)
log_info "Python : $PYVER"
python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 6) else 1)" || log_error "Python 3.6+ requis."

# --- Arborescence ---
log_step "Création de l'arborescence..."
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p src arduino models data/logs data/exports data/training_images
mkdir -p datasets/{images,labels}/{train,val,test} tests docs scripts assets/{images,diagrams,videos}
log_info "Racine projet : $ROOT"

# --- pip ---
log_step "Mise à jour de pip..."
python3 -m pip install --upgrade pip setuptools wheel --user

# --- Dépendances Python (sans PyTorch) ---
log_step "Installation des dépendances Python..."
pip3 install --user -r requirements.txt 2>/dev/null || pip3 install --user pyserial numpy Pillow opencv-python matplotlib pandas

# --- PyTorch ---
if [ "$PLATFORM" = "jetson" ]; then
    log_step "PyTorch sur Jetson..."
    if python3 -c "import torch" 2>/dev/null; then
        log_info "PyTorch déjà installé : $(python3 -c 'import torch; print(torch.__version__)')"
    else
        log_warn "Installation du wheel PyTorch Jetson (peut prendre 10–15 min)..."
        WHEEL="torch-1.10.0-cp36-cp36m-linux_aarch64.whl"
        URL="https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl"
        [ ! -f "$WHEEL" ] && wget -q --show-progress -O "$WHEEL" "$URL"
        pip3 install --user "$WHEEL" && rm -f "$WHEEL"
        pip3 install --user torchvision
        log_info "PyTorch Jetson installé"
    fi
else
    log_step "Installation de PyTorch..."
    pip3 install --user torch torchvision
    log_info "PyTorch installé"
fi

# --- YOLOv5 (via torch.hub) ---
log_step "Vérification YOLOv5 (torch.hub)..."
log_info "Le projet utilise YOLOv5 via torch.hub (pas Ultralytics YOLOv8)."
log_info "Modèle custom : mettre models/best.pt ; sinon YOLOv5s COCO sera utilisé au premier run."

# --- Permissions série ---
log_step "Permissions série (Arduino)..."
sudo usermod -a -G dialout "$USER" 2>/dev/null || true
log_warn "Déconnecte-toi / reconnecte-toi pour que le groupe dialout soit pris en compte."

# --- Scripts de lancement ---
log_step "Création des scripts..."

cat > scripts/run_manual.sh << 'LAUNCH'
#!/bin/bash
cd "$(dirname "$0")/.."
exec python3 src/waste_classifier.py
LAUNCH

cat > scripts/run_auto.sh << 'LAUNCH'
#!/bin/bash
cd "$(dirname "$0")/.."
exec python3 src/yolo_detector.py
LAUNCH

chmod +x scripts/run_manual.sh scripts/run_auto.sh

# --- Script de test matériel (créé seulement s'il n'existe pas) ---
if [ ! -f scripts/test_hardware.py ]; then
cat > scripts/test_hardware.py << 'PYTEST'
#!/usr/bin/env python3
"""Tests : série, caméra, PyTorch, YOLOv5 (torch.hub)."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))

def ok(msg):  print("   ✓", msg)
def fail(msg): print("   ✗", msg); return False
def warn(msg): print("   ⚠", msg)

print("Smart Bin SI - Test matériel / stack\n" + "=" * 50)

# 1) Série
print("\n[1] Ports série")
try:
    import serial.tools.list_ports
    ports = list(serial.tools.list_ports.comports())
    if ports:
        for p in ports:
            ok(f"{p.device} - {p.description}")
    else:
        warn("Aucun port série (Arduino non branché ?)")
except ImportError:
    fail("pyserial non installé")

# 2) Caméra
print("\n[2] Caméra")
try:
    import cv2
    cap = cv2.VideoCapture(0)
    if cap.isOpened():
        ok("Caméra /dev/video0 accessible")
        cap.release()
    else:
        warn("Caméra non accessible")
except ImportError:
    fail("opencv-python non installé")

# 3) PyTorch
print("\n[3] PyTorch")
try:
    import torch
    ok(f"PyTorch {torch.__version__}")
    if torch.cuda.is_available():
        ok(f"CUDA : {torch.cuda.get_device_name(0)}")
    else:
        warn("CUDA non disponible (CPU)")
except ImportError:
    fail("PyTorch non installé")

# 4) YOLOv5 (torch.hub) — chargement complet si --yolo
print("\n[4] YOLOv5 (torch.hub)")
try:
    import torch
    ok(f"torch.hub disponible")
    if "--yolo" in sys.argv:
        model = torch.hub.load("ultralytics/yolov5", "yolov5s", pretrained=True)
        ok("YOLOv5s chargé (1er run peut télécharger)")
    else:
        warn("Pour tester le chargement YOLOv5 : python3 scripts/test_hardware.py --yolo")
except Exception as e:
    fail(f"YOLOv5 torch.hub : {e}")

# 5) Modèle custom
print("\n[5] Modèle custom (optionnel)")
custom = ROOT / "models" / "best.pt"
if custom.exists():
    ok(f"models/best.pt présent")
else:
    warn("models/best.pt absent → YOLOv5s COCO sera utilisé au premier run")

print("\n" + "=" * 50 + "\n")
PYTEST
chmod +x scripts/test_hardware.py
fi

# --- Script de test applicatif (créé seulement s'il n'existe pas) ---
if [ ! -f scripts/test_app.py ]; then
cat > scripts/test_app.py << 'PYAPP'
#!/usr/bin/env python3
"""Test applicatif : config, waste_classifier, imports yolo_detector."""
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))
def main():
    print("Smart Bin SI - Test applicatif\n" + "=" * 50)
    try:
        import config
        print("\n[1] config : OK")
        import waste_classifier
        waste_classifier.init_database()
        waste_classifier.init_serial_connection()
        print("[2] waste_classifier : OK")
        waste_classifier.cleanup()
        import yolo_detector
        print("[3] yolo_detector : OK\n" + "=" * 50 + "\n")
        return 0
    except Exception as e:
        print("   ✗", e)
        return 1
if __name__ == "__main__":
    sys.exit(main())
PYAPP
chmod +x scripts/test_app.py
fi

# --- .gitignore (ne pas écraser si existant) ---
if [ ! -f .gitignore ]; then
    log_step "Création de .gitignore..."
    cat > .gitignore << 'GIT'
__pycache__/
*.py[cod]
venv/ .venv/ env/
data/waste_items.db
data/logs/*.log
data/exports/*
models/*.pt
!models/README.md
.vscode/ .idea/
.pytest_cache/ .coverage htmlcov/
GIT
fi

# --- Résumé ---
echo -e "\n${GREEN}Installation terminée.${NC}\n"
echo "Prochaines étapes :"
echo "  1. Se déconnecter/reconnecter (série)"
echo "  2. Tester :  python3 scripts/test_hardware.py"
echo "  3. Test app :  python3 scripts/test_app.py"
echo "  4. Mode manuel :  bash scripts/run_manual.sh"
echo "  5. Mode auto (caméra) :  bash scripts/run_auto.sh"
echo ""
