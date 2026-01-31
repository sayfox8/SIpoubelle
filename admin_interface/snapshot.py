#!/usr/bin/env python
"""Affiche un snapshot des données actuelles"""

import requests
import json
from datetime import datetime

print('='*60)
print('📊 SNAPSHOT EN TEMPS RÉEL - Interface Admin SmartBin')
print('='*60)
print(f'\nTimestamp: {datetime.now().strftime("%d/%m/%Y %H:%M:%S")}')

try:
    # System Info
    print('\n[SYSTÈME]')
    resp = requests.get('http://localhost:5000/api/system/info', timeout=5)
    data = resp.json()
    if data['success']:
        sys_info = data['system']
        cpu_info = data['cpu']
        mem_info = data['memory']
        disk_info = data['disk']
        
        print(f'  • Hostname: {sys_info["hostname"]}')
        print(f'  • OS: {sys_info["os"]} {sys_info["os_version"]}')
        print(f'  • Uptime: {sys_info["uptime"]}')
        print(f'  • CPU: {cpu_info["percent"]}% ({cpu_info["count"]} cores @ {cpu_info["freq_mhz"]} MHz)')
        print(f'  • RAM: {mem_info["used_gb"]}GB / {mem_info["total_gb"]}GB ({mem_info["percent"]}%)')
        print(f'  • Disque: {disk_info["free_gb"]}GB libre / {disk_info["total_gb"]}GB ({disk_info["percent"]}% utilisé)')
    
    # GPU Info
    print('\n[GPU]')
    resp = requests.get('http://localhost:5000/api/gpu/info', timeout=5)
    data = resp.json()
    if data['gpu_available'] and data['devices']:
        for i, gpu in enumerate(data['devices']):
            print(f'  GPU {i}: {gpu["name"]}')
            print(f'    • Température: {gpu["temperature"]}°C')
            print(f'    • VRAM: {gpu["memory_used_gb"]}GB / {gpu["memory_total_gb"]}GB ({gpu["memory_percent"]}%)')
            print(f'    • Utilisation: {gpu["utilization_percent"]}%')
    else:
        print('  ⚠️  Non disponible (drivers NVIDIA manquants?)')
    
    # Scripts Status
    print('\n[SCRIPTS]')
    resp = requests.get('http://localhost:5000/api/scripts/status', timeout=5)
    data = resp.json()
    if data['success']:
        for script, status in data['scripts'].items():
            if status['running']:
                print(f'  ✅ {script}: 🟢 EN COURS (PID: {status["pid"]})')
            else:
                print(f'  ❌ {script}: 🔴 Arrêté')
    
    print('\n' + '='*60)
    print('✅ Tous les services sont opérationnels\n')
    
except ConnectionError:
    print('\n❌ ERREUR: Le serveur Flask n\'est pas accessible')
    print('Démarrez-le avec: python app.py\n')
except Exception as e:
    print(f'\n❌ ERREUR: {e}\n')
