void main(void)
{
  int tmp;
  tmp = malloc(1);
  void *alloced = (void *)(tmp + 1);
  free(alloced - 1);
  return;
}
