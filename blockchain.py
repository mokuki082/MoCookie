"""Blockchain."""

import Crypto.Hash.SHA512 as SHA512
import transaction
import encryption


class Block():
    """Block in the blockchain."""

    def __init__(self):
        """Constructor."""
        self.__previous_block = None
        self.__previous_hash = None
        self.__current_hash = None
        self.__transactions = []

    @property
    def previous_block(self) -> 'Block':
        """Get previous_block."""
        return self.__previous_block

    @previous_block.setter
    def previous_block(self, prev_block: 'Block'):
        """Set previous_block."""
        self.__previous_block = prev_block

    @property
    def previous_hash(self) -> 'Block':
        """Get previous_hash."""
        return self.__previous_hash

    @previous_hash.setter
    def previous_hash(self, prev_hash: 'Block'):
        """Set previous_hash."""
        self.__previous_hash = prev_hash

    @property
    def current_hash(self) -> str:
        """Compute hash of the current block if haven't already.

        Returns:
        128 character hash of the current block

        """
        if not self.__current_hash:
            self.__current_hash = self.calculate_hash()
        return self.__current_hash

    @property
    def transactions(self) -> list:
        """Get transactions."""
        return self.__transactions

    @transactions.setter
    def transactions(self, transactions: list):
        """Set transactions."""
        if not isinstance(transactions, list):
            raise TypeError('transactions must be of type list.')
        for t in transactions:
            if not issubclass(t, transaction.Transaction):
                e = 'elements must be a subclass of transaction.Transaction'
                raise TypeError(e)
        self.__transactions = transactions

    def add_transaction(self, t: 'Transaction'):
        """Add a transaction to the block."""
        if not issubclass(t, transaction.Transaction):
            raise TypeError('transaction is not a subclass of Transaction')
        self.__transactions.append(t)

    def calculate_hash(self) -> str:
        """Calculate the hash of the current block.

        Use the current_hash() function for optimizatoin.

        Returns:
        Base64 of the hash:

        """
        plaintext = ''  # nonce(opt)|prev_hash|trans1|trans2...
        if not self.__previous_hash:
            raise Warning('Previous hash has not been set yet.')
        plaintext += self.__previous_hash
        plaintext += '|'.join([str(i) for i in self.__transactions])
        digest = SHA512.new(bytes(plaintext, 'utf-8')).digest()
        return str(encryption.bin2base64(digest), 'ascii')


class Blockchain():
    """Store a linked list of blocks."""

    def __init__(self):
        """Constructor."""
        self.__head = None
        self.__size = 0
        self.__pool = []

    @property
    def head(self) -> 'Block':
        """Get head block."""
        return self.__head

    @head.setter
    def head(self, head: 'Block'):
        """Set head block."""
        if not isinstance(head, Block):
            raise TypeError('head must be of type Block.')
        # Update size
        curr = head
        size = 0
        while curr:
            size += 1
            curr = curr.previous_block
        self.__head = head
        self.__size = size

    @property
    def size(self) -> 'Block':
        """Get blockchain size."""
        return self.__size

    @property
    def pool(self) -> list:
        """Get pool."""
        return self.__pool

    @pool.setter
    def pool(self, pool: list):
        """Set pool."""
        if not isinstance(pool, list):
            raise TypeError('pool must be of type list')
        for t in pool:
            if not issubclass(t, transaction.Transaction):
                e = 'elements in pool must be a subclass of Transaction'
                raise TypeError(e)
        self.__pool = pool

    def add_transaction(self, t: 'transaction.Transaction'):
        """Add a transaction into the pool.

        Keyword arguments:
        t -- transaction, any subclass of transaction.Transaction
        """
        if not issubclass(t, transaction.Transaction):
            e = 'add_transaction(t): t must be a subclass of Transaction.'
            raise TypeError(e)
        # Check transaction validity
        t.validate()
        # Add transaction to the pool
        self.__pool.append(t)

    def commit(self, nonce: int) -> bool:
        """Commit 3 or less transactions from the pool based on condition.

        Keyword arguments:
        nonce -- a random integer

        Returns:
        True if a block is committed
        False if no blocks is committed

        """
        if len(self.__pool) == 0:
            # Nothing to commit
            return False

        # Initialize a new block
        new_block = Block()
        if not self.__head:
            new_block.previous_hash = '0' * 128
        new_block.transactions = self.__pool
        new_block.previous_block = self.__head

        # Commit current pool
        self.__head = new_block
        self.__pool = []
        self.__size += 1

        # Execute actions associated to the transactions
        for t in new_block.transactions:
            t.action()

        return True
