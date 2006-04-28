#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "serial.h"
#include "rdos.h"
#include "keyboard.h"

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
	RdosWaitMilli(5000);

	TSerialDebug Debug;
	char Str[10];
	TWaitDevice *WaitDevice;
	TWait Wait;
	TKeyboardDevice Keyboard;
	int num;

	TSerialDevice Port1(1, 9600, 'E', 8, 1);
	TSerialDevice Port2(4, 9600, 'E', 8, 1);

	Port1.Open();
	Port2.Open();

	Wait.Add(&Port1);
	Wait.Add(&Port2);
	Wait.Add(&Keyboard);

	int handle;
	char FileName[40];

	for (num = 0; num < 100; num++)
	{
		sprintf(FileName, "d:\\log\\raw%03d.dat", num);
		handle = RdosOpenFile(FileName, 0);
		if (handle)
			RdosCloseFile(handle);
		else
			break;
	}
	TFile *File = new TFile(FileName, 0);

//	TFile *CbusFile = new TFile("z:\\cbus.dat", 0);
//	TFile *BarFile = new TFile("z:\\bar.dat", 0);
//	TFile *File = new TFile("z:\\raw.dat", 0);
//	TFile *File = new TFile("z:\\device.dat", 0);

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
				Keyboard.Get();
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
	}
}

