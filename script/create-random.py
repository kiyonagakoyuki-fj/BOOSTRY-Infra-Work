import random
import string


def randomstring():
    return ''.join([random.choice(string.ascii_letters + string.digits + "#$%&+-.<=>?@[^_{|}~") for i in range(30)])


print(randomstring())
