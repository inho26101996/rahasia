#!/bin/bash
set -e
set -o pipefail

BASE_ARCHIVE_DIR="$HOME/dripster/backup"

get_next_archive_number() {
    local i=1
    while [ -d "${BASE_ARCHIVE_DIR}/${i}" ]
    do
        i=$((i+1))
    done
    echo "$i"
}

trap "echo 'Penghentian manual oleh pengguna.'; exit 130" INT

# **Pastikan folder backup ada**
mkdir -p "${BASE_ARCHIVE_DIR}"

# **Atur chmod 777 di awal untuk semua script**
chmod 777 *.sh *.py

# **Instalasi Semua Dependensi Sistem di Awal**
echo "$(date) - Memulai instalasi dependensi sistem..." >> log.txt
sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv npm expect
echo "$(date) - Instalasi dependensi sistem selesai." >> log.txt

# **Setup Virtual Environment (venv)**
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "$(date) - Virtual environment dibuat." >> log.txt
fi

# **Aktifkan Virtual Environment**
source venv/bin/activate

# **Instalasi Dependensi Python Setelah Aktivasi venv**
if [ ! -f ".venv_installed" ]; then
    echo "$(date) - Menginstal dependensi Python di dalam venv..." >> log.txt
    pip install -r requirements.txt
    touch .venv_installed
    echo "$(date) - Dependensi Python di dalam venv diinstal." >> log.txt
fi

# **Jalankan npm install sekali di awal jika perlu**
if [ -f package.json ] && [ ! -d node_modules ]; then
    echo "$(date) - Menginstal dependensi Node.js..." >> log.txt
    npm install
    echo "$(date) - Dependensi Node.js diinstal." >> log.txt
fi

echo "$(date) - Semua dependensi sudah siap. Memulai eksekusi loop..." >> log.txt

# **Mulai Looping Tanpa Pengecekan Ulang Dependensi**
while true; do
    echo "$(date) - Memulai iterasi baru" >> log.txt

    python create_wallet.py
    echo "$(date) - Dompet dibuat" >> log.txt

    python seed_to_pk.py
    echo "$(date) - Seed phrase dikonversi" >> log.txt

    node merge_keys.js
    echo "$(date) - Kunci privat digabungkan" >> log.txt

    node dripster.js
    echo "$(date) - Dripster selesai dijalankan" >> log.txt

    # **Buat Backup**
    ARCHIVE_NUMBER=$(get_next_archive_number)
    ARCHIVE_FOLDER="${BASE_ARCHIVE_DIR}/${ARCHIVE_NUMBER}"
    mkdir -p "${ARCHIVE_FOLDER}"

    # **Pindahkan File Sesuai Backup yang Sudah Ada**
    if [ -f seed_phrase.txt ]
    then
        while IFS= read -r line; do
            filename="${line// /_}.txt"
            if [ -f "$filename" ]; then
                mv "$filename" "${ARCHIVE_FOLDER}/"
            fi
        done < seed_phrase.txt
    fi

    if [ -f seed_phrase.txt ]
    then
        mv seed_phrase.txt "${ARCHIVE_FOLDER}/"
    fi
    if [ -f pk.txt ]
    then
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
