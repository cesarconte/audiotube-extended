#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# Autonomous installer for audiotube-extended (Golden Gate / CachyOS.UI)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "=================================================="
echo "  Instalador de AudioTube Extended (CachyOS.UI)   "
echo "=================================================="

# 1. Configurar build con CMake apuntando a /usr
echo "==> Configurando CMake (prefix=/usr)..."
cmake -B "${BUILD_DIR}" -S "${SCRIPT_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr

# 2. Compilar
echo "==> Compilando AudioTube Extended..."
cmake --build "${BUILD_DIR}" -j"$(nproc)"

# 3. Instalar en /usr (Política estricta del sistema, prohibido ~/.local)
echo "==> Instalando en /usr..."
if [ "$EUID" -eq 0 ]; then
    cmake --install "${BUILD_DIR}" --prefix /usr
else
    sudo -n cmake --install "${BUILD_DIR}" --prefix /usr
fi

# 4. Actualizar cachés del sistema
echo "==> Actualizando cachés de escritorio e iconos..."
if command -v update-desktop-database >/dev/null 2>&1; then
    sudo -n update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    sudo -n gtk-update-icon-cache -qtf /usr/share/icons/hicolor || true
fi

echo "=================================================="
echo "  ✓ AudioTube Extended instalado con éxito en /usr"
echo "=================================================="
