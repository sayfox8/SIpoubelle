#include <Servo.h>

/**
 * PROJET : Poubelle Intelligente SI
 * DESCRIPTION : Contrôle d'un plateau double axe pour le tri automatique.
 * CONFIGURATION DES BACS : 
 * - Marron : 30°  | Bascule vers le HAUT (Sens 0°)
 * - Jaune  : 120° | Bascule vers le HAUT (Sens 0°)
 * - Vert   : 90°  | Bascule vers le BAS  (Sens 180°)
 */

// Définition des servos
Servo servoOrientation; 
Servo servoBascule;     

// Configuration des broches
const int PIN_ORIENT = 10;
const int PIN_BASCULE = 9;

// Paramètres de position
const int POS_REPOS = 90;       
const int ANGLE_MARRON = 30;    
const int ANGLE_JAUNE = 150;     
const int ANGLE_VERT = 90;      

// Seuils d'inclinaison
const int VIDAGE_HAUT = 20;  // Inclinaison vers le haut (proche de 0)
const int VIDAGE_BAS = 160;  // Inclinaison vers le bas (proche de 180)

void setup() {
  Serial.begin(9600);
  
  servoOrientation.attach(PIN_ORIENT);
  servoBascule.attach(PIN_BASCULE);
  
  // Initialisation à plat
  servoOrientation.write(POS_REPOS);
  servoBascule.write(POS_REPOS);
  
  Serial.println("Systeme de Tri Maj (Haut/Bas) - Pret");
}

void loop() {
  if (Serial.available() > 0) {
    String commande = Serial.readStringUntil('\n');
    commande.trim();

    if (commande == "marron") {
      // Marron : 30°, Bascule vers le HAUT (direction = 0)
      executerSequenceTri(ANGLE_MARRON, "MARRON", 0);
    } 
    else if (commande == "jaune") {
      // Jaune : 120°, Bascule vers le HAUT (direction = 0)
      executerSequenceTri(ANGLE_JAUNE, "JAUNE", 0);
    }
    else if (commande == "verte") {
      // Vert : 90°, Bascule vers le BAS (direction = 1)
      executerSequenceTri(ANGLE_VERT, "VERT", 1);
    }
  }
}

/**
 * @param angleCible : Angle de rotation du plateau
 * @param nomBac : Nom pour le debug console
 * @param directionBascule : 0 pour HAUT (vers 0°), 1 pour BAS (vers 180°)
 */
void executerSequenceTri(int angleCible, String nomBac, int directionBascule) {
  Serial.print("Cible : "); Serial.print(nomBac);
  
  int angleVidage = (directionBascule == 0) ? VIDAGE_HAUT : VIDAGE_BAS;

  // 1. ORIENTATION
  servoOrientation.write(angleCible);
  delay(1000); 

  // 2. VIDAGE
  servoBascule.write(angleVidage);
  delay(600);

  // 3. VIBRATIONS
  for (int i = 0; i < 4; i++) {
    // On secoue en revenant légèrement vers le repos
    if (directionBascule == 0) {
      servoBascule.write(angleVidage + 20); // Remonte un peu vers 90
    } else {
      servoBascule.write(angleVidage - 20); // Remonte un peu vers 90
    }
    delay(150);
    servoBascule.write(angleVidage);
    delay(150);
  }

  // 4. RETOUR AU REPOS
  delay(400);
  servoBascule.write(POS_REPOS); 
  delay(500);
  servoOrientation.write(POS_REPOS); 
  
  Serial.println(" -> Tri termine.");
}