"""All types of transactions in MoCookie."""

from person import Cookier


class Transaction():
    """Generic Transaction class."""

    def __init__(self, protocol: str, recent_block: str, content: str,
                 cookiers: list):
        """Constructor.

        Keyword arguments:
        protocol -- a 2 character id for the transaction protocol.
        recent_block -- the hash of a recent block as a string.
        content -- body of the transaction. Limit: 100 characters.
        cookiers -- list of cookiers involved in the transaction. Limit: 2-3.
        """
        self._protocol = protocol
        self._recent_block = recent_block
        self._content = content  # 100 characters limit
        self._cookiers = cookiers  # 2-3 length limit
        self.validate()

    def __str__(self):
        """Give the string representation of the transaction.

        Returns:
        protocol|recent_block|pubk1,pubk2...,pubkn|content

        """
        pubks = [i.pubk for i in self._cookiers]
        return '%s|%s|%s|%s' % (self._protocol,
                                self._recent_block,
                                ','.join(pubks),
                                self._content)

    def validate(self):
        """Validate the transaction at a basic level."""
        if not isinstance(self._protocol, str):
            raise TypeError('Transaction(a,b,c,d): a must be of type str.')
        if not isinstance(self._recent_block, str):
            raise TypeError('Transaction(a,b,c,d): b must be of type str.')
        if not isinstance(self._content, str):
            raise TypeError('Transaction(a,b,c,d): c must be of type str.')
        if not isinstance(self._cookiers, list):
            raise TypeError('Transaction(a,b,c,d): d must be of type list.')
        for cookier in self._cookiers:
            if not isinstance(cookier, Cookier):
                err_ms = 'Transaction(a,b,c,d): d must contain Cookier only.'
                raise TypeError(err_ms)
        if len(self._content) > 100:
            err_ms = 'Transaction(a,b,c,d): c cannot be longer than 100 chars.'
            raise ValueError(err_ms)
        if len(self._cookiers) > 3:
            err_ms = 'Transaction(a,b,c,d): d cannot have more than 3 elements'
            raise ValueError(err_ms)
        try:
            self.validate_further()
        except NotImplementedError:
            pass

    def validate_further(self):
        """Execute at the end of validate()."""
        raise NotImplementedError

    def action(self):
        """Actin associated with the transaction."""
        raise NotImplementedError


class GiveCookieTransaction(Transaction):
    """A gives B a crypto cookie."""

    def __init__(self, recent_block: str, giver: 'Cookier',
                 receiver: 'Cookier', reason: str):
        """Constructor.

        Keyword arguments:
        recent_block -- hash value of a recent block as a string
        giver -- a Cookier object
        receiver -- a Cookier object
        reason -- a string of 100 characters limit
        """
        # Initialize super class
        super().__init__('gc', recent_block, reason, [giver, receiver])

    @property
    def reason(self):
        """Get the reason."""
        return self._content

    @reason.setter
    def reason(self, reason):
        """Set the reason."""
        if len(reason) > 100:
            raise ValueError('reason cannot be more than 100 characters.')
        self._content = reason

    @property
    def giver(self):
        """Get the giver."""
        return self._cookiers[0]

    @giver.setter
    def giver(self, giver):
        """Set the giver."""
        if not isinstance(giver, Cookier):
            raise TypeError('giver must be of type Cookier.')
        self._cookiers[0] = giver

    @property
    def receiver(self):
        """Get the receiver."""
        return self._cookiers[1]

    @receiver.setter
    def receiver(self, receiver):
        """Set the receiver."""
        if not isinstance(receiver, Cookier):
            raise TypeError('receiver must be of type Cookier.')
        self._cookiers[1] = receiver

    def action(self):
        """Recalculate A, B and C's cookie wallets."""
        self._cookiers[0].wallet -= 1
        self._cookiers[1].wallet += 1



class ReceiveCookieTransaction(Transaction):
    """A receive a real cookie from B."""

    def __init__(self, recent_block: str, receiver: 'Cookier',
                 giver: 'Cookier', cookie_type: str):
        """Constructor.

        Keyword arguments:
        recent_block -- hash value of a recent block as a string
        receiver -- a Cookier object
        giver -- a Cookier object
        cookie_type -- a string of 100 characters limit
        """
        super().__init__('rc', recent_block, cookie_type, [receiver, giver])

    @property
    def cookie_type(self):
        """Get the cookie_type."""
        return self._content

    @cookie_type.setter
    def cookie_type(self, cookie_type):
        """Set the cookie_type."""
        if len(cookie_type) > 100:
            raise ValueError('cookie_type cannot be more than 100 characters.')
        self._content = cookie_type

    @property
    def receiver(self):
        """Get the receiver."""
        return self._cookiers[0]

    @receiver.setter
    def receiver(self, receiver):
        """Set the receiver."""
        if not isinstance(receiver, Cookier):
            raise TypeError('receiver must be of type Cookier.')
        self._cookiers[0] = receiver

    @property
    def giver(self):
        """Get the giver."""
        return self._cookiers[1]

    @giver.setter
    def giver(self, giver):
        """Set the giver."""
        if not isinstance(giver, Cookier):
            raise TypeError('giver must be of type Cookier.')
        self._cookiers[1] = giver

    def action(self):
        """Recalculate A, B and C's cookie wallets."""
        self._cookiers[0].wallet -= 1
        self._cookiers[1].wallet += 1


class CollapseCookieTransaction(Transaction):
    """A owes B owes C a cookie then A gives C a cookie."""

    def __init__(self, recent_block: str, giver: 'Cookier', middler: 'Cookier'
                 receiver: 'Cookier', cookie_type: str):
        """Constructor.

        Keyword arguments:
        recent_block -- hash value of a recent block as a string
        giver -- a Cookier object
        receiver -- a Cookier object
        cookie_type -- a string of 100 characters limit
        """
        super().__init__('cc', recent_block, cookie_type,
                         [giver, middler, receiver])

    @property
    def cookie_type(self):
        """Get the cookie_type."""
        return self._content

    @cookie_type.setter
    def cookie_type(self, cookie_type):
        """Set the cookie_type."""
        if len(cookie_type) > 100:
            raise ValueError('cookie_type cannot be more than 100 characters.')
        self._content = cookie_type

    @property
    def giver(self):
        """Get the giver."""
        return self._cookiers[0]

    @giver.setter
    def giver(self, giver):
        """Set the giver."""
        if not isinstance(giver, Cookier):
            raise TypeError('giver must be of type Cookier.')
        self._cookiers[0] = giver

    @property
    def receiver(self):
        """Get the receiver."""
        return self._cookiers[1]

    @receiver.setter
    def receiver(self, receiver):
        """Set the receiver."""
        if not isinstance(receiver, Cookier):
            raise TypeError('receiver must be of type Cookier.')
        self._cookiers[1] = receiver

    def action(self):
        """Recalculate A, B and C's cookie wallets."""
        self._cookiers[0].wallet += 1
        self._cookiers[2].wallet -= 1
