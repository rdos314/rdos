#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#include <rdos.h>

void main()
{
    int ok;
    int dev;
    int codec;
    int node;

    ok = RdosGetFixedAudioOutput(&dev, &codec, &node);
        
    RdosTestGate();    
}

