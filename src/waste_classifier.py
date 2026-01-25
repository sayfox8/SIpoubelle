"""
Smart Bin SI - Système de Classification des Déchets
Contrôleur principal pour le tri manuel avec apprentissage en base de données
"""

import serial
import sqlite3
import time
import sys

# ============================================
# CONFIGURATION
# ============================================

# Configuration du port série (vérifier avec 'ls /dev/ttyACM*')
SERIAL_PORT = '/dev/ttyACM0'
BAUD_RATE = 9600
SERIAL_TIMEOUT = 1

# Configuration de la base de données
DB_NAME = 'waste_items.db'

# Couleurs de bacs disponibles
VALID_BINS = ["yellow", "green", "brown"]

# Durée du mouvement de tri (secondes)
SORTING_DURATION = 10


# ============================================
# CONNEXION ARDUINO
# ============================================

def init_serial_connection():
    """
    Initialise la connexion avec l'Arduino
    Retourne: objet serial ou None si échec
    """
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=SERIAL_TIMEOUT)
        time.sleep(2)  # Attendre l'initialisation de l'Arduino
        print("✓ Succès : Connecté à l'Arduino")
        return ser
    except Exception as e:
        print(f"⚠ Note : Mode simulation (Arduino non détecté sur {SERIAL_PORT})")
        print(f"   Erreur : {e}")
        return None


# ============================================
# GESTION DE LA BASE DE DONNÉES
# ============================================

def init_database():
    """
    Initialise la base de données SQLite avec les tables requises
    Retourne: objets connection et cursor
    """
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    # Créer la table principale de classification
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS waste_classification (
            item_name TEXT PRIMARY KEY,
            bin_color TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            usage_count INTEGER DEFAULT 1
        )
    ''')
    
    connection.commit()
    print(f"✓ Base de données initialisée : {DB_NAME}")
    return connection, cursor


def get_or_assign_bin_color(cursor, connection, item_name):
    """
    Vérifie si l'objet existe en base, sinon demande à l'utilisateur d'assigner la couleur
    
    Args:
        cursor: Curseur de la base de données
        connection: Connexion à la base de données
        item_name: Nom de l'objet détecté
    
    Retourne:
        str: Couleur du bac (yellow/green/brown) ou None si annulé
    """
    # Chercher dans la base de données
    cursor.execute(
        "SELECT bin_color FROM waste_classification WHERE item_name = ?",
        (item_name.lower(),)
    )
    result = cursor.fetchone()
    
    if result:
        # Objet trouvé dans la base
        bin_color = result[0]
        print(f"✓ Trouvé en base : {item_name} → bac {bin_color}")
        
        # Incrémenter le compteur d'utilisation
        cursor.execute(
            "UPDATE waste_classification SET usage_count = usage_count + 1 WHERE item_name = ?",
            (item_name.lower(),)
        )
        connection.commit()
        
        return bin_color
    
    else:
        # Nouvel objet - demander à l'utilisateur
        print(f"\n[NOUVEL OBJET DÉTECTÉ : '{item_name}']")
        print("Dans quel bac doit aller cet objet ?")
        print("  - yellow  (recyclable : plastique, carton, métal)")
        print("  - green   (organique : déchets alimentaires, biodégradable)")
        print("  - brown   (déchets généraux : non recyclable)")
        
        while True:
            user_choice = input("Entrer la couleur du bac (yellow/green/brown) ou 'skip' : ").strip().lower()
            
            if user_choice == 'skip':
                print("⊘ Classification ignorée")
                return None
            
            if user_choice in VALID_BINS:
                # Sauvegarder la nouvelle classification
                cursor.execute(
                    "INSERT INTO waste_classification (item_name, bin_color) VALUES (?, ?)",
                    (item_name.lower(), user_choice)
                )
                connection.commit()
                print(f"✓ Sauvegardé : {item_name} → bac {user_choice}")
                return user_choice
            
            print(f"✗ Erreur : Veuillez choisir 'yellow', 'green' ou 'brown'")


# ============================================
# CONTRÔLE MATÉRIEL
# ============================================

def send_sorting_command(serial_connection, bin_color):
    """
    Envoie une commande de tri à l'Arduino et attend la fin
    
    Args:
        serial_connection: Connexion série active (ou None pour simulation)
        bin_color: Couleur du bac cible (yellow/green/brown)
    """
    if serial_connection:
        try:
            # Envoyer la commande via série
            command = f"{bin_color}\n"
            serial_connection.write(command.encode())
            print(f"→ Commande envoyée à l'Arduino : {bin_color}")
            
            # Attendre la fin du mouvement de tri
            print(f"⏳ Attente de la fin du tri ({SORTING_DURATION}s)...")
            time.sleep(SORTING_DURATION)
            print("✓ Tri terminé")
            
        except Exception as e:
            print(f"✗ Erreur série : {e}")
    else:
        # Mode simulation
        print(f"[SIMULATION] L'Arduino trierait vers le bac {bin_color}")
        time.sleep(1)  # Court délai pour la simulation


# ============================================
# PROGRAMME PRINCIPAL
# ============================================

def main():
    """
    Boucle de contrôle principale pour le tri manuel
    """
    print("\n" + "="*50)
    print("🤖 SMART BIN SI - SYSTÈME DE CONTRÔLE MANUEL")
    print("="*50)
    print("Entrez les noms d'objets pour simuler une détection")
    print("Tapez 'quit' pour quitter")
    print("Tapez 'stats' pour voir les statistiques")
    print("="*50 + "\n")
    
    # Initialiser la connexion matérielle
    serial_conn = init_serial_connection()
    
    # Initialiser la base de données
    db_connection, db_cursor = init_database()
    
    try:
        # Boucle de contrôle principale
        while True:
            # Obtenir l'entrée utilisateur
            user_input = input("\nObjet détecté > ").strip()
            
            # Gérer les commandes spéciales
            if user_input.lower() == 'quit':
                print("\n👋 Arrêt du système...")
                break
            
            if user_input.lower() == 'stats':
                show_database_stats(db_cursor)
                continue
            
            if not user_input:
                continue
            
            # Traiter la classification de l'objet
            print(f"\n🔍 Traitement : '{user_input}'")
            
            # Étape 1 : Obtenir ou assigner la couleur du bac
            bin_color = get_or_assign_bin_color(db_cursor, db_connection, user_input)
            
            if bin_color is None:
                continue  # L'utilisateur a ignoré la classification
            
            # Étape 2 : Envoyer la commande de tri physique
            print(f"🎯 Action de tri : {user_input} → bac {bin_color}")
            send_sorting_command(serial_conn, bin_color)
            
    except KeyboardInterrupt:
        print("\n\n⚠ Programme interrompu par l'utilisateur")
    
    finally:
        # Arrêt propre
        print("\n🔌 Fermeture des connexions...")
        
        if serial_conn:
            serial_conn.close()
            print("  ✓ Connexion série fermée")
        
        if db_connection:
            db_connection.close()
            print("  ✓ Connexion base de données fermée")
        
        print("\n✓ Arrêt système complet\n")


def show_database_stats(cursor):
    """
    Affiche les statistiques de la base de données
    
    Args:
        cursor: Curseur de la base de données
    """
    print("\n" + "="*50)
    print("📊 STATISTIQUES DE LA BASE DE DONNÉES")
    print("="*50)
    
    # Total d'objets
    cursor.execute("SELECT COUNT(*) FROM waste_classification")
    total_items = cursor.fetchone()[0]
    print(f"Total d'objets appris : {total_items}")
    
    # Répartition par bac
    for bin_color in VALID_BINS:
        cursor.execute(
            "SELECT COUNT(*), SUM(usage_count) FROM waste_classification WHERE bin_color = ?",
            (bin_color,)
        )
        count, total_usage = cursor.fetchone()
        total_usage = total_usage or 0
        print(f"  Bac {bin_color:8} : {count:3} objets ({total_usage:4} utilisations)")
    
    # Objets les plus triés
    print("\nTop 5 des objets les plus triés :")
    cursor.execute(
        "SELECT item_name, bin_color, usage_count FROM waste_classification ORDER BY usage_count DESC LIMIT 5"
    )
    for idx, (item, color, count) in enumerate(cursor.fetchall(), 1):
        print(f"  {idx}. {item:20} → {color:6} ({count} fois)")
    
    print("="*50)


# ============================================
# POINT D'ENTRÉE
# ============================================

if __name__ == "__main__":
    main()