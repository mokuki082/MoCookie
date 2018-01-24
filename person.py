class Involver():
    """ An individual involved in MoCookie """

    name_maxlen = 30

    def __init__(self, pubk: str, name: str):

        """ Constructor

        Keyword arguments:
        pubk -- RSA public key in base 64 as a string
        name -- a name within <name_maxlen> characters as a string
        """

        self.__pubk = pubk
        if len(name) > name_maxlen:
            raise ValueError('Name is too long.')
        self.__name = name

    @property
    def pubk(self):
        return self.__pubk

    @pubk.setter
    def pubk(self, pubk: str):
        self.__pubk = pubk

    @property
    def name(self):
        return self.__name

    @name.setter
    def name(self, name: str):
        if len(name) > name_maxlen:
            raise ValueError('Name is too long.')
        self.__name = name
