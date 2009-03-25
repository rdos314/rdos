#include <stdio.h>
#include "rdos.h"

void main()
{
    int i;

    for (i = 0; i < 10; i++)
        RdosWriteString("hello world\r\n");
}

