#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "unzip.h"


void main()
{
    char *buf = new char[4000];
    int size;

    size = RdosGetCertificateJson("d:/ssl/cert.pem", buf, size);   

    buf[size] = 0;
    printf(buf); 

    RdosTestGate("");
}



