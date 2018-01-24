class Transaction():

    def __init__(self):
        """ Constructor """
        self._content = None
        self._is_valid = False
        pass

    def __str__(self):
        """ String representation of the transaction

        Format: protocol|privk1,privk2...,privkn|content
        """
        raise NotImplementedError

    @property
    def content(self):
        return self._content

    @content.setter
    def content(self, sender):
        self._content = sender

    @property
    def is_valid():
        return self._is_valid
