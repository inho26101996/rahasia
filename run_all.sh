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

# Flags untuk menandakan status instalasi
PYTHON_INSTALLED=false
NODEJS_INSTALLED=false
SOLANA_INSTALLED=false
EXPECT_INSTALLED=false

# Periksa dan instal dependensi Python jika belum ada
if ! $PYTHON_INSTALLED; then
    if ! command -v python3 &> /dev/null || ! command -v pip3 &> /dev/null; then
        echo "$(date) - Python3 atau pip belum terinstal. Memulai instalasi..." >> log.txt
        sudo apt update
        sudo apt install -y python3 python3-pip
        if [ "$?" -eq "0" ]; then
            echo "$(date) - Python3 dan pip berhasil terinstal." >> log.txt
            PYTHON_INSTALLED=true
        else
            echo "$(date) - Instalasi Python3 atau pip gagal." >> log.txt
        fi
    else
        echo "$(date) - Python3 dan pip sudah terdeteksi." >> log.txt
        PYTHON_INSTALLED=true
    fi
fi

# Periksa dan instal python3-venv jika belum ada
if ! dpkg -s python3-venv &> /dev/null; then
    echo "$(date) - python3-venv belum terinstal. Memulai instalasi..." >> log.txt
    sudo apt update
    sudo apt install -y python3-venv
    echo "$(date) - python3-venv berhasil terinstal." >> log.txt
fi

# Periksa dan instal dependensi Node.js jika belum ada
if ! $NODEJS_INSTALLED; then
    if ! command -v npm &> /dev/null; then
        echo "$(date) - npm belum terinstal. Memulai instalasi..." >> log.txt
        sudo apt update
        sudo apt install -y npm
        if [ "$?" -eq "0" ]; then
            echo "$(date) - npm berhasil terinstal." >> log.txt
            NODEJS_INSTALLED=true
        else
            echo "$(date) - Instalasi npm gagal." >> log.txt
        fi
    else
        echo "$(date) - npm sudah terdeteksi." >> log.txt
        NODEJS_INSTALLED=true
    fi
fi

# Instalasi Solana CLI menggunakan perintah resmi terbaru dari website dengan versi spesifik
if ! $SOLANA_INSTALLED; then
    if ! command -v solana &> /dev/null; then
        echo "$(date) - Solana CLI belum terinstal. Memulai instalasi menggunakan skrip resmi versi v2.1.16..." >> log.txt
        sudo apt update
        sudo apt install -y curl
        if sh -c "$(curl -sSfL https://release.anza.xyz/v2.1.16/install)"; then
            echo "$(date) - Solana CLI berhasil terinstal." >> log.txt
            echo "$(date) - Pastikan Anda telah memperbarui PATH environment variable Anda sesuai dengan petunjuk installer Solana." >> log.txt
            SOLANA_INSTALLED=true
        else
            echo "$(date) - Instalasi Solana CLI gagal." >> log.txt
        fi
    else
        echo "$(date) - Solana CLI sudah terdeteksi." >> log.txt
        SOLANA_INSTALLED=true
    fi
fi

# Periksa dan instal expect jika belum ada
if ! $EXPECT_INSTALLED; then
    if ! command -v expect &> /dev/null; then
        echo "$(date) - expect belum terinstal. Memulai instalasi..." >> log.txt
        sudo apt update
        sudo apt install -y expect
        if [ "$?" -eq "0" ]; then
            echo "$(date) - expect berhasil terinstal." >> log.txt
            EXPECT_INSTALLED=true
        else
            echo "$(date) - Instalasi expect gagal." >> log.txt
        fi
    else
        echo "$(date) - expect sudah terdeteksi." >> log.txt
        EXPECT_INSTALLED=true
    fi
fi

# Berikan akses penuh ke semua skrip .sh di direktori saat ini
chmod 777 *.sh

while true; do
    echo "$(date) - Memulai iterasi baru" >> log.txt

    # Periksa keberadaan venv sebelum membuatnya
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        if [ "$?" -ne "0" ]; then
            echo "$(date) - Gagal membuat virtual environment. Script berhenti." >> log.txt
            exit 1
        fi
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
