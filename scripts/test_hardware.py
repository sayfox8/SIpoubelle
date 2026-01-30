#!/usr/bin/env python3
"""
Smart Bin SI - Tests matériel et stack
Vérifie : ports série, caméra, PyTorch, YOLOv5 (torch.hub), modèle custom.
Usage : python3 scripts/test_hardware.py [--yolo]
  --yolo : teste aussi le chargement complet de YOLOv5s (télécharge si besoin).
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))


def ok(msg):
    print("   ✓", msg)


def fail(msg):
    print("   ✗", msg)
    return False


def warn(msg):
    print("   ⚠", msg)


def main():
    print("Smart Bin SI - Test matériel / stack\n" + "=" * 50)

    # 1) Ports série
    print("\n[1] Ports série (Arduino)")
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
        return

    # 4) YOLOv5 (torch.hub)
    print("\n[4] YOLOv5 (torch.hub)")
    try:
        import torch
        ok("torch.hub disponible")
        if "--yolo" in sys.argv:
            print("   Chargement YOLOv5s (1er run peut télécharger)...")
            model = torch.hub.load("ultralytics/yolov5", "yolov5s", pretrained=True)
            ok("YOLOv5s chargé")
        else:
            warn("Pour tester le chargement YOLOv5 : python3 scripts/test_hardware.py --yolo")
    except Exception as e:
        fail(f"YOLOv5 : {e}")

    # 5) Modèle custom
    print("\n[5] Modèle custom (optionnel)")
    custom = ROOT / "models" / "best.pt"
    if custom.exists():
        ok("models/best.pt présent")
    else:
        warn("models/best.pt absent → YOLOv5s COCO sera utilisé au premier run")

    print("\n" + "=" * 50 + "\n")


if __name__ == "__main__":
    main()
