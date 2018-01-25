#!/usr/bin/env python3
"""Encryption related classes."""

import os
import binascii

# Globals
PYCRYPTO_INSTALLED = False

# Check if pycrypto is installed
try:
    from Crypto.PublicKey import RSA
    from Crypto.Cipher import PKCS1_OAEP
    from Crypto.Signature import PKCS1_PSS
    from Crypto.Hash import SHA512
    PYCRYPTO_INSTALLED = True
except ImportError:
    pass


def bin2base64(bin_str: bytes) -> bytes:
    """Convert bytes to base64.

    Keyword arguments:
    bin_str -- Ascii string representation as bytes

    Returns:
    Base 64 representation as bytes

    """
    return binascii.b2a_base64(bin_str)


def base642bin(base64_str: bytes) -> bytes:
    """Convert base64 to bytes.

    Keyword arguments:
    bin_str -- Base64 representation as bytes

    Returns:
    Ascii string representation as bytes

    """
    return binascii.a2b_base64(base64_str)


def RSA_verify(message: str, signature: str, pubkey: str) -> bool:
    """Verify a message using its signature.

    Keyword arguments:
    message -- the message
    signature -- the signature in base64 ascii string
    pubkey -- sender's public key in base64 ascii string

    Returns:
    A boolean

    """
    if not isinstance(message, str):
        raise ValueError('message not a string')
    if not isinstance(signature, str):
        raise ValueError('signature not a string')
    if not isinstance(pubkey, str):
        raise ValueError('pubkey not a string')
    # Decode parameters
    signature = base642bin(bytes(signature, 'ascii'))
    pubkey = base642bin(bytes(pubkey, 'ascii'))
    # Verify
    key = RSA.importKey(pubkey)
    h = SHA512.new(bytes(message, 'utf-8'))
    verifier = PKCS1_PSS.new(key)
    if verifier.verify(h, signature):
        return True
    return False


def RSA_encrypt(message: str, pubk: str) -> str:
    """Encrypt a message using a given RSA public key.

    Keyword arguments:
    message -- a message in string
    pubk -- a public key in base64 ascii string

    Returns:
    ciphertext in base 64 format as a string

    """
    # Decode public key
    pubk = base642bin(bytes(pubk, 'ascii'))
    pubk = RSA.importKey(pubk)
    # Encrypt message
    cipher = PKCS1_OAEP.new(pubk)
    ciphertext = cipher.encrypt(bytes(message, 'utf-8'))
    return str(bin2base64(ciphertext), 'ascii')


class RSAUser():
    """Create an RSA user."""

    keylen = 2048

    def __init__(self):
        """Constructor."""
        # Check if pycrypto is installed
        global PYCRYPTO_INSTALLED
        if not PYCRYPTO_INSTALLED:
            raise ImportError('Module Pycrypto not installed.')

        self.__pubkey = None
        self.__privkey = None

    def retrieve_keys(self, pubkey_path: str, privkey_path: str):
        """Retrieve keys from given files."""
        with open(pubkey_path, 'r') as f:
            key = base642bin(f.read().encode())
            self.__pubkey = RSA.importKey(key)
        with open(privkey_path, 'r') as f:
            key = base642bin(f.read().encode())
            self.__privkey = RSA.importKey(key)

    def generate_keys(self, pubkey_path: str, privkey_path: str):
        """Generate new keys and store the keys in DER format."""
        # Create directories if doesn't exist
        if not os.path.exists(os.path.dirname(pubkey_path)):
            os.makedirs(os.path.dirname(pubkey_path))
        # Generate new priv/pub keys
        self.__privkey = RSA.generate(RSAUser.keylen)
        self.__pubkey = self.__privkey.publickey()
        with open(pubkey_path, 'w') as f:
            key = self.__pubkey.exportKey('DER')
            f.write(str(bin2base64(key), 'ascii'))
        with open(privkey_path, 'w') as f:
            key = self.__privkey.exportKey('DER')
            f.write(str(bin2base64(key), 'ascii'))

    @property
    def pubkey(self) -> str:
        """Get the string representation of the public key."""
        if not self.__pubkey:
            return None
        key = self.__pubkey.exportKey('DER')
        return str(bin2base64(key), 'ascii')

    def decrypt(self, ciphertext: str) -> str:
        """Decrypt a ciphertext using self's private key.

        Keyword arguments:
        ciphertext -- a ciphertext in base64 ascii string

        Returns:
        The original message decrypted from the ciphertext as a string

        """
        if not self.__privkey:
            raise ValueError('Private key does not exist.')
        # Decode ciphertext
        ciphertext = bytes(ciphertext, 'ascii')
        # Decryption
        ciphertext = base642bin(ciphertext)
        cipher = PKCS1_OAEP.new(self.__privkey)
        return str(cipher.decrypt(ciphertext), 'utf-8')

    def sign(self, message: str) -> str:
        """Sign a message.

        Keyword arguments:
        message -- the message in utf-8 string

        Returns:
        The signature as a base64 string

        """
        if not isinstance(message, str):
            raise TypeError("message is not a string")
        if not self.__privkey:
            raise ValueError('Private key does not exist.')
        h = SHA512.new(bytes(message, 'utf-8'))
        signer = PKCS1_PSS.new(self.__privkey)
        signature = signer.sign(h)
        return str(bin2base64(signature), 'ascii')
