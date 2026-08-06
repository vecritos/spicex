import sys

# a simple shitty shifter algorithm

offset = 5
unicode_max = 65565 # sure, no, but sure

def shift(x, encode=True):
    shift_amount = (1 if encode else -1) * offset

    return (x + shift_amount) % unicode_max

def ff(args):
    example = "tormund"
    b = bytes([ord(b) for b in example])
    encoded = [shift(x) for x in b]
    converted = [shift(x, False) for x in encoded]

    print(list(b))
    print(encoded)
    print(converted)

    print('--------------')

if __name__ == '__main__':
    ff(sys.argv)

