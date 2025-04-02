import random
from bip_utils import Bip39SeedGenerator, Bip44, Bip44Coins, Bip32Ed25519Slip
from solders.keypair import Keypair
from solders.pubkey import Pubkey
from solders.system_program import ID as SYSTEM_PROGRAM_ID
import base58
import os

def export_private_keys(seed_phrase, num_keys):
    try:
        seed_bytes = Bip39SeedGenerator(seed_phrase).Generate()
        master_key = Bip32Ed25519Slip.FromSeed(seed_bytes)
        results = {}
        for i in range(num_keys):
            derivation_path = f"m/44'/501'/{i}'/0'"
            path_segments = derivation_path.split('/')[1:]

            current_key = master_key
            for segment in path_segments:
                index_str = segment[:-1]
                is_hardened = segment.endswith("'")
                index = int(index_str)
                if is_hardened:
                    index += 2**31
                current_key = current_key.DeriveChild(index)

            private_key_bytes = current_key.PrivateKey().ToBytes()
            # Create Keypair from private key bytes using solders
            keypair = Keypair.from_secret_key(bytes(private_key_bytes))
            private_key_base58 = base58.b58encode(keypair.secret().to_bytes()).decode('utf-8')
            results[derivation_path] = private_key_base58
        return results
    except Exception as e:
        print(f"Terjadi kesalahan dalam export_private_keys: {e}")
        return {}

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
