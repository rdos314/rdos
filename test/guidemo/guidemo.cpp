#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

int VbeHandle;
int bpp;
int width;
int height;
int rowsize;
void *buf;
int count = 0;
int font;

void RandomLine()
{
	int x1, y1;
	int x2, y2;

	x1 = random(width);
	y1 = random(height);
	x2 = random(width);
	y2 = random(height);
	RdosSetDrawColor(VbeHandle, mkcolor(random(256), random(256), random(256)));
	RdosSetLGOP(VbeHandle, random(11));
	RdosDrawLine(VbeHandle, x1, y1, x2, y2);
}

void RandomRect()
{
	int x, y;
	int w, h;

	RdosSetDrawColor(VbeHandle, mkcolor(random(256), random(256), random(256)));
	RdosSetLGOP(VbeHandle, random(11));
	if (random(2) == 0)
		RdosSetHollowStyle(VbeHandle);
	else
		RdosSetFilledStyle(VbeHandle);
	x = random(width);
	y = random(height);
	w = random(width - x);
	h = random(height - y);
	RdosDrawRect(VbeHandle, x, y, w, h);
}

void RandomEllipse()
{
	int x, y;
	int w, h;

	x = random(width);
	y = random(height);
	w = random(width - x);
	h = random(height - y);
	RdosSetDrawColor(VbeHandle, mkcolor(random(256), random(256), random(256)));
	RdosSetLGOP(VbeHandle, random(11));
	if (random(2) == 0)
		RdosSetHollowStyle(VbeHandle);
	else
		RdosSetFilledStyle(VbeHandle);
	RdosDrawEllipse(VbeHandle, x, y, w, h);
}

void RandomText()
{
	int x, y;
	int w, h;
	char str[80];

	sprintf(str, "%d", count);
	RdosGetStringMetrics(font, str, &w, &h);
	x = random(width - w);
	y = random(height - h);
	RdosSetDrawColor(VbeHandle, mkcolor(random(256), random(256), random(256)));
	RdosSetLGOP(VbeHandle, random(11));
	RdosDrawString(VbeHandle, x, y, str);
}

void cdecl main()
{
	RdosWaitMilli(250);
	bpp = 32;
	width = 800;
	height = 600;
	VbeHandle = RdosSetVBEMode(&bpp, &width, &height, &rowsize, &buf);
	RdosSetClipRect(VbeHandle, 100, 100, width - 100, height - 100);
	font = RdosOpenFont(60);
	RdosSetFont(VbeHandle, font);
	for (;;)
	{
		count++;
		switch (random(4))
		{
			case 0:
				RandomLine();
				break;

			case 1:
				RandomRect();
				break;

			case 2:
				RandomEllipse();
				break;

			case 3:
				RandomText();
				break;
		}
	}
}

