#!/bin/bash
# ============================================
# Smart Bin SI - Complete Setup Script
# ============================================
# Installs all dependencies and sets up project structure
# Compatible with NVIDIA Jetson Nano and standard Linux

set -e  # Exit on error

# ============================================
# COLORS
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# LOGGING FUNCTIONS
# ============================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}[STEP]${NC} ${BLUE}$1${NC}"
}

# ============================================
# HEADER
# ============================================
clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        🤖  SMART BIN SI - INSTALLATION SCRIPT  🗑️        ║
║                                                           ║
║              Automated Setup for Jetson Nano              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# ============================================
# CHECK PRIVILEGES
# ============================================
if [ "$EUID" -eq 0 ]; then
    log_error "Do not run with sudo. The script will ask for permissions when needed."
    exit 1
fi

# ============================================
# PLATFORM DETECTION
# ============================================
log_step "Detecting Platform..."

PLATFORM="unknown"
if [ -f /etc/nv_tegra_release ]; then
    PLATFORM="jetson"
    log_info "Platform: NVIDIA Jetson"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    log_info "Platform: Linux (Generic)"
else
    log_warn "Platform unknown - Attempting standard Linux installation"
    PLATFORM="linux"
fi

# ============================================
# SYSTEM UPDATE
# ============================================
log_step "Updating System Packages..."

sudo apt-get update -qq
log_info "Package list updated"

# ============================================
# INSTALL SYSTEM DEPENDENCIES
# ============================================
log_step "Installing System Dependencies..."

sudo apt-get install -y \
    python3-pip \
    python3-dev \
    python3-tk \
    build-essential \
    git \
    curl \
    wget \
    libhdf5-dev \
    libatlas-base-dev \
    libopenblas-dev \
    liblapack-dev \
    libjpeg-dev \
    zlib1g-dev \
    libpython3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev

log_info "System dependencies installed"

# ============================================
# CHECK PYTHON VERSION
# ============================================
log_step "Checking Python Version..."

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
log_info "Python version: $PYTHON_VERSION"

if [[ ! "$PYTHON_VERSION" =~ ^3\.[6-9] ]]; then
    log_error "Python 3.6+ required (found: $PYTHON_VERSION)"
    exit 1
fi

# ============================================
# CREATE PROJECT STRUCTURE
# ============================================
log_step "Creating Project Structure..."

mkdir -p src
mkdir -p arduino
mkdir -p models
mkdir -p data/logs
mkdir -p data/exports
mkdir -p datasets/{images,labels}/{train,val,test}
mkdir -p tests
mkdir -p docs
mkdir -p assets/{images,diagrams,videos}
mkdir -p scripts

log_info "Directory structure created"

# ============================================
# UPGRADE PIP
# ============================================
log_step "Upgrading pip..."

python3 -m pip install --upgrade pip setuptools wheel --user

# ============================================
# INSTALL PYTHON DEPENDENCIES
# ============================================
log_step "Installing Python Dependencies..."

# Create requirements.txt if it doesn't exist
if [ ! -f requirements.txt ]; then
    cat > requirements.txt << EOF
# Core Dependencies
pyserial>=3.5
numpy>=1.19.0
Pillow>=8.0.0
opencv-python>=4.5.0

# YOLO (will handle PyTorch separately for Jetson)
ultralytics>=8.0.0

# Optional
matplotlib>=3.3.0
pandas>=1.3.0
EOF
    log_info "Created requirements.txt"
fi

# Install base dependencies
pip3 install --user pyserial numpy Pillow opencv-python matplotlib pandas

log_info "Base dependencies installed"

# ============================================
# JETSON-SPECIFIC PYTORCH INSTALLATION
# ============================================
if [ "$PLATFORM" == "jetson" ]; then
    log_step "Installing PyTorch for Jetson..."
    
    # Check if PyTorch is already installed
    if python3 -c "import torch" &> /dev/null; then
        TORCH_VERSION=$(python3 -c "import torch; print(torch.__version__)")
        log_info "PyTorch already installed: v$TORCH_VERSION"
    else
        log_warn "PyTorch not found - Installing..."
        log_warn "This may take 10-15 minutes..."
        
        # Download pre-built PyTorch wheel for Jetson
        TORCH_WHEEL="torch-1.10.0-cp36-cp36m-linux_aarch64.whl"
        TORCH_URL="https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl"
        
        if [ ! -f "$TORCH_WHEEL" ]; then
            wget -q --show-progress -O "$TORCH_WHEEL" "$TORCH_URL"
        fi
        
        pip3 install --user "$TORCH_WHEEL"
        rm "$TORCH_WHEEL"
        
        # Install torchvision
        pip3 install --user torchvision
        
        log_info "PyTorch installed for Jetson"
    fi
else
    # Standard Linux - Install PyTorch via pip
    log_step "Installing PyTorch..."
    pip3 install --user torch torchvision
    log_info "PyTorch installed"
fi

# ============================================
# INSTALL ULTRALYTICS YOLO
# ============================================
log_step "Installing Ultralytics YOLOv8..."

pip3 install --user ultralytics

log_info "YOLOv8 installed"

# ============================================
# CONFIGURE SERIAL PERMISSIONS
# ============================================
log_step "Configuring Serial Port Permissions..."

# Add user to dialout group
sudo usermod -a -G dialout $USER

log_info "User added to 'dialout' group"
log_warn "You need to LOG OUT and LOG BACK IN for serial permissions to take effect"

# ============================================
# CREATE LAUNCH SCRIPTS
# ============================================
log_step "Creating Launch Scripts..."

# Script 1: Run Manual Mode
cat > scripts/run_manual.sh << 'EOFSCRIPT'
#!/bin/bash
cd "$(dirname "$0")/.."
python3 src/waste_classifier.py
EOFSCRIPT
chmod +x scripts/run_manual.sh

# Script 2: Run Auto Mode
cat > scripts/run_auto.sh << 'EOFSCRIPT'
#!/bin/bash
cd "$(dirname "$0")/.."
python3 src/yolo_detector.py
EOFSCRIPT
chmod +x scripts/run_auto.sh

# Script 3: Test Hardware
cat > scripts/test_hardware.py << 'EOFSCRIPT'
#!/usr/bin/env python3
"""Quick hardware test script"""
import sys

print("Testing Hardware Connections...\n")

# Test 1: Serial ports
print("[1] Checking Serial Ports...")
try:
    import serial.tools.list_ports
    ports = list(serial.tools.list_ports.comports())
    if ports:
        print(f"   ✓ Found {len(ports)} port(s):")
        for p in ports:
            print(f"      - {p.device}")
    else:
        print("   ✗ No serial ports found")
except ImportError:
    print("   ✗ pyserial not installed")

# Test 2: Camera
print("\n[2] Checking Camera...")
try:
    import cv2
    cap = cv2.VideoCapture(0)
    if cap.isOpened():
        print("   ✓ Camera accessible at /dev/video0")
        cap.release()
    else:
        print("   ✗ Camera not accessible")
except ImportError:
    print("   ✗ opencv-python not installed")

# Test 3: PyTorch
print("\n[3] Checking PyTorch...")
try:
    import torch
    print(f"   ✓ PyTorch v{torch.__version__}")
    if torch.cuda.is_available():
        print(f"   ✓ CUDA available (GPU: {torch.cuda.get_device_name(0)})")
    else:
        print("   ⚠ CUDA not available (will use CPU)")
except ImportError:
    print("   ✗ PyTorch not installed")

# Test 4: YOLO
print("\n[4] Checking YOLOv8...")
try:
    from ultralytics import YOLO
    print("   ✓ Ultralytics YOLOv8 installed")
except ImportError:
    print("   ✗ Ultralytics not installed")

print("\n" + "="*50)
print("Hardware test complete!")
print("="*50 + "\n")
EOFSCRIPT
chmod +x scripts/test_hardware.py

log_info "Launch scripts created"

# ============================================
# CREATE .gitignore
# ============================================
log_step "Creating .gitignore..."

cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
.venv

# Data
data/waste_items.db
data/logs/*.log
data/exports/*.csv
data/exports/*.json

# Models (if too large)
models/*.pt
!models/README.md

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
*.tmp

# Jupyter
.ipynb_checkpoints

# Testing
.pytest_cache/
*.cover
.coverage
htmlcov/
EOF

log_info ".gitignore created"

# ============================================
# CREATE README
# ============================================
log_step "Creating README.md..."

cat > README.md << 'EOF'
# 🤖 Smart Bin SI - Intelligent Waste Sorting System

Automated waste classification system using NVIDIA Jetson Nano, YOLOv8, and Arduino.

## 🚀 Quick Start

### 1. Manual Mode (Text Input)
```bash
bash scripts/run_manual.sh
```

### 2. Automatic Mode (Camera Detection)
```bash
bash scripts/run_auto.sh
```

### 3. Test Hardware
```bash
python3 scripts/test_hardware.py
```

## 📁 Project Structure

```
SmartBin_SI/
├── src/              # Python source code
├── arduino/          # Arduino firmware
├── models/           # YOLO models
├── data/             # Database and logs
├── scripts/          # Launch scripts
└── docs/             # Documentation
```

## 📚 Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Usage Guide](docs/USAGE.md)
- [Hardware Setup](docs/HARDWARE_SETUP.md)
- [YOLO Training](docs/YOLO_TRAINING.md)

## 🔧 Configuration

Edit `src/config.py` to customize:
- Model selection
- Camera settings
- Arduino port
- Waste-to-bin mapping

## 🎯 Next Steps

1. Download a pre-trained model:
   ```bash
   python3 scripts/download_model.py
   ```

2. Upload Arduino code:
   - Open `arduino/smart_bin_controller.ino` in Arduino IDE
   - Select board: Arduino Uno
   - Upload

3. Run the system!

## 📞 Support

See `docs/TROUBLESHOOTING.md` for common issues.

---

**License:** MIT  
**Author:** Smart Bin SI Team
EOF

log_info "README.md created"

# ============================================
# FINAL SUMMARY
# ============================================
echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║              ✅  INSTALLATION COMPLETE!  ✅               ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}📁 Project Location:${NC} $(pwd)"
echo -e "${CYAN}🐍 Python Version:${NC} $PYTHON_VERSION"
echo -e "${CYAN}🖥️  Platform:${NC} $PLATFORM"

echo -e "\n${YELLOW}⚠️  IMPORTANT NEXT STEPS:${NC}\n"
echo "1. LOG OUT and LOG BACK IN to apply serial permissions"
echo "2. Download a YOLO model:"
echo "   ${CYAN}python3 scripts/download_model.py${NC}"
echo ""
echo "3. Upload Arduino code:"
echo "   ${CYAN}arduino/smart_bin_controller.ino${NC}"
echo ""
echo "4. Test hardware connections:"
echo "   ${CYAN}python3 scripts/test_hardware.py${NC}"
echo ""
echo "5. Run the system:"
echo "   Manual:  ${CYAN}bash scripts/run_manual.sh${NC}"
echo "   Auto:    ${CYAN}bash scripts/run_auto.sh${NC}"

echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       🎉 Happy Waste Sorting! 🗑️ ♻️                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}\n"