#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "modbus.h"
#include "datetime.h"


/*################## GetFile ##########################
*   Purpose....: Get a new file                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TFile *GetFile()
{
    int num;
    int handle;
    char FileName[40];

    for (num = 0; num < 10000; num++)
    {
        sprintf(FileName, "d:\\inv\\log%04d.dat", num);
        handle = RdosOpenFile(FileName, 0);
        if (handle)
            RdosCloseFile(handle);
        else
            break;
    }
    return new TFile(FileName, 0);
}

void main()
{
    TFile *File = GetFile();
    TModbusDevice dev(0x7701A8C0, 502);
    TModbus unit(&dev, 1);
    int i;
    int val;
    char str[80];
    TString row;
    TDateTime time;

    for (;;)
    {
        if (unit.ReqHoldingRegisters(40203, 28))
        {
            time.SetCurrent();
            row.printf("%04d-%02d-%02d %02d.%02d ", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin());

            unit.GetBufferedHoldingRegister(40214, &val);
            sprintf(str, "Output power %dW", val);
            row += str;

            unit.GetBufferedHoldingRegister(40224, &val);
            sprintf(str, ", PV power %dW", val);
            row += str;

            unit.GetBufferedHoldingRegister(40216, &val);
            sprintf(str, ", Battery voltage %d.%1dV", val / 10, val %10);
            row += str;

            unit.GetBufferedHoldingRegister(40217, &val);
            row += ", current ";
            if (val < 0)
            {
                val = -val;
                row += "-";
            }
            sprintf(str, "%d.%1dA\r\n", val / 10, val %10);
            row += str;
        }

        printf(row.GetData());
        File->Write(row.GetData(), row.GetSize());

        for (i = 0; i < 60; i++)
            RdosWaitMilli(1000);
    }

//    RdosTestGate("");
}



