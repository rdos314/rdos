#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#include <rdos.h>

void main()
{
    int min;
    int max;

    RdosGetAudioInputAmpCap(0, 0, 12, &min, &max);
        
    RdosTestGate();    
}

