#!/bin/bash
set -e
set -o pipefail

BASE_ARCHIVE_DIR="$HOME/dripster/backup"

get_next_archive_number() {
    local i=1
    while [ -d "${BASE_ARCHIVE_DIR}/${i}" ]; do
        i=$((i+1))
    done
    echo "$i"
}

trap "echo 'Penghentian manual oleh pengguna.'; exit 130" INT

# **Pastikan folder backup ada**
mkdir -p "${BASE_ARCHIVE_DIR}"

# **Atur chmod 777 di awal untuk semua script**
chmod 777 *.sh

# **Cek & Install python3, python3-venv, dan Node.js jika belum ada**
if ! command -v python3 &>/dev/null; then
    echo "$(date) - Python3 tidak ditemukan. Menginstal..." >> log.txt
    sudo apt-get update && sudo apt-get install -y python3 python3-pip
fi

if ! dpkg -s python3-venv &>/dev/null; then
    echo "$(date) - python3-venv tidak ditemukan. Menginstal..." >> log.txt
    sudo apt-get install -y python3-venv
fi

if ! command -v npm &>/dev/null; then
    echo "$(date) - npm tidak ditemukan. Menginstal..." >> log.txt
    sudo apt-get install -y npm
fi

# **Cek & Install Solana CLI dan Solana Keygen**
if ! command -v solana &>/dev/null || ! command -v solana-keygen &>/dev/null; then
    echo "$(date) - Solana CLI atau Solana Keygen tidak ditemukan. Menginstal..." >> log.txt
    curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
fi

# **Setup Virtual Environment (venv) hanya di awal**
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

#
