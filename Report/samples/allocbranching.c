int* val = malloc(TOO_LARGE);
if (rand() % 2)
	val = malloc(SMALL_ENOUGH);
free(val);
