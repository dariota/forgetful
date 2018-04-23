size_t size = TOO_LARGE;
if (rand() % 2)
	size = SMALL_ENOUGH;
val = malloc(size);
free(val);
