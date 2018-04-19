int fc(int a) {
	return a + 1;
}

int main(void) {
	int i = 1;
	int* point = malloc(sizeof(i));
	int** ppoint = malloc(sizeof(point) * fc(1));

	return 2 * i;
}
