from bip_utils import Bip39SeedGenerator, Bip44, Bip44Coins, Bip44Changes
from solana.keypair import Keypair
import base58
import random

# Fungsi untuk mengexport private key dari seed phrase dengan indeks alamat tertentu
def export_private_key(seed_phrase: str, index: int) -> str:
    seed_bytes = Bip39SeedGenerator(seed_phrase).Generate()
    bip44_mst_ctx = Bip44.FromSeed(seed_bytes, Bip44Coins.SOLANA)
    bip44_acc_ctx = bip44_mst_ctx.Purpose().Coin().Account(0).Change(Bip44Changes.CHAIN_EXT)
    bip44_addr_ctx = bip44_acc_ctx.AddressIndex(index)
    private_key_bytes = bip44_addr_ctx.PrivateKey().Raw().ToBytes()
    keypair = Keypair.from_seed(private_key_bytes)
    private_key_base58 = base58.b58encode(keypair.secret_key).decode()
    return private_key_base58

# Baca seed phrases dari file seeds.txt
with open("seeds.txt", "r") as file:
    seed_phrases = file.readlines()

# Generate private keys untuk setiap seed phrase dan simpan hasilnya dalam satu file .txt
for seed_phrase in seed_phrases:
    seed_phrase = seed_phrase.strip()
    if seed_phrase:
        num_keys = random.randint(80, 100)
        filename = f"{seed_phrase.replace(' ', '_')}.txt"
        with open(filename, "w") as output_file:
            for i in range(num_keys):
                private_key = export_private_key(seed_phrase, i)
                output_file.write(f"{private_key}\n")
        print(f"File {filename} created with {num_keys} Private Keys")

print("All seed phrases processed.")
