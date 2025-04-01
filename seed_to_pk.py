from bip44 import Wallet
from bip44.utils import hex_to_private_key
import base58

seed_phrase = input("Masukkan seed phrase Anda: ")
wallet = Wallet(seed_phrase)
private_key_hex = wallet.derive_account("m/44'/501'/0'/0'").private_key

private_key = hex_to_private_key(private_key_hex)
private_key_bytes = private_key.to_bytes(32, 'big') # convert integer to bytes

private_key_base58 = base58.b58encode(private_key_bytes).decode('utf-8')

print("Kunci pribadi (Base58):", private_key_base58)
