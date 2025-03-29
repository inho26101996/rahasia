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

# **Cek Arsitektur CPU**
ARCH=$(uname -m)
echo "$(date) - Arsitektur sistem: $ARCH" >> log.txt

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

    if [[ "$ARCH" == "aarch64" ]]; then
        echo "$(date) - Sistem menggunakan ARM (aarch64), mengompilasi Solana dari source..." >> log.txt
        sudo apt-get install -y curl git build-essential pkg-config libssl-dev clang cmake
        git clone https://github.com/solana-labs/solana.git
        cd solana
        ./scripts/cargo-install-all.sh .
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
        cd ..
    else
        curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
    fi
fi

# **Cek & Install Anza CLI (Agave)**
if ! command -v anza &>/dev/null; then
    echo "$(date) - Anza CLI tidak ditemukan. Menginstal..." >> log.txt

    if [[ "$ARCH" == "aarch64" ]]; then
        echo "$(date) - Sistem menggunakan ARM (aarch64), mengompilasi Anza dari source..." >> log.txt
        sudo apt-get install -y curl git clang cmake make pkg-config libssl-dev
        git clone https://github.com/anza-xyz/agave.git
        cd agave
        cargo build --release
        export PATH="$HOME/agave/target/release:$PATH"
        echo 'export PATH="$HOME/agave/target/release:$PATH"' >> ~/.bashrc
        source ~/.bashrc
        cd ..
    else
        curl -sSfL https://release.anza.xyz/stable/agave-install-init | bash
        export PATH="$HOME/.local/share/anza/install/active_release/bin:$PATH"
        echo 'export PATH="$HOME/.local/share/anza/install/active_release/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
    fi
fi

# **Setup Virtual Environment (venv) hanya di awal**
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# **Aktifkan Virtual Environment**
source venv/bin/activate

# **Pastikan pip install hanya dijalankan sekali**
if [ ! -f ".venv_installed" ]; then
    echo "$(date) - Menginstal dependensi Python..." >> log.txt
    pip install -r requirements.txt
    touch .venv_installed
fi

# **Jalankan npm install sekali di awal jika perlu**
if [ -f package.json ] && [ ! -d node_modules ]; then
    echo "$(date) - Menginstal dependensi Node.js..." >> log.txt
    npm install
fi

echo "$(date) - Semua dependensi sudah siap. Memulai eksekusi loop..." >> log.txt

# **Mulai Looping Tanpa Pengecekan Ulang Dependensi**
while true; do
    echo "$(date) - Memulai iterasi baru" >> log.txt

    python create_wallet.py
    echo "$(date) - Dompet dibuat" >> log.txt

    ./seed_to_rpk.sh
    echo "$(date) - Seed phrase dikonversi" >> log.txt

    python pkbase58.py
    echo "$(date) - Kunci privat dikonversi" >> log.txt

    node merge_keys.js
    echo "$(date) - Kunci privat digabungkan" >> log.txt

    node dripster.js
    echo "$(date) - Dripster selesai dijalankan" >> log.txt

    # **Buat Backup**
    ARCHIVE_NUMBER=$(get_next_archive_number)
    ARCHIVE_FOLDER="${BASE_ARCHIVE_DIR}/${ARCHIVE_NUMBER}"
    mkdir -p "${ARCHIVE_FOLDER}"

    # **Pindahkan File Sesuai Backup yang Sudah Ada**
    if [ -f seed_phrase.txt ]; then
        while IFS= read -r line; do
            filename="${line// /_}.txt"
            if [ -f "$filename" ]; then
                mv "$filename" "${ARCHIVE_FOLDER}/"
            fi
        done < seed_phrase.txt
    fi

    if [ -f seed_phrase.txt ]; then
        mv seed_phrase.txt "${ARCHIVE_FOLDER}/"
    fi
    if [ -f pk.txt ]; then
        mv pk.txt "${ARCHIVE_FOLDER}/"
    fi

    # **Rotasi Log Jika Terlalu Besar (Mencegah File Membengkak)**
    logsize=$(du -k "log.txt" | cut -f1)
    if [ "$logsize" -gt 5000 ]; then
        mv log.txt "log_$(date +%F_%T).txt"
        echo "$(date) - Log dirotasi karena ukuran terlalu besar." > log.txt
    fi

    echo "$(date) - Iterasi selesai. Mengulang dalam 60 detik..." >> log.txt
    sleep 60
done
