#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "bitdev.h"
#include "videodev.h"

#define FALSE	0
#define TRUE	!FALSE

void cdecl main()
{
	int i;
	TGraphicDevice *vbe;
	TFont *font;
	int channel;
	int val;
	char str[20];
	int x, y;
	long double mv[16];

	RdosWaitMilli(250);

	vbe = new TVideoGraphicDevice(16, 800, 600);

	font = new TFont(16);
	vbe->SetFont(font);
	vbe->SetFilledStyle();
    vbe->SetLgopNone();

	for (;;)
	{
		for (channel = 0; channel < 16; channel++)
			mv[channel] = 0;

		for (i = 0; i < 100; i++)
		{
			for (channel = 0; channel < 16; channel++)
			{
				val = RdosReadAD(channel);
				mv[channel] += (long double)val / 32768.0 * 10000.0;
			}
			RdosWaitMilli(10);
		}

		for (channel = 0; channel < 16; channel++)
		{
			sprintf(str, "%7.1LfmV", mv[channel] / 100.0);
			x = 120 * (channel / 8);
			y = 16 * (channel % 8);
			vbe->SetDrawColor(0, 0, 0);
			vbe->DrawRect(x, y, x + 120, y + 16);
			vbe->SetDrawColor(255, 255, 255);
			vbe->DrawString(x, y, str);
		}
	}
}

