from solders.keypair import Keypair
from mnemonic import Mnemonic
import random

def buat_dompet_solana_mnemonic_acak():
    """Membuat 5-10 dompet Solana dengan seed phrase 12 kata dan menyimpannya."""

    mnemo = Mnemonic("english")
    jumlah_dompet = random.randint(7, 10)  # Menghasilkan jumlah dompet acak antara 5 dan 10

    with open('seed_phrase.txt', 'w') as f:
        for i in range(jumlah_dompet):
            seed_phrase = mnemo.generate(strength=128)  # Menghasilkan seed phrase 12 kata
            seed_bytes = mnemo.to_seed(seed_phrase)
            keypair = Keypair.from_seed(seed_bytes[:32])  # Solana menggunakan 32 byte pertama dari seed
            f.write(f"{seed_phrase}\n")
            print(f"Dompet {i + 1}: Seed Phrase: {seed_phrase}, Alamat Publik: {keypair.pubkey()}")

    print(f"{jumlah_dompet} dompet Solana dengan seed phrase 12 kata telah dibuat dan disimpan di 'seed_phrase.txt'")

if __name__ == "__main__":
    buat_dompet_solana_mnemonic_acak()