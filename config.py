
"""
Message Queuing Telemetry Transport (MQTT) Configuration - MQTT is a lightweight messaging protocol that provides resource-constrained network 
clients with a simple way to distribute telemetry information in low-bandwidth environments.
"""
# Thresholds
EAR_THRESHOLD = 0.25 # Eye Aspect Ratio (EAR) threshold
EAR_CONSEC_FRAMES = 20 # Number of consecutive frames the EAR should be below the threshold to trigger an alert.

# Paths
PREDICTOR_PATH = 'resources/shape_predictor_68_face_landmarks.dat'
ALERT_SOUND_PATH = 'resources/alert.wav'

# MQTT Configuration
MQTT_BROKER_ADDRESS = 'broker.hivemq.com'
MQTT_BROKER_PORT = 1883
MQTT_TOPIC = 'driver/drowsiness'
MQTT_CLIENT_ID = 'DrowsinessDetectorClient'
