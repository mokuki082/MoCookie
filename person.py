#!/usr/bin/env python3
"""Contains information on Individuals involved in the project."""

import encryption


class CookierList():
    """A list of cookiers."""

    def __init__(self):
        """Constructor."""
        self.__cookiers = []

    @property
    def cookiers(self):
        """Get cookiers."""
        return self.__cookiers

    @cookiers.setter
    def cookiers(self, cookiers):
        """Set cookiers."""
        for cookier in cookiers:
            if not isinstance(cookier, Cookier):
                raise TypeError('list elements must be of type Cookier')
        self.__cookiers = cookiers

    def add_cookier(self, cookier: 'Cookier'):
        """Add a cookier into the list.

        Keyword arguments:
        cookier -- a Cookier object
        """
        if not isinstance(cookier, Cookier):
            raise TypeError("add_cookier(x): x must be of type Cookier")
        # Check that the cookier doesn't exist already
        if cookier in self.__cookiers:
            raise ValueError('add_cookier(x): x already exists.')
        self.__cookiers.append(cookier)

    def remove_cookier(self, cookier: 'Cookier'):
        """Remove a cookier from the list.

        Keyword arguments:
        pubk -- public key associated to the cookier
        """
        try:
            self.__cookiers.remove(cookier)
        except ValueError:
            raise ValueError('remove_cookier(x): x not in cook')

    def search(self, pubk=None: str, name=None: str, wallet=None: int) -> list:
        """Search for all matching cookiers in the list.

        Keyword arguments:
        pubk -- public key associated to the cookier
        name -- name associated to the cookier
        wallet -- Number of cookies belonging to the cookier

        Returns:
        A list of matched cookiers

        """
        conditions = 0
        if pubk:
            if not isinstance(pubk, str):
                raise TypeError('search(pubk=x): x must be of type str.')
            conditions += 1
        if name:
            if not isinstance(name, str):
                raise TypeError('search(name=x): x must be of type str.')
            conditions += 1
        if wallet:
            if not isinstance(wallet, int):
                raise TypeError('search(wallet=x): x must be of type int.')
            conditions += 1

        if conditions == 0:
            err_log = 'search(pubk=x, name=y): please specify x and/or y'
            raise ValueError(err_log)

        matched_cookiers = []
        for cookier in self.__cookiers:
            match = 0
            if pubk and cookier.pubk == pubk:
                match += 1
            if name and cookier.name == name:
                match += 1
            if wallet and cookier.waller == wallet:
                match += 1
            if conditions == match:
                matched_cookiers.append(cookier)
        return matched_cookiers


class Cookier():
    """An individual involved in MoCookie."""

    name_maxlen = 16

    def __init__(self, pubk: str, name: str):
        """Constructor.

        Keyword arguments:
        pubk -- RSA public key in base 64 as a string
        name -- a name within <name_maxlen> characters as a string
        """
        if not isinstance(pubk, str):
            raise TypeError('pubk must be of type string')
        if not isinstance(name, str):
            raise TypeError('name must be of type string')
        if 2 <= len(name) <= Cookier.name_maxlen:
            self.__name = name
        else:
            raise ValueError('name must be of length 2-16')
        self.__pubk = pubk
        self.__wallet = 0

    def __eq__(self, other):
        """Redefine equality function."""
        return self.__pubk == other.pubk and self.__name == other.name

    @property
    def pubk(self) -> str:
        """Get the cookier's public key."""
        return self.__pubk

    @pubk.setter
    def pubk(self, pubk: str):
        """Set the cookier's public key."""
        self.__pubk = pubk

    @property
    def name(self) -> str:
        """Get the cookier's name."""
        return self.__name

    @name.setter
    def name(self, name: str):
        """Set the cookier's name."""
        if len(name) > Cookier.name_maxlen:
            raise ValueError('Name is too long.')
        self.__name = name

    @property
    def wallet(self) -> int:
        """Get the cookier's wallet"""
        return self.__wallet

    @wallet.setter
    def wallet(self, wallet):
        """Set the cookier's wallet"""
        self.__wallet = wallet

    def verify(self, message: str, signature: str) -> bool:
        """Verify a message sent by the Cookier.

        Keyword arguments:
        message -- the message as a string
        signature -- the signature in base64 as a string
        """
        return encryption.RSA_verify(message, signature, self.__pubk)
