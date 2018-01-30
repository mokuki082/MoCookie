
import transaction
import encryption
import cookie


class MoCookieClient():
    """MoCookie client-side API"""

    def __init__(self, username):
        self.__me = cookie.Cookier()

    def give_cookie(privk, pubk, )
