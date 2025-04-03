#!/bin/bash
	set -e
	set -o pipefail

	BASE_ARCHIVE_DIR="$HOME/dripster/backup"
	ERROR_DIR="Error"
	LOG_FILE="log.txt"
	MAX_LOG_SIZE=102400  # 100KB
	MAX_ERROR_RETRIES=5
	error_count=0

	get_next_archive_number() {
	    local i=1
	    while [ -d "${BASE_ARCHIVE_DIR}/${i}" ]
	    do
		i=$((i+1))
	    done
	    echo "$i"
	}

	# Fungsi untuk membatasi ukuran log
	limit_log_size() {
	    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt $MAX_LOG_SIZE ]; then
		tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp"
		mv "$LOG_FILE.tmp" "$LOG_FILE"
	    fi
	}

	# Fungsi untuk menangani Ctrl+C (interupsi)
	cleanup_and_exit() {
	    echo "$(date) - Interupsi (Ctrl+C) diterima. Memindahkan file ke folder error bernomor..." >> "$LOG_FILE"

	    # Buat folder error jika belum ada
	    mkdir -p "$ERROR_DIR"

	    # Buat folder error bernomor
	    local error_folder_number=1
	    while [ -d "$ERROR_DIR/$error_folder_number" ]; do
		error_folder_number=$((error_folder_number + 1))
	    done
	    mkdir -p "$ERROR_DIR/$error_folder_number"

	    # Pindahkan semua file .txt dan .log kecuali requirements.txt
	    for file in *.txt; do
		if [ "$file" != "requirements.txt" ]; then
		    mv "$file" "$ERROR_DIR/$error_folder_number/" 2>/dev/null || true
		fi
	    done
	    mv *.log "$ERROR_DIR/$error_folder_number/" 2>/dev/null || true

	    echo "$(date) - Menghentikan skrip." >> "$LOG_FILE"
	    exit 1
	}
	trap cleanup_and_exit INT

	# Fungsi untuk menangani error
	handle_error() {
	    local error_message="$1"
	    echo "$(date) - TERJADI ERROR: $error_message" >> "$LOG_FILE"
	    echo "$(date) - Memindahkan file ke folder error bernomor..." >> "$LOG_FILE"

	    # Buat folder error jika belum ada
	    mkdir -p "$ERROR_DIR"

	    # Buat folder error bernomor
	    local error_folder_number=1
	    while [ -d "$ERROR_DIR/$error_folder_number" ]; do
		error_folder_number=$((error_folder_number + 1))
	    done
	    mkdir -p "$ERROR_DIR/$error_folder_number"

	    # Pindahkan semua file .txt dan .log kecuali requirements.txt
	    for file in *.txt; do
		if [ "$file" != "requirements.txt" ]; then
		    mv "$file" "$ERROR_DIR/$error_folder_number/" 2>/dev/null || true
		fi
	    done
	    mv *.log "$ERROR_DIR/$error_folder_number/" 2>/dev/null || true

	    error_count=$((error_count + 1))
	    echo "$(date) - Jumlah error berturut-turut: $error_count / $MAX_ERROR_RETRIES" >> "$LOG_FILE"

	    if [ "$error_count" -lt "$MAX_ERROR_RETRIES" ]; then
		echo "$(date) - Menunggu 5 detik sebelum mencoba lagi..." >> "$LOG_FILE"
		sleep 5
		echo "$(date) - Memulai ulang skrip dari awal..." >> "$LOG_FILE"
		# Reset virtual environment
		deactivate 2>/dev/null || true
		rm -rf venv 2>/dev/null || true
		./"$0" # Jalankan kembali skrip dari awal
		exit 0 # Pastikan instance saat ini keluar
	    else
		echo "$(date) - Batas maksimum percobaan ulang ($MAX_ERROR_RETRIES) tercapai. Menghentikan skrip." >> "$LOG_FILE"
		exit 1
	    fi
	}
	trap 'handle_error "$?"' ERR # Tangkap exit status bukan pesan error langsung

	# **Pastikan folder backup ada**
	mkdir -p "${BASE_ARCHIVE_DIR}"

	# **Atur chmod 777 di awal untuk semua script**
	chmod 777 *.sh *.py

	# **Instalasi Semua Dependensi Sistem di Awal**
	echo "$(date) - Memulai instalasi dependensi sistem..." >> "$LOG_FILE"
	sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv npm expect
	echo "$(date) - Instalasi dependensi sistem selesai." >> "$LOG_FILE"

	# **Setup Virtual Environment (venv)**
	if [ ! -d "venv" ]; then
	    python3 -m venv venv
	    echo "$(date) - Virtual environment dibuat." >> "$LOG_FILE"
	fi

	# **Aktifkan Virtual Environment**
	source venv/bin/activate

	# **Instalasi Dependensi Python Setelah Aktivasi venv**
	if [ ! -f ".venv_installed" ]; then
	    echo "$(date) - Menginstal dependensi Python di dalam venv..." >> "$LOG_FILE"
	    while IFS= read -r package; do
		echo "$(date) - Mencoba menginstal $package..." >> "$LOG_FILE"
		pip install --ignore-installed --no-deps "$package" || echo "$(date) - Gagal menginstal $package. Melanjutkan..." >> "$LOG_FILE"
	    done < requirements.txt
	    touch .venv_installed
	    echo "$(date) - Proses instalasi dependensi Python di dalam venv selesai (beberapa mungkin gagal)." >> "$LOG_FILE"
	fi

	# **Jalankan npm install sekali di awal jika perlu**
	if [ -f package.json ] && [ ! -d node_modules ]; then
	    echo "$(date) - Menginstal dependensi Node.js..." >> "$LOG_FILE"
	    npm install
	    echo "$(date) - Dependensi Node.js diinstal." >> "$LOG_FILE"
	fi

	echo "$(date) - Semua dependensi sudah siap. Memulai eksekusi loop..." >> "$LOG_FILE"

	# **Mulai Looping Tanpa Pengecekan Ulang Dependensi**
	while true; do
	    limit_log_size
	    echo "$(date) - Memulai iterasi baru" >> "$LOG_FILE"

	    python create_wallet.py
	    echo "$(date) - Dompet dibuat" >> "$LOG_FILE"

	    python seed_to_pk.py
	    echo "$(date) - Seed phrase dikonversi" >> "$LOG_FILE"

	    node merge_keys.js
	    echo "$(date) - Kunci privat digabungkan" >> "$LOG_FILE"

	    node dripster.js
	    echo "$(date) - Dripster selesai dijalankan" >> "$LOG_FILE"

	    # **Buat Backup**
	    ARCHIVE_NUMBER=$(get_next_archive_number)
	    ARCHIVE_FOLDER="${BASE_ARCHIVE_DIR}/${ARCHIVE_NUMBER}"
	    mkdir -p "${ARCHIVE_FOLDER}"
	    echo "$(date) - Menyimpan file ke ${ARCHIVE_FOLDER}" >> "$LOG_FILE"

	    # **Pindahkan File Sesuai Backup yang Sudah Ada**
	    if [ -f seeds.txt ]
	    then
		while IFS= read -r line; do
		    filename="${line// /_}.txt"
		    if [ -f "$filename" ]; then
		        mv "$filename" "${ARCHIVE_FOLDER}/"
		    fi
		done < seeds.txt
		mv seeds.txt "${ARCHIVE_FOLDER}/" 2>/dev/null # Baru pindahkan seeds.txt
	    fi
	    if [ -f pk.txt ]
	    then
		mv pk.txt "${ARCHIVE_FOLDER}/" 2>/dev/null
	    fi

	    echo "$(date) - Iterasi selesai. Mengulang dalam 60 detik..." >> "$LOG_FILE"
	    sleep 60
	done
