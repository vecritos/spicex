import math

def sieve(limit):
    primes = []

    if limit < 2:
        return primes
    elif limit == 2:
        primes.append(2)
    elif limit == 3:
        primes.append(3)

    is_prime = [False] * (limit + 1)
    loop_limit = int(math.sqrt(limit)) + 1

    for i in range(1, loop_limit):
        for j in range(1, loop_limit):
            if i == j:
                continue

            i2 = i**2
            j2 = j**2

            n = 4 * i2 + j2
            if n <= limit and n % 12 in (1, 5):
                is_prime[n] = not is_prime[n]

            n = 3 * i2 + j2
            if n <= limit and n % 12 == 7:
                is_prime[n] = not is_prime[n]

            if i > j:
                n = 3 * i2 - j2
                if n <= limit and n % 12 == 11:
                    is_prime[n] = not is_prime[n]

    primes.append([x for x in range(5, limit + 1) if is_prime[x]])
    return primes[0] # dereference 

def pick_prime(primes, min_size=1000):
    """returns a suitable prime to use as modulus"""
    for prime in primes:
        if prime >= min_size:
            return prime

    return None

def hash(p, string, modulus):
    """implements polynomial rolling of string keys"""
    hash_value = 0
    for i, char in enumerate(string):
        hash_value = ord(char) * (p << i) + hash_value

    return hash_value % modulus

if __name__ == '__main__':
    primes = sieve(10000) # modify limit based on your needs
    print(primes)
    modulus = pick_prime(primes, 1000)

    if modulus != None:
        test_array = ["alpha","beta","gamma","delta","epsilon"]
        
        for string in test_array:
            hash_value = hash(5871, string, modulus)
            print(f"Hash of {string} is {hash_value}")
    else:
        print(f"No prime large enough found, please expand test case")

