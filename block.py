import Crypto.Hash.SHA512 as SHA512

class Block():
    """ Cookie storage """

    def __init__(self):

        """ Constructor """

        self.__previous_block = None
        self.__previous_hash = None
        self.__current_hash = None
        self.__transactions = []

    @property
    def previous_block(self) -> 'Block':
        return self.__previous_block

    @previous_block.setter
    def previous_block(self, prev_block: 'Block'):
        self.__previous_block = prev_block

    @property
    def previous_hash(self) -> str:
        return self.__previous_hash

    @previous_hash.setter
    def previous_hash(self, prev_hash: str):
        self._previous_hash = prev_hash

    @property
    def current_hash(self) -> str:
        return self.__current_hash

    @current_hash.setter
    def current_hash(self, current_hash):
        self.__current_hash = current_hash

    @property
    def transactions(self):
        return self.__transactions

    @transactions.setter
    def transactions(self, transactions):
        self.__transactions = transactions

    def calculate_hash(self):

        """ Calculate the hash of the current block

        Plaintext: prevHash|transactions...
        """

        if not self.__previous_hash:
            raise Warning('Previous hash has not been set')
