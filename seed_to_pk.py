import random
from bip44 import Wallet
from bip44.utils import hex_to_private_key
import base58
import os

def export_private_keys(seed_phrase, num_keys):
    wallet = Wallet(seed_phrase)
    results = {}
    for i in range(num_keys):
        derivation_path = f"m/44'/501'/{i}'/0'"
        private_key_hex = wallet.derive_account(derivation_path).private_key
        private_key = hex_to_private_key(private_key_hex)
        private_key_bytes = private_key.to_bytes(32, 'big')
        private_key_base58 = base58.b58encode(private_key_bytes).decode('utf-8')
        results[derivation_path] = private_key_base58
    return results

def sanitize_filename(filename):
    return filename.replace(" ", "_") + ".txt"

def main():
    try:
        with open("seed_phrase.txt", "r") as f:
            seed_phrases = [line.strip() for line in f.readlines()]
    except FileNotFoundError:
        print("File seed_phrase.txt tidak ditemukan.")
        return

    for seed_phrase in seed_phrases:
        num_keys = random.randint(80, 100)  # Jumlah kunci acak antara 80 dan 100
        results = export_private_keys(seed_phrase, num_keys)
        filename = sanitize_filename(seed_phrase)
        try:
            with open(filename, "w") as outfile:
                for path, pk in results.items():
                    outfile.write(f"{path}: {pk}\n")
            print(f"Kunci pribadi untuk {filename} ({num_keys} kunci) telah diekspor.")
        except Exception as e:
            print(f"Gagal mengekspor kunci pribadi untuk {filename}: {e}")

if __name__ == "__main__":
    main()
