#!/usr/bin/env python3
"""
Smart Bin SI - Test applicatif (imports + config + waste_classifier)
Vérifie que le code charge sans erreur et que la config / DB sont utilisables.
Usage : python3 scripts/test_app.py
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))


def main():
    print("Smart Bin SI - Test applicatif\n" + "=" * 50)

    # 1) Config
    print("\n[1] Config")
    try:
        import config
        print("   ✓ config chargé")
        print(f"   ✓ MODEL_PATH = {config.MODEL_PATH}")
        print(f"   ✓ ARDUINO_PORT = {config.ARDUINO_PORT}")
    except Exception as e:
        print("   ✗", e)
        return 1

    # 2) waste_classifier (DB + série en mode simulation si pas d'Arduino)
    print("\n[2] waste_classifier")
    try:
        import waste_classifier
        waste_classifier.init_database()
        waste_classifier.init_serial_connection()
        print("   ✓ waste_classifier chargé (DB + série)")
        # Test mapping
        bin_color = waste_classifier.get_bin_color("plastic")
        print(f"   ✓ get_bin_color('plastic') = {bin_color}")
        waste_classifier.cleanup()
    except Exception as e:
        print("   ✗", e)
        return 1

    # 3) Imports yolo_detector (sans lancer la boucle)
    print("\n[3] yolo_detector (imports)")
    try:
        import yolo_detector
        print("   ✓ yolo_detector importé (WasteDetector disponible)")
    except Exception as e:
        print("   ✗", e)
        return 1

    print("\n" + "=" * 50)
    print("Tous les tests applicatifs sont passés.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
