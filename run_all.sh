#!/bin/bash
set -e

BASE_ARCHIVE_DIR="/root/dripster/backup"

get_next_archive_number() {
    local i=1
    while [ -d "${BASE_ARCHIVE_DIR}/${i}" ]; do
        i=$((i+1))
    done
    echo "$i"
}

# Fungsi untuk menangani Ctrl+C
trap "echo 'Penghentian manual oleh pengguna.'; exit 130" INT

# Buat folder backup jika belum ada
if [ ! -d "${BASE_ARCHIVE_DIR}" ]; then
    mkdir -p "${BASE_ARCHIVE_DIR}"
fi

# Fungsi untuk memeriksa dan menginstal dependensi Python
check_and_install_python() {
    if ! command -v python3 &> /dev/null; then
        echo "$(date) - Python3 tidak terinstal. Menginstal Python3..." >> log.txt
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
        echo "$(date) - Python3 dan pip terpasang." >> log.txt
    else
        echo "$(date) - Python3 sudah terinstal." >> log.txt
    fi
}

# Fungsi untuk memeriksa dan menginstal dependensi Node.js
check_and_install_nodejs() {
    if ! command -v npm &> /dev/null; then
        echo "$(date) - npm tidak terinstal. Menginstal npm..." >> log.txt
        # Sesuaikan perintah instalasi npm dengan sistem operasi Anda
        # Contoh untuk Debian/Ubuntu:
        sudo apt-get update
        sudo apt-get install -y npm
        echo "$(date) - npm terpasang." >> log.txt
    else
        echo "$(date) - npm sudah terinstal." >> log.txt
    fi
}

# Fungsi untuk memeriksa dan menginstal program expect
check_and_install_expect() {
    if ! command -v expect &> /dev/null; then
        echo "$(date) - expect tidak terinstal. Menginstal expect..." >> log.txt
        sudo apt-get update
        sudo apt-get install -y expect
        echo "$(date) - expect terpasang." >> log.txt
    else
        echo "$(date) - expect sudah terinstal." >> log.txt
    fi
}

# Instalasi dependensi di awal script
echo "$(date) - Memeriksa dan menginstal dependensi awal..." >> log.txt
check_and_install_python
check_and_install_nodejs
check_and_install_expect
echo "$(date) - Dependensi awal selesai diperiksa dan diinstal." >> log.txt

while true; do
    echo "$(date) - Memulai iterasi baru" >> log.txt

    # Berikan akses penuh ke semua skrip .sh di direktori saat ini
    chmod 777 *.sh

    # Periksa keberadaan venv sebelum membuatnya
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        echo "$(date) - Virtual environment dibuat." >> log.txt
    else
        echo "$(date) - Virtual environment sudah ada. Melewati pembuatan." >> log.txt
    fi

    source venv/bin/activate
    echo "$(date) - Virtual environment diaktifkan" >> log.txt

    pip install -r requirements.txt
    echo "$(date) - Dependensi Python terpasang" >> log.txt
    python create_wallet.py
    echo "$(date) - Dompet dibuat" >> log.txt
    ./seed_to_rpk.sh
    echo "$(date) - Seed phrase dikonversi" >> log.txt
    python pkbase58.py
    echo "$(date) - Kunci privat dikonversi" >> log.txt

    # Periksa dan instal dependensi Node.js dari package.json
    if [ -f package.json ]; then
        if [ ! -d node_modules ]; then
            echo "$(date) - Menginstal dependensi Node.js dari package.json..." >> log.txt
            npm install
            echo "$(date) - Dependensi Node.js terpasang." >> log.txt
        else
            echo "$(date) - Dependensi Node.js sudah terpasang." >> log.txt
        fi
    else
        echo "$(date) - package.json tidak ditemukan. Melewati instalasi dependensi Node.js." >> log.txt
    fi

    node merge_keys.js
    echo "$(date) - Kunci privat digabungkan" >> log.txt
    node dripster.js
    echo "$(date) - Dripster selesai dijalankan" >> log.txt

    ARCHIVE_NUMBER=$(get_next_archive_number)
    ARCHIVE_FOLDER="${BASE_ARCHIVE_DIR}/${ARCHIVE_NUMBER}"
    mkdir -p "${ARCHIVE_FOLDER}"
    echo "$(date) - Menyimpan file ke ${ARCHIVE_FOLDER}" >> log.txt

    # Pindahkan file berdasarkan seed phrase dari seed_phrase.txt terlebih dahulu
    if [ -f seed_phrase.txt ]; then
        while IFS= read -r line; do
            filename="${line// /_}.txt" # Ganti spasi dengan garis bawah
            if [ -f "$filename" ]; then
                mv "$filename" "${ARCHIVE_FOLDER}/"
            fi
        done < seed_phrase.txt
    fi

    # Pindahkan seed_phrase.txt dan pk.txt setelah file-file lain dipindahkan
    if [ -f seed_phrase.txt ]; then
        mv seed_phrase.txt "${ARCHIVE_FOLDER}/"
    fi
    if [ -f pk.txt ]; then
        mv pk.txt "${ARCHIVE_FOLDER}/"
    fi

    echo "$(date) - Iterasi selesai. Mengulang dalam 60 detik..." >> log.txt
    sleep 60
done
