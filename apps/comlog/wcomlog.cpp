#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "serial.h"
#include "win32.h"

#include "str.h"
#include "file.h"


void Log(TSerialDebug *Debug)
{
	char Str[10];

	sprintf(Str, "%04hX", Debug->ch);
	Str[0] = Str[2];
	Str[1] = Str[3];
	Str[2] = ' ';
	Str[3] = ' ';
	Str[4] = 0;
	printf(Str);
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
	HANDLE console = GetStdHandle(STD_OUTPUT_HANDLE);
	TSerialDebug Debug;
	TSerialDevice Port1(3, 9600, 'O', 8, 1);
	TSerialDevice Port2(4, 9600, 'O', 8, 1);

	TFile *File = new TFile("raw.dat", 0);
	Port1.Open();
   Port2.Open();

	for (;;)
	{
		if (Port1.Poll())
		{
			Win32GetTics(GetTickCount(), &Debug.TimeMSB, &Debug.TimeLSB);
			Debug.Channel = 1;
			Debug.ch = Port1.Read();
			File->Write(&Debug, sizeof(Debug));
			SetConsoleTextAttribute(console, 9);
			Log(&Debug);
		}

		if (Port2.Poll())
		{
			Win32GetTics(GetTickCount(), &Debug.TimeMSB, &Debug.TimeLSB);
			Debug.Channel = 2;
			Debug.ch = Port2.Read();
			File->Write(&Debug, sizeof(Debug));
			SetConsoleTextAttribute(console, 11);
			Log(&Debug);
		}
	}
}

