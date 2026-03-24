#!/bin/bash
# ============================================================================
# Wrapper script - Démarrage VNC + Jupyter Lab
#Auteur: Marwa ZIDI
# ============================================================================
echo "=========================================="
echo "DEBUT DU SCRIPT - $(date)"
echo "=========================================="
set -e

# ============================================================================
# CRÉATION DU LIEN SYMBOLIQUE POUR /data
# ============================================================================
echo "🔗 Création du lien symbolique pour /data..."
cd /root
if [ ! -L "data" ] && [ -d "/data" ]; then
    ln -s /data data
    echo "✅ Lien symbolique créé: /root/data -> /data"
else
    echo "⚠️  Le lien symbolique existe déjà ou /data n'existe pas"
fi

# ============================================================================
# DÉMARRAGE VNC/IGV
# ============================================================================
echo "🖥️  Démarrage VNC/IGV..."
export DISPLAY=:1
Xvfb :1 -screen 0 1280x1024x24 &
sleep 2
fluxbox &
x11vnc -display :1 -rfbport 5900 -rfbauth /root/.vnc/passwd -forever -shared -bg
websockify --web=/usr/share/novnc 6080 localhost:5900 &
echo "VNC démarré sur le port 6080"
sleep 3

# ============================================================================
# DÉMARRAGE JUPYTER LAB SANS MOT DE PASSE
# ============================================================================
echo "📓 Lancement de Jupyter Lab SANS mot de passe..."
cd /root

# Lancer Jupyter SANS mot de passe
exec jupyter lab \
    --allow-root \
    --no-browser \
    --ip="0.0.0.0" \
    --port=8888 \
    --IdentityProvider.token="" \
    --ServerApp.password="" \
    --ServerApp.shutdown_no_activity_timeout=1200 \
    --MappingKernelManager.cull_idle_timeout=1200 \
    --TerminalManager.cull_inactive_timeout=1200
