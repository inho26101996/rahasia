#!/usr/bin/expect -f

exp_internal 0

set BASE_PATH "m/44'/501'/"
set TIMEOUT 30

# Fungsi untuk Menampilkan Seed Phrase Singkat (Hanya 3 Kata Pertama)
proc simplify_seed_phrase {seed_phrase} {
    set words [split $seed_phrase " "]
    return "[lindex $words 0] [lindex $words 1] [lindex $words 2] ..."
}

# Membaca Seed Phrases dari File seed_phrase.txt
puts "?? Membaca seed phrases dari file seed_phrase.txt..."
if {[file exists "seed_phrase.txt"]} {
    set file [open "seed_phrase.txt" r]
    set file_content [read $file]
    close $file
    set SEED_PHRASES [split $file_content "\n"]
    puts "? Seed phrases berhasil dibaca."
} else {
    puts "? Error: File seed_phrase.txt tidak ditemukan."
    exit 1
}

# Loop untuk Setiap Seed Phrase
foreach SEED_PHRASE $SEED_PHRASES {
    set SEED_PHRASE [string trim $SEED_PHRASE]
    if {$SEED_PHRASE eq ""} { continue }

    set OUTPUT_FILE [string map {" " "_"} $SEED_PHRASE].txt
    set SHORT_SEED [simplify_seed_phrase $SEED_PHRASE]

    puts "\n--- Memproses Seed Phrase: ($SHORT_SEED) ---"
    puts "?? Output file: $OUTPUT_FILE"

    # Menentukan jumlah akun acak antara 80 dan 110
    set ACCOUNT_COUNT [expr {int(rand() * (110 - 80 + 1)) + 80}]

    for {set i 0} {$i < $ACCOUNT_COUNT} {incr i} {
        set ACCOUNT_INDEX "${i}'"
        set DERIVATION_PATH "${BASE_PATH}${ACCOUNT_INDEX}/0'"

        puts "\n--- Akun ke-($i) ---"
        puts "?? Derivation Path : ($DERIVATION_PATH)"
        puts "?? Seed Phrase      : ($SHORT_SEED)"

        # Jalankan solana-keygen secara diam-diam
        log_user 0
        spawn solana-keygen recover -f -o /tmp/temp_wallet.json prompt://?full-path=$DERIVATION_PATH
        send "$SEED_PHRASE\n"

        # Lewati Prompt Passphrase
        expect {
            -timeout $TIMEOUT
            "If this seed phrase has an associated passphrase, enter it now. Otherwise, press ENTER to continue:" {
                send "\n"
            }
            timeout {
                puts "? Timeout saat menunggu prompt Passphrase."
                exit 1
            }
        }

        # Lewati Konfirmasi Public Key
        expect {
            -timeout $TIMEOUT
            "Recovered pubkey" {}
            timeout {
                puts "? Timeout saat menunggu konfirmasi pubkey."
                exit 1
            }
        }

        # Konfirmasi untuk Melanjutkan
        expect {
            -timeout $TIMEOUT
            "Continue? (y/n):" {
                send "y\n"
            }
            eof {}
            timeout {
                puts "? Timeout saat menunggu prompt Continue."
                exit 1
            }
        }

        after 1000
        log_user 1

        # Membaca dan Menyimpan Private Key
        set file [open "/tmp/temp_wallet.json" r]
        set PRIVKEY_RAW [string trim [read $file]]
        close $file
        set outfile [open "$OUTPUT_FILE" a]
        puts $outfile "$PRIVKEY_RAW"
        close $outfile
        exec rm /tmp/temp_wallet.json

        puts "? Raw Private Key : tersimpan"
    }
    puts "? Successfully generated raw private keys for seed phrase: ($SHORT_SEED)"
}

puts "\n?? Selesai."