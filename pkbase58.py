from solders.keypair import Keypair
import base58
import os

def convert_raw_key_to_base58(raw_key_str):
    """Mengonversi raw private key (string) ke Base58."""
    raw_key_str = raw_key_str.strip()  # Hapus spasi di awal dan akhir
    raw_key_str = raw_key_str.replace('[', '').replace(']', '')  # Hapus kurung siku
    raw_key_list = [int(x.strip()) for x in raw_key_str.split(',')]
    keypair = Keypair.from_bytes(raw_key_list)
    private_key_bytes = keypair.to_bytes()
    return base58.b58encode(private_key_bytes).decode()

def process_seed_file(seed_file):
    """Membaca nama seed phrase dari file seed_phrase.txt dan memproses setiap file."""
    with open(seed_file, 'r') as f:
        for line in f:
            seed_phrase = line.strip()
            if seed_phrase:
                # Membuat nama file input dari seed phrase
                input_filename = seed_phrase.replace(' ', '_') + '.txt'
                convert_raw_keys_and_replace_file(input_filename) # Memanggil fungsi baru

def convert_raw_keys_and_replace_file(input_file):
    """Membaca raw private key dari file, mengonversi, dan mengganti file input dengan hasil konversi."""
    try:
        base58_keys = []
        with open(input_file, 'r') as infile:
            for line in infile:
                raw_key = line.strip()
                if raw_key:
                    base58_key = convert_raw_key_to_base58(raw_key)
                    base58_keys.append(base58_key)
        # Menulis hasil konversi kembali ke file input, mengganti isinya
        with open(input_file, 'w') as outfile:
            for base58_key in base58_keys:
                outfile.write(base58_key + '\n')
        print(f"Raw private keys dari {input_file} telah dikonversi dan menggantikan file asli.")
    except FileNotFoundError:
        print(f"File tidak ditemukan: {input_file}")

# Contoh penggunaan
seed_file = 'seed_phrase.txt'  # Nama file yang berisi daftar seed phrase
process_seed_file(seed_file)
print(f"\nProses konversi selesai. File-file asli telah digantikan dengan hasil konversi.")