import random
from bip_utils import Bip39SeedGenerator
from solders.keypair import Keypair
import base58
import hashlib

def generate_solana_keypair_from_seed(seed_phrase: str, index: int) -> str:
    """Menghasilkan private key Solana dari seed phrase dengan index untuk variasi."""
    try:
        seed_bytes_full = Bip39SeedGenerator(seed_phrase).Generate()
        # Tambahkan index ke seed untuk membuatnya unik
        salted_seed = seed_bytes_full + index.to_bytes(4, byteorder='big')
        # Hash seed yang sudah ditambahkan salt untuk mendapatkan 32 byte
        solana_seed_bytes = hashlib.sha256(salted_seed).digest()[:32]
        keypair = Keypair.from_seed(list(solana_seed_bytes))
        private_key_base58 = base58.b58encode(keypair.secret()).decode('utf-8')
        return private_key_base58
    except Exception as e:
        print(f"Terjadi kesalahan: {e}")
        return None

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
        num_keys = random.randint(80, 100)  # Acak antara 80 sampai 100 private key
        filename = sanitize_filename(seed_phrase)
        try:
            with open(filename, "w") as outfile:
                for i in range(num_keys):
                    private_key = generate_solana_keypair_from_seed(seed_phrase, i)
                    if private_key:
                        outfile.write(f"{private_key}\n")
            print(f"Private key untuk {filename} ({num_keys} key) telah diekspor.")
        except Exception as e:
            print(f"Gagal mengekspor private key untuk {filename}: {e}")

if __name__ == "__main__":
    main()
