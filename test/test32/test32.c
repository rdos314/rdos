#include <stdio.h>
#include <stdlib.h>
#include "datetime.h"

#include <rdos.h>

void main()
{
    char str[80];
    TDateTime currtime;

    sprintf(str, "%d", currtime.GetDay());

    RdosTestGate(str);
    
}

