#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "serial.h"
#include "rdos.h"
#include "keyboard.h"

#include "str.h"
#include "path.h"

#define MAX_FILE_SIZE   0x400000 // 4 MB

/*################## GetFile ##########################
*   Purpose....: Get a new file     	   					      	        #
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
		sprintf(FileName, "d:\\log\\raw%04d.dat", num);
		handle = RdosOpenFile(FileName, 0);
		if (handle)
			RdosCloseFile(handle);
		else
			break;
	}
	return new TFile(FileName, 0);
}

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void cdecl main()
{
	RdosWaitMilli(5000);

	TSerialDebug Debug;
	char Str[10];
	TWaitDevice *WaitDevice;
	TWait Wait;
	TKeyboardDevice Keyboard;

	TSerialDevice Port1(1, 9600, 'N', 8, 1);
	TSerialDevice Port2(4, 9600, 'N', 8, 1);

	Port1.Open();
	Port2.Open();

	Wait.Add(&Port1);
	Wait.Add(&Port2);
	Wait.Add(&Keyboard);

	TFile *File = GetFile();

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

		if (WaitDevice == &Keyboard)
		{
			if (Keyboard.Poll())
			{
				if (Keyboard.Get() == 0x1b)
					return;
			}
		}

		sprintf(Str, "%04hX", Debug.ch);
		Str[0] = Str[2];
		Str[1] = Str[3];
		Str[2] = ' ';
		Str[3] = ' ';
		Str[4] = 0;
		RdosWriteString(Str);

		if (File->GetSize() > MAX_FILE_SIZE)
		{
			delete File;
			File = GetFile();
		}
	}
}
