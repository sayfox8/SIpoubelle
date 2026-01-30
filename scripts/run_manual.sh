#!/bin/bash
# Mode manuel : saisie texte → tri (waste_classifier)
cd "$(dirname "$0")/.."
exec python3 src/waste_classifier.py
