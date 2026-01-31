#!/usr/bin/env python
"""
Script de test pour vérifier les APIs de l'interface administrative
"""

import requests
import json
import time
import subprocess
import os

BASE_URL = "http://localhost:5000"

def test_api(endpoint, method="GET", data=None):
    """Teste une API et affiche le résultat"""
    url = f"{BASE_URL}{endpoint}"
    print(f"\n{'='*60}")
    print(f"[TEST] {method} {endpoint}")
    print(f"{'='*60}")
    
    try:
        if method == "GET":
            response = requests.get(url, timeout=5)
        elif method == "POST":
            response = requests.post(url, json=data, timeout=5)
        
        print(f"Status: {response.status_code}")
        
        try:
            result = response.json()
            print(json.dumps(result, indent=2, ensure_ascii=False))
            return result
        except:
            print(f"Response: {response.text}")
            return None
    except Exception as e:
        print(f"❌ ERREUR: {e}")
        return None

def main():
    print("\n" + "🧪 TEST DES APIs SMARTBIN".center(60, "="))
    
    # Test 1: Infos système
    print("\n[1/4] Test des informations système...")
    system_info = test_api("/api/system/info")
    
    if system_info and system_info.get('success'):
        print("✅ Système: OK")
        sys_data = system_info.get('system', {})
        cpu_data = system_info.get('cpu', {})
        mem_data = system_info.get('memory', {})
        
        print(f"\n  • Hostname: {sys_data.get('hostname')}")
        print(f"  • OS: {sys_data.get('os')} {sys_data.get('os_version')}")
        print(f"  • Uptime: {sys_data.get('uptime')}")
        print(f"  • CPU: {cpu_data.get('percent')}% ({cpu_data.get('count')} cores)")
        print(f"  • RAM: {mem_data.get('used_gb')}GB / {mem_data.get('total_gb')}GB ({mem_data.get('percent')}%)")
    else:
        print("❌ Système: ERREUR")
    
    # Test 2: Infos GPU
    print("\n[2/4] Test des informations GPU...")
    gpu_info = test_api("/api/gpu/info")
    
    if gpu_info:
        if gpu_info.get('gpu_available'):
            print("✅ GPU: OK")
            devices = gpu_info.get('devices', [])
            for i, gpu in enumerate(devices):
                print(f"\n  GPU {i}:")
                print(f"    • Modèle: {gpu.get('name')}")
                print(f"    • Température: {gpu.get('temperature')}°C")
                print(f"    • VRAM: {gpu.get('memory_used_gb')}GB / {gpu.get('memory_total_gb')}GB")
                print(f"    • Utilisation: {gpu.get('utilization_percent')}%")
        else:
            print("⚠️  GPU: Non disponible (drivers NVIDIA manquants?)")
    
    # Test 3: Statut des scripts
    print("\n[3/4] Test du statut des scripts...")
    scripts_status = test_api("/api/scripts/status")
    
    if scripts_status and scripts_status.get('success'):
        print("✅ Scripts Status: OK")
        scripts = scripts_status.get('scripts', {})
        for script, status in scripts.items():
            state = "🟢 EN COURS" if status['running'] else "🔴 Arrêté"
            pid_info = f"(PID: {status['pid']})" if status['running'] else ""
            print(f"  • {script}: {state} {pid_info}")
    else:
        print("❌ Scripts Status: ERREUR")
    
    # Test 4: Config
    print("\n[4/4] Test de lecture config.py...")
    config = test_api("/api/config/read")
    
    if config and config.get('success'):
        print("✅ Config: OK")
        content = config.get('content', '')
        lines = content.split('\n')
        print(f"  • Fichier trouvé: {config.get('path')}")
        print(f"  • Nombre de lignes: {len(lines)}")
        print(f"  • Premiers caractères: {content[:100]}...")
    else:
        print("❌ Config: ERREUR")
    
    # Résumé
    print("\n" + "="*60)
    print("📊 RÉSUMÉ DES TESTS")
    print("="*60)
    
    tests_results = {
        "Système": system_info and system_info.get('success'),
        "GPU": gpu_info and (gpu_info.get('success') or not gpu_info.get('gpu_available')),
        "Scripts": scripts_status and scripts_status.get('success'),
        "Config": config and config.get('success')
    }
    
    passed = sum(1 for v in tests_results.values() if v)
    total = len(tests_results)
    
    for test, result in tests_results.items():
        status = "✅" if result else "❌"
        print(f"{status} {test}")
    
    print(f"\nRésultat: {passed}/{total} tests réussis")
    
    if passed == total:
        print("\n🎉 TOUS LES TESTS SONT PASSÉS!")
    else:
        print(f"\n⚠️  {total - passed} test(s) échoué(s)")

if __name__ == "__main__":
    # Vérifier que le serveur est en cours d'exécution
    try:
        requests.get(f"{BASE_URL}", timeout=2)
    except:
        print("❌ ERREUR: Le serveur Flask n'est pas accessible à localhost:5000")
        print("Veuillez démarrer le serveur avec: python app.py")
        exit(1)
    
    main()
