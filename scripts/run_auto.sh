#!/bin/bash
# Mode auto : caméra + YOLOv5 → tri (yolo_detector)
cd "$(dirname "$0")/.."
exec python3 src/yolo_detector.py
