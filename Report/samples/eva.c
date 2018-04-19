#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <stdio.h>

#define NUM_PRIMES 8

int isPrime(int candidate) {
	if (candidate == 1) {
		return 0;
	}

	for (int i = 2; i < (((int) sqrt(candidate)) + 1); i++) {
		if (!(candidate % i)) {
			return 0;
		}
	}
	return 1;
}

int main(void) {
	srand(time(NULL));
	int randVal = rand();
	int randPrime = 2;
	int morePrimes[NUM_PRIMES];
	int index;
	int current = 1;

	for (index = 0; index < NUM_PRIMES; current++) {
		if (isPrime(current)) {
			if (rand() % 2) {
				randPrime = current * 4;
			}
			morePrimes[index] = current;
			++index;
		}
	}
}
