#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "serial.h"
#include "rdos.h"

#include "str.h"
#include "path.h"

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void cdecl main()
{
	TSerialDebug Debug;
	char Str[10];
	TWaitDevice *WaitDevice;
	TWait Wait;
	TSerialDevice Port1(&Wait, 1, 2400, 'E', 7, 1);
	TSerialDevice Port2(&Wait, 2, 2400, 'E', 7, 1);

//	TFile *CbusFile = new TFile("z:\\cbus.dat", 0);
//	TFile *BarFile = new TFile("z:\\bar.dat", 0);
	TFile *File = new TFile("z:\\raw.dat", 0);

	for (;;)
	{
		WaitDevice = Wait.WaitForever();
		if (WaitDevice == &Port1)
		{
			RdosGetTics(&Debug.TimeMSB, &Debug.TimeLSB);
			Debug.Channel = 1;
			Debug.ch = Port1.Read();
			File->Write(&Debug, sizeof(Debug));
			RdosSetForeColor(9);
		}

		if (WaitDevice == &Port2)
		{
			RdosGetTics(&Debug.TimeMSB, &Debug.TimeLSB);
			Debug.Channel = 2;
			Debug.ch = Port2.Read();
			File->Write(&Debug, sizeof(Debug));
			RdosSetForeColor(11);
		}

		sprintf(Str, "%04hX", Debug.ch);
		Str[0] = Str[2];
		Str[1] = Str[3];
		Str[2] = ' ';
		Str[3] = ' ';
		Str[4] = 0;
		RdosWriteString(Str);
	}
}

