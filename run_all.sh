#!/bin/bash
set -e
set -o pipefail

BASE_ARCHIVE_DIR="/root/dripster/backup"
ANZA_VERSION="v2.2.3"
ANZA_URL="https://github.com/anza-xyz/agave/releases/download/${ANZA_VERSION}/solana-release-x86_64-unknown-linux-gnu.tar.bz2"
INSTALL_DIR="$HOME/.local/share/solana/install"

get_next_archive_number() {
    local i=1
    while [ -d "${BASE_ARCHIVE_DIR}/${i}" ]; do
        i=$((i+1))
    done
    echo "$i"
}

trap "echo 'Penghentian manual oleh pengguna.'; exit 130" INT

mkdir -p "${BASE_ARCHIVE_DIR}"
chmod 777 *.sh

# **Cek & Install python3, python3-venv, dan Node.js jika belum ada**
if ! command -v python3 &>/dev/null; then
    sudo apt-get update && sudo apt-get install -y python3 python3-pip
fi

if ! dpkg -s python3-venv &>/dev/null; then
    sudo apt-get install -y python3-venv
fi

if ! command -v npm &>/dev/null; then
    sudo apt-get install -y npm
fi

# **Cek & Install Solana CLI (Anza) langsung dari GitHub**
if ! command -v solana &>/dev/null; then
    echo "$(date) - Solana CLI tidak ditemukan. Mengunduh dari GitHub..." >> log.txt
    mkdir -p "$INSTALL_DIR"
    wget -O /tmp/solana-release.tar.bz2 "$ANZA_URL"
    tar -xjf /tmp/solana-release.tar.bz2 -C "$INSTALL_DIR"
    mv "$INSTALL_DIR"/solana-release/* "$INSTALL_DIR/active_release/"
    rm -rf "$INSTALL_DIR"/solana-release
    export PATH="$INSTALL_DIR/active_release/bin:$PATH"
    echo 'export PATH="$INSTALL_DIR/active_release/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    rm /tmp/solana-release.tar.bz2
fi

# **Setup Virtual Environment (venv)**
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

if [ ! -f ".venv_installed" ]; then
    pip install -r requirements.txt
    touch .venv_installed
fi

if [ -f package.json ] && [ ! -d node_modules ]; then
    npm install
fi

while true; do
    python create_wallet.py
    ./seed_to_rpk.sh
    python pkbase58.py
    node merge_keys.js
    node dripster.js

    ARCHIVE_NUMBER=$(get_next_archive_number)
    ARCHIVE_FOLDER="${BASE_ARCHIVE_DIR}/${ARCHIVE_NUMBER}"
    mkdir -p "${ARCHIVE_FOLDER}"

    if [ -f seed_phrase.txt ]; then
        while IFS= read -r line; do
            filename="${line// /_}.txt"
            if [ -f "$filename" ]; then
                mv "$filename" "${ARCHIVE_FOLDER}/"
            fi
        done < seed_phrase.txt
    fi

    mv seed_phrase.txt pk.txt "${ARCHIVE_FOLDER}/" 2>/dev/null || true
    logsize=$(du -k "log.txt" | cut -f1)
    if [ "$logsize" -gt 5000 ]; then
        mv log.txt "log_$(date +%F_%T).txt"
        echo "$(date) - Log dirotasi karena ukuran terlalu besar." > log.txt
    fi

    sleep 60
done
