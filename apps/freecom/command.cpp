#include "rdos.h"
#include <stdio.h>

void main()
{
	int resdll;
	int size;
	char str[0x1000];

	resdll = RdosLoadDll("langswe");
	size = RdosReadResource(resdll, 1, str, 0x1000);
	if (size)
	{
		str[size] = 0;
		printf(str);
	}
	RdosFreeDll(resdll);
}

