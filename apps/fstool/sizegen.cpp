#include <stdio.h>

const long double Coeff = 1.17777589604;

void GenSizeTab()
{
	long double Fact = 1.0;
	long double Sum = 0.0;
	int i;

	printf(";\r\n");
	printf("; Table is generated using %12.10f as factor\r\n", (float)Coeff);
	printf(";\r\n");
	printf("\r\n");
	printf("ExtentSizeTab:");

	for (i = 0; i < 126; i++)
	{
		if (i % 4 == 0)
			printf("\r\nes%02hX	DD ", i);

		Sum += (long)Fact;
		printf("%08lXh", (long)Fact);
		Fact *= Coeff;

		if (i % 4 != 3)
			printf(", ");
	}
	printf("\r\n");
}

void GenSumTab()
{
	long double Fact = 1.0;
	long double Sum = 0.0;
	int i;

	printf("\r\n");
	printf(";\r\n");
	printf("; This table is the sum of the ExtentSizeTab\r\n");
	printf("; The total sum is 2^23\r\n");
	printf(";\r\n");
	printf("\r\n");
	printf("ExtentPosTab:");

	for (i = 0; i < 126; i++)
	{
		if (i % 4 == 0)
			printf("\r\nep%02hX	DD ", i);

		printf("%08lXh", (long)Sum);
		Sum += (long)Fact;
		Fact *= Coeff;

		if (i % 4 != 3)
			printf(", ");
	}
	printf("\r\n");
}

void main()
{
	GenSizeTab();
	GenSumTab();
}

