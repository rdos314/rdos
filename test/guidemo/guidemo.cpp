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

	x1 = random(width + 200) - 100;
	y1 = random(height + 200) - 100;
	x2 = random(width + 200) - 100;
	y2 = random(height + 200) - 100;
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
	x = random(width + 200) - 100;
	y = random(height + 200) - 100;
	w = random(width + 100);
	h = random(height + 100);
	x -= w / 2;
	y -= h / 2;
	RdosDrawRect(VbeHandle, x, y, w, h);
}

void RandomEllipse()
{
	int x, y;
	int w, h;

	x = random(width + 200) - 100;
	y = random(height + 200) - 100;
	w = random(width + 100);
	h = random(height + 100);
	x -= w / 2;
	y -= h / 2;
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
	x = random(width + 200) - 100;
	y = random(height + 200) - 100;
	x -= w / 2;
	y -= h / 2;
	RdosSetDrawColor(VbeHandle, mkcolor(random(256), random(256), random(256)));
	RdosSetLGOP(VbeHandle, random(11));
	RdosDrawString(VbeHandle, x, y, str);
}

void cdecl main()
{
	int i;

	RdosWaitMilli(250);
	bpp = 32;
	width = 800;
	height = 600;
	VbeHandle = RdosSetVBEMode(&bpp, &width, &height, &rowsize, &buf);
//	RdosSetClipRect(VbeHandle, 100, 100, width - 100, height - 100);

	RdosSetLGOP(VbeHandle, LGOP_ADD);

	RdosSetDrawColor(VbeHandle, mkcolor(0, 0, 255));
	for (i = 0; i < 800; i++)
		RdosDrawLine(VbeHandle, 0, 3 * i, 3 * i, 0);

	RdosWaitMilli(5000);

	RdosSetDrawColor(VbeHandle, mkcolor(0, 255, 0));
	for (i = -250; i < 250; i++)
		RdosDrawLine(VbeHandle, height, width - 3 * i, 3 * i, 0);

	RdosWaitMilli(5000);

	RdosSetDrawColor(VbeHandle, mkcolor(0, 255, 255));
	for (i = -250; i < 250; i++)
		RdosDrawLine(VbeHandle, 0, 3 * i, height - 3 * i, width);

	RdosWaitMilli(5000);

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

