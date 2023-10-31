#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"
#include "file.h"
#include "videodev.h"

void main()
{
    TGraphicDevice *vbe;
    char *Linear;
    int ScanLine = 800;
    int Height = 600;
    int i, j;

    vbe = new TVideoGraphicDevice(32, 800, 600);

    Linear = (char *)vbe->GetLinear();

    for (i = 0; i < ScanLine; i++)
        for (j = 0; j < 4; j++)
            Linear[4 * i + j] = 0xFF;

    for (i = 0; i < Height; i++)
        for (j = 0; j < 4; j++)
            Linear[4 * i * ScanLine + j] = 0xFF;


//    RdosTestGate("");
}
