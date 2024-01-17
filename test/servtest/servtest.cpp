#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "httpsfact.h"

void main()
{
    THttpsSocketServerFactory fact(443, 100, 0x1000);
    fact.RootDir = "d:/www";

    fact.SetCertificate("d:/ssl/cert.pem", "d:/ssl/privkey.pem", "d:/ssl/chain.pem");

    for (;;)
        fact.WaitForever();
}



