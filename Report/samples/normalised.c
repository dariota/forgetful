int fc(int a)
{
  int __retres;
  __retres = a + 1;
  return __retres;
}

int main(void)
{
  int __retres;
  int **tmp_1;
  int tmp_0;
  int i = 1;
  int *point = malloc(sizeof(i));
  tmp_0 = fc(1);
  tmp_1 = (int **)malloc(sizeof(point) * (unsigned int)tmp_0);
  int **ppoint = tmp_1;
  __retres = 2 * i;
  return __retres;
}
