#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "bmp.h"
#include "jpeg.h"
#include "videodev.h"
#include "keyboard.h"
#include "mouse.h"

#define FALSE	0
#define	TRUE	!FALSE

TGraphicDevice *vbe;
TSprite *MouseSprite;
TJpegBitmapDevice *redhead;
TJpegBitmapDevice *neander;
TJpegBitmapDevice *orgneander;
TBmpBitmapDevice *facemask;
TBmpBitmapDevice *backmask;

TMouseDevice *Mouse;
TKeyboardDevice *Keyboard;
int BackActive = FALSE;
int HairActive = FALSE;

int rnorm, gnorm, bnorm, lnorm;
int rneander, gneander, bneander, lneander;

TBitmapGraphicDevice *CreateMouseMask()
{
	TBitmapGraphicDevice *mono;

	mono = new TBitmapGraphicDevice(1, 40, 40);
	mono->SetLgopNone();
	mono->DrawLine(0, 20, 19, 20);
	mono->DrawLine(21, 20, 40, 20);
	mono->DrawLine(20, 0, 20, 19);
	mono->DrawLine(20, 21, 20, 40);

	return mono;
}

TBitmapGraphicDevice *CreateMouseBitmap(TGraphicDevice *dev, int r, int g, int b)
{
	TBitmapGraphicDevice *bitmap;

	bitmap = new TBitmapGraphicDevice(dev->GetBpp(), 40, 40);
	bitmap->SetLgopNone();
	bitmap->SetFilledStyle();
	bitmap->SetDrawColor(r, g, b);
	bitmap->DrawRect(0, 0, 40, 40);

	return bitmap;
}

void UpdateMarker(int x, int y)
{
	int pixel;
	int back;
	int face;
	int r, g, b;
	int lum, rrel, grel, brel;
	char str[80];

	MouseSprite->Move(x, y);

	pixel = vbe->GetPixel(x, y);
	r = getred(pixel);
	g = getgreen(pixel);
	b = getblue(pixel);

	if (x >= 200 && x < 200 + neander->GetWidth() && y >= 0 && y < neander->GetHeight())
	{
		back = backmask->GetPixel(x - 200, y);
		face = facemask->GetPixel(x - 200, y);

		if (BackActive)
		{
			MouseSprite->Hide();
			if (back)
			{
				back = FALSE;
				backmask->SetLgopInv();
			}
			else
			{
				back = TRUE;
				backmask->SetLgopNone();
			}
			backmask->SetPixel(x - 200, y);

			if (face)
			{
				facemask->SetLgopInv();
				facemask->SetPixel(x - 200, y);
			}

			if (back)
			{
				r = 128;
				g = 128;
				b = 128;
			}
			else
			{
				pixel = orgneander->GetPixel(x - 200, y);
				r = getred(pixel);
				g = getgreen(pixel);
				b = getblue(pixel);
			}

			neander->SetDrawColor(r, g, b);
			neander->SetPixel(x - 200, y);
			vbe->SetDrawColor(r, g, b);
			vbe->SetPixel(x, y);
			MouseSprite->Show();
		}

		if (HairActive)
		{
			MouseSprite->Hide();
			face = facemask->GetPixel(x - 200, y);
			if (face)
			{
				face = FALSE;
				facemask->SetLgopInv();
			}
			else
			{
				face = TRUE;
				facemask->SetLgopNone();
			}
			facemask->SetPixel(x - 200, y);

			if (back)
			{
				backmask->SetLgopInv();
				backmask->SetPixel(x - 200, y);
			}

			pixel = orgneander->GetPixel(x - 200, y);
			r = getred(pixel);
			g = getgreen(pixel);
			b = getblue(pixel);

			if (!face)
			{
				r += rnorm - rneander;
				if (r >= 256)
					r = 255;
				if (r < 0)
					r = 0;

				g += gnorm - gneander;
				if (g >= 256)
					g = 255;
				if (g < 0)
					g = 0;

				b += bnorm - bneander;
				if (b >= 256)
					b = 255;
				if (b < 0)
					b = 0;
			}

			neander->SetDrawColor(r, g, b);
			neander->SetPixel(x - 200, y);
			vbe->SetDrawColor(r, g, b);
			vbe->SetPixel(x, y);
			MouseSprite->Show();
		}

	}

	lum = (r + g + b) / 3;
	if (lum)
	{
		rrel = r * 1000 / lum;
		grel = g * 1000 / lum;
		brel = b * 1000 / lum;
	}
	else
	{
		rrel = 1000;
		grel = 1000;
		brel = 1000;
	}

	vbe->SetFilledStyle();
	vbe->SetDrawColor(0, 0, 0);
	vbe->DrawRect(0, 200, 200, 400);

	vbe->SetDrawColor(r, g, b);
	vbe->DrawRect(0, 400, 200, 425);

	vbe->SetDrawColor(rrel * 128 / 1000, 0, 0);
	vbe->DrawRect(0, 425, 50, 450);

	vbe->SetDrawColor(0, grel * 128 / 1000, 0);
	vbe->DrawRect(50, 425, 100, 450);

	vbe->SetDrawColor(0, 0, brel * 128 / 1000);
	vbe->DrawRect(100, 425, 150, 455);

	sprintf(str, "X: %d, Y: %d", x, y);
	vbe->SetDrawColor(255, 255, 255);
	vbe->DrawString(0, 375, str);

	sprintf(str, "R: %d", r);
	vbe->SetDrawColor(255, 0, 0);
	vbe->DrawString(0, 200, str);

	sprintf(str, "G: %d", g);
	vbe->SetDrawColor(0, 255, 0);
	vbe->DrawString(0, 225, str);

	sprintf(str, "B: %d", b);
	vbe->SetDrawColor(0, 0, 255);
	vbe->DrawString(0, 250, str);

	sprintf(str, "Lu: %d", lum);
	vbe->SetDrawColor(255, 255, 255);
	vbe->DrawString(0, 275, str);

	sprintf(str, "Rr: %d", rrel);
	vbe->SetDrawColor(255, 0, 0);
	vbe->DrawString(0, 300, str);

	sprintf(str, "Gr: %d", grel);
	vbe->SetDrawColor(0, 255, 0);
	vbe->DrawString(0, 325, str);

	sprintf(str, "Br: %d", brel);
	vbe->SetDrawColor(0, 0, 255);
	vbe->DrawString(0, 350, str);
}

void MouseMove(TMouseDevice *Mouse, int x, int y, int MouseButton, int KeyState)
{
	UpdateMarker(x, y);
}

void KeyPress(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	int x, y;

	switch (VirtualKey)
	{
		case 'H':
			HairActive = TRUE;
			Mouse->GetPosition(&x, &y);
			UpdateMarker(x, y);
			break;

		case 'B':
			BackActive = TRUE;
			Mouse->GetPosition(&x, &y);
			UpdateMarker(x, y);
			break;

		case 'S':
			facemask->Save("c:\\facemask.bmp");
			backmask->Save("c:\\backmask.bmp");
			neander->Save("c:\\neander2.jpg");
			break;

		case VK_ESCAPE:
			exit(0);

		case VK_RIGHT:
			Mouse->GetPosition(&x, &y);
			x++;
			Mouse->SetPosition(x, y);
			UpdateMarker(x, y);
			break;

		case VK_LEFT:
			Mouse->GetPosition(&x, &y);
			if (x)
				x--;
			Mouse->SetPosition(x, y);
			UpdateMarker(x, y);
			break;

		case VK_DOWN:
			Mouse->GetPosition(&x, &y);
			y++;
			Mouse->SetPosition(x, y);
			UpdateMarker(x, y);
			break;

		case VK_UP:
			Mouse->GetPosition(&x, &y);
			if (y)
				y--;
			Mouse->SetPosition(x, y);
			UpdateMarker(x, y);
			break;
	}
}

void KeyRelease(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	switch (VirtualKey)
	{
		case 'H':
			HairActive = FALSE;
			break;

		case 'B':
			BackActive = FALSE;
			break;
	}
}

void GetRedheadColors()
{
	int x, y;
	int Width, Height;
	int LineSize;
	char *bits;
	char *ptr;
	int pixel;
	int r, g, b;
	int lum, rrel, grel, brel;
	int face;
	int backgr;
	int done;
	int hair;
	int rsum = 0;
	int gsum = 0;
	int bsum = 0;
	int count = 0;

	bits = (unsigned char *)redhead->GetLinear();
	Width = redhead->GetWidth();
	Height = redhead->GetHeight();
	LineSize = redhead->GetLineSize();

	for (y = 0; y < Height; y++)
		for (x = 0; x < Width; x++)
		{
			ptr = bits + LineSize * y + 3 * x;
			pixel = *(int *)ptr;
			r = getred(pixel);
			g = getgreen(pixel);
			b = getblue(pixel);

			lum = (r + g + b) / 3;
			if (lum)
			{
				rrel = r * 1000 / lum;
				grel = g * 1000 / lum;
				brel = b * 1000 / lum;
			}
			else
			{
				rrel = 1000;
				grel = 1000;
				brel = 1000;
			}

			if (rrel >= 1450)
			{
				rsum += r;
				gsum += g;
				bsum += b;
				count++;
			}
		}

	rnorm = rsum / count;
	gnorm = gsum / count;
	bnorm = bsum / count;
	lnorm = (rnorm + gnorm + bnorm) / 3;
}

void GetNeanderMasks()
{
	int x, y;
	int Width, Height;
	int LineSize;
	char *bits;
	char *ptr;
	int pixel;
	int r, g, b;
	int lum, rrel, grel, brel;
	int face;
	int backgr;
	int done;
	int hair;

	if (facemask)
		delete facemask;
	facemask = new TBmpBitmapDevice(1, neander->GetWidth(), neander->GetHeight());
	facemask->SetLgopNone();

	if (backmask)
		delete backmask;
	backmask = new TBmpBitmapDevice(1, neander->GetWidth(), neander->GetHeight());
	backmask->SetLgopNone();

	bits = (unsigned char *)neander->GetLinear();
	Width = neander->GetWidth();
	Height = neander->GetHeight();
	LineSize = neander->GetLineSize();

	for (y = 0; y < Height; y++)
		for (x = 0; x < Width; x++)
		{
			ptr = bits + LineSize * y + 3 * x;
			pixel = *(int *)ptr;
			r = getred(pixel);
			g = getgreen(pixel);
			b = getblue(pixel);

			lum = (r + g + b) / 3;
			if (lum)
			{
				rrel = r * 1000 / lum;
				grel = g * 1000 / lum;
				brel = b * 1000 / lum;
			}
			else
			{
				rrel = 1000;
				grel = 1000;
				brel = 1000;
			}

			backgr = FALSE;

			if (y <= 100)
				backgr = TRUE;

			if (x >= 440 && y <= 400)
				backgr = TRUE;

			if (x >= 420 && y <= 240)
				backgr = TRUE;

			if (x >= 400 && y <= 175)
				backgr = TRUE;

			hair = TRUE;
			if (x <= 40 && y <= 490)
				hair = FALSE;

			if (x <= 70 && y <= 75)
				hair = FALSE;

			if (x <= 100 && y <= 35)
				hair = FALSE;

			if (x >= 490 && y <= 90)
				hair = FALSE;

			if (x >= 480 && y <= 65)
				hair = FALSE;

			if (backgr)
				face = FALSE;
			else
			{
				face = FALSE;
				if (x >= 240 && x <= 370 && y >= 320 && y <= 380)
					face = TRUE;

				if (x >= 170 && x <= 400 && y >= 180 && y <= 290)
					face = TRUE;

				if (x >= 230 && x <= 360 && y >= 265 && y <= 320)
					face = TRUE;
			}

			done = FALSE;

			if (hair)
			{
				if (backgr)
				{
					if (rrel < 1000 && grel > 1000)
						done = TRUE;
				}
				else
				{
					if (rrel < 1000 && grel > 1000 && lum < 125)
						done = TRUE;
				}
			}
			else
				done = TRUE;

			if (done)
				backmask->SetPixel(x, y);
			else
			{
				if (backgr)
					done = TRUE;
				else
				{
					if (!face && (lum <= 110 || rrel >= 1450))
						done = TRUE;
				}

				if (!done)
					facemask->SetPixel(x, y);
			}
		}

}

void GetNeanderColors()
{
	int x, y;
	int Width, Height;
	int LineSize;
	char *bits;
	char *ptr;
	int pixel;
	int r, g, b;
	int lum, rrel, grel, brel;
	int face;
	int backgr;
	int rsum = 0;
	int gsum = 0;
	int bsum = 0;
	int count = 0;

	bits = (unsigned char *)neander->GetLinear();
	Width = neander->GetWidth();
	Height = neander->GetHeight();
	LineSize = neander->GetLineSize();

	for (y = 0; y < Height; y++)
		for (x = 0; x < Width; x++)
		{
			ptr = bits + LineSize * y + 3 * x;
			pixel = *(int *)ptr;
			r = getred(pixel);
			g = getgreen(pixel);
			b = getblue(pixel);

			lum = (r + g + b) / 3;
			if (lum)
			{
				rrel = r * 1000 / lum;
				grel = g * 1000 / lum;
				brel = b * 1000 / lum;
			}
			else
			{
				rrel = 1000;
				grel = 1000;
				brel = 1000;
			}

			face = facemask->GetPixel(x, y);
			backgr = backmask->GetPixel(x, y);

			if (!face && !backgr)
			{
				rsum += r;
				gsum += g;
				bsum += b;
				count++;
			}
		}

	rneander = rsum / count;
	gneander = gsum / count;
	bneander = bsum / count;
	lneander = (rneander + gneander + bneander) / 3;
}

int GetMean(TBitmapGraphicDevice *dev, int x, int y, int R, int *rv, int *gv, int *bv)
{
	int cx, cy;
	int tr, tg, tb;
	int tlum;
	int count;
	char *ptr;
	char *bits;
	int LineSize;
	int pixel;
	int r, g, b;
	int lum;
	int ystart;
	TBitmapGraphicDevice mdev(1, 2 * R + 1,  2 * R + 1);
	TBitmapGraphicDevice cdev(neander->GetBpp(), 2 * R + 1, 2 * R + 1);

	mdev.SetFilledStyle();
	bits = (char *)cdev.GetLinear();
	LineSize = cdev.GetLineSize();

	if (y < R)
		ystart = R - y;
	else
		ystart = 0;

	mdev.DrawEllipse(R, R, R, R);
	mdev.SetLgopAnd();
	if (y < R)
		mdev.Blit(dev, x - R, 0, 0, ystart, 2 * R + 1, 2 * R + 1 - ystart);
	else
		mdev.Blit(dev, x - R, y - R, 0, 0, 2 * R + 1, 2 * R + 1);
	mdev.SetLgopXor();
	mdev.DrawRect(0, 0, 2 * R + 1, 2 * R + 1);

	if (y < R)
		cdev.Blit(orgneander, x - R, 0, 0, ystart, 2 * R + 1, 2 * R + 1 - ystart);
	else
		cdev.Blit(orgneander, x - R, y - R, 0, 0, 2 * R + 1, 2 * R + 1);
	cdev.SetDrawColor(255, 255, 255);
	cdev.Blit(&mdev, 0, 0, 0, 0, 2 * R + 1, 2 * R + 1);

	count = 0;
	tlum = 0;
	tr = 0;
	tg = 0;
	tb = 0;

	for (cy = ystart; cy < 2 * R + 1; cy++)
		for (cx = 0; cx < 2 * R + 1; cx++)
		{
			ptr = bits + LineSize * cy + 3 * cx;
			pixel = *(int *)ptr;
			r = getred(pixel);
			g = getgreen(pixel);
			b = getblue(pixel);
			lum = (r + g + b) / 3;
			if (lum != 255)
			{
				count++;
				tlum += lum;
				tr += r;
				tg += g;
				tb += b;
			}
		}

	if (count)
	{
		if (rv)
			*rv = tr / count;

		if (gv)
			*gv = tg / count;

		if (bv)
			*bv = tb / count;

		return tlum / count;
	}
	return 0;
}

int GetPixelDiff(TBitmapGraphicDevice *dev, int x, int y, int R)
{
	int pixel;
	int r, g, b;
	int lum, tlum;
	int diff;

	tlum = GetMean(dev, x, y, R, 0, 0, 0);
	if (tlum)
	{
		pixel = orgneander->GetPixel(x, y);
		r = getred(pixel);
		g = getgreen(pixel);
		b = getblue(pixel);

		lum = (r + g + b) / 3;

		diff = lum - tlum;
		if (diff < 0)
			diff = -diff;

		if (tlum)
			return diff * 100 / tlum;
	}

	return 0;
}

void ProcessBorders(TBitmapGraphicDevice *dev, int maxdiff, int x, int y, int R)
{
	if (GetPixelDiff(dev, x, y, R) >= maxdiff)
	{
		dev->SetLgopInv();
		dev->SetPixel(x, y);
	}
	else
	{
		dev->SetLgopNone();
		dev->SetPixel(x, y);
	}
}

void FixupBorders()
{
	int R;
	int x, y;
	int backgr;
	int pos;
	int rlowdiff, rhighdiff;
	int glowdiff, ghighdiff;
	int blowdiff, bhighdiff;
	int min, max;
	int pixel;
	int r, g, b;
	int lum, tlum;
	int tr, tg, tb;
	int diff;
	int doit;

	R = 20;

	RdosWriteString("Low R diff %> ");
	if (scanf("%d", &rlowdiff) != 1)
		rlowdiff = -25;

	RdosWriteString("High R diff %> ");
	if (scanf("%d", &rhighdiff) != 1)
		rhighdiff = 25;

	RdosWriteString("Low G diff %> ");
	if (scanf("%d", &glowdiff) != 1)
		glowdiff = -25;

	RdosWriteString("High G diff %> ");
	if (scanf("%d", &ghighdiff) != 1)
		ghighdiff = 25;

	RdosWriteString("Low B diff %> ");
	if (scanf("%d", &blowdiff) != 1)
		blowdiff = -25;

	RdosWriteString("High B diff %> ");
	if (scanf("%d", &bhighdiff) != 1)
		bhighdiff = 25;

	for (y = 0; y < neander->GetHeight(); y++)
	{
		for (x = 0; x < neander->GetWidth(); x++)
		{
			backgr = backmask->GetPixel(x, y);
			if (backgr == 0)
				break;
		}

		if (x)
		{
			pos = x - 40;
			if (pos < 0)
				pos = 0;

			for (x = pos; x < pos + 50; x++)
				ProcessBorders(backmask, 20, x, y, 10);
		}
	}

	for (y = 0; y < neander->GetHeight(); y++)
	{
		for (x = neander->GetWidth() - 1; x; x--)
		{
			backgr = backmask->GetPixel(x, y);
			if (backgr == 0)
				break;
		}

		if (x != neander->GetWidth() - 1)
		{
			pos = x - 20;
			if (pos >= neander->GetWidth())
				pos = neander->GetWidth() - 1;

			for (x = pos; x < pos + 60; x++)
				ProcessBorders(backmask, 20, x, y, 10);
		}
	}

	tlum = GetMean(facemask, 215, 290, 40, &tr, &tg, &tb);

	for (y = 0; y < 200; y++)
	{
		for (x = neander->GetWidth() - 1; x; x--)
		{
			backgr = facemask->GetPixel(x, y);
			if (backgr != 0)
				break;
		}

		if (x)
		{
			max = x + 20;

			for (x = 0; x < neander->GetWidth(); x++)
			{
				backgr = facemask->GetPixel(x, y);
				if (backgr != 0)
					break;
			}

			min = x - 20;

			if (min < 0)
				min = 0;

			if (max >= neander->GetWidth())
				max = neander->GetWidth() - 1;

			for (x = min; x < max; x++)
			{
				pixel = orgneander->GetPixel(x, y);
				r = getred(pixel);
				g = getgreen(pixel);
				b = getblue(pixel);

				lum = (r + g + b) / 3;

				doit = FALSE;

				diff = r - tr;

				if (diff <= rlowdiff)
					doit = TRUE;

				if (diff >= rhighdiff)
					doit = TRUE;

				diff = g - tg;

				if (diff <= glowdiff)
					doit = TRUE;

				if (diff >= ghighdiff)
					doit = TRUE;

				diff = b - tb;

				if (diff <= blowdiff)
					doit = TRUE;

				if (diff >= bhighdiff)
					doit = TRUE;

				if (doit)
				{
					facemask->SetLgopInv();
					facemask->SetPixel(x, y);
				}
				else
				{
					facemask->SetLgopNone();
					facemask->SetPixel(x, y);
				}
			}
		}
	}

	for (y = 201; y < neander->GetHeight(); y++)
	{
		for (x = 0; x < neander->GetWidth(); x++)
		{
			backgr = facemask->GetPixel(x, y);
			if (backgr != 0)
				break;
		}

		if (x)
		{
			pos = x - 40;
			if (pos < 0)
				pos = 0;

			for (x = pos; x < pos + 50; x++)
				ProcessBorders(facemask, 20, x, y, 20);
		}
	}

	for (y = 201; y < neander->GetHeight(); y++)
	{
		for (x = neander->GetWidth() - 1; x; x--)
		{
			backgr = facemask->GetPixel(x, y);
			if (backgr != 0)
				break;
		}

		if (x != neander->GetWidth() - 1)
		{
			pos = x - 20;
			if (pos >= neander->GetWidth())
				pos = neander->GetWidth() - 1;

			for (x = pos; x < pos + 60; x++)
				ProcessBorders(facemask, 20, x, y, 20);
		}
	}
}

void ProcessNeander()
{
	int x, y;
	int Width, Height;
	int LineSize;
	char *bits;
	char *ptr;
	int pixel;
	int r, g, b;
	int lum, rrel, grel, brel;
	int face;
	int backgr;
	int rdiff, gdiff, bdiff;
	int ldiff;

	ldiff = lnorm - lneander;

	rdiff = rnorm - rneander - ldiff;
	gdiff = gnorm - gneander - ldiff;
	bdiff = bnorm - bneander - ldiff;

	bits = (unsigned char *)neander->GetLinear();
	Width = neander->GetWidth();
	Height = neander->GetHeight();
	LineSize = neander->GetLineSize();

	for (y = 0; y < Height; y++)
		for (x = 0; x < Width; x++)
		{
			ptr = bits + LineSize * y + 3 * x;
			pixel = *(int *)ptr;
			r = getred(pixel);
			g = getgreen(pixel);
			b = getblue(pixel);

			lum = (r + g + b) / 3;
			if (lum)
			{
				rrel = r * 1000 / lum;
				grel = g * 1000 / lum;
				brel = b * 1000 / lum;
			}
			else
			{
				rrel = 1000;
				grel = 1000;
				brel = 1000;
			}

			face = facemask->GetPixel(x, y);
			backgr = backmask->GetPixel(x, y);

			if (backgr)
			{
				pixel = pixel & 0xFF000000;
				pixel = pixel | mkcolor(128, 128, 128);
				*(int *)ptr = pixel;
			}

			if (!face && !backgr)
			{
				r += rdiff;
				if (r >= 256)
					r = 255;
				if (r < 0)
					r = 0;

				g += gdiff;
				if (g >= 256)
					g = 255;
				if (g < 0)
					g = 0;

				b += bdiff;
				if (b >= 256)
					b = 255;
				if (b < 0)
					b = 0;

				pixel = pixel & 0xFF000000;
				pixel = pixel | mkcolor(r, g, b);
				*(int *)ptr = pixel;
			}
		}
}

void main()
{
	TFont *font;
	TWait *Wait;
	TWaitDevice *WaitDevice;
	TGraphicDevice *MouseMask;
	TGraphicDevice *MouseBitmap;
	int ext, state, vk, sc;
	char str[80];
	TBitmapGraphicDevice *jessica;

	RdosWaitMilli(250);

	Wait = new TWait();

	redhead = TJpegBitmapDevice::Create("redhead.jpg");
	GetRedheadColors();

	orgneander = TJpegBitmapDevice::Create("neander.jpg");
	neander = new TJpegBitmapDevice(orgneander);
	neander->Blit(orgneander, 0, 0, 0, 0, orgneander->GetWidth(), orgneander->GetHeight());

	facemask = TBmpBitmapDevice::Create("facemask.bmp");
	backmask = TBmpBitmapDevice::Create("backmask.bmp");

	if (facemask == 0 && backmask == 0)
	{
		GetNeanderMasks();
		facemask->Save("c:\\facemask.bmp");
		backmask->Save("c:\\backmask.bmp");
	}

	GetNeanderColors();

	FixupBorders();

	ProcessNeander();
	neander->Save("c:\\neander2.jpg");

	jessica = TJpegBitmapDevice::Create("d:\\linnea.jpg");

	vbe = new TVideoGraphicDevice(24, 1280, 1024);

	vbe->Blit(jessica, 0, 0, 0, 0, jessica->GetWidth(), jessica->GetHeight());

	font = new TFont(20);
	vbe->SetFont(font);

	sprintf(str, "Rr: %d", rnorm);
	vbe->SetDrawColor(255, 0, 0);
	vbe->DrawString(0, 500, str);

	sprintf(str, "Gr: %d", gnorm);
	vbe->SetDrawColor(0, 255, 0);
	vbe->DrawString(0, 525, str);

	sprintf(str, "Br: %d", bnorm);
	vbe->SetDrawColor(0, 0, 255);
	vbe->DrawString(0, 550, str);

	Keyboard = new TKeyboardDevice(Wait);
	Keyboard->OnKeyPress = KeyPress;
	Keyboard->OnKeyRelease = KeyRelease;

	Mouse = new TMouseDevice(Wait);
	Mouse->OnMove = MouseMove;

	Mouse->SetWindow(0, 0, vbe->GetWidth(), vbe->GetHeight());
	Mouse->SetMickey(1, 1);
	Mouse->SetPosition(vbe->GetWidth() / 2, vbe->GetHeight() / 2);

	MouseMask = CreateMouseMask();
	MouseBitmap = CreateMouseBitmap(vbe, 255, 255, 255);
	MouseSprite = vbe->CreateSprite(MouseBitmap, MouseMask, 20, 20);
	MouseSprite->Show();

	vbe->Blit(redhead, 0, 0, 0, 0, redhead->GetWidth(), redhead->GetHeight());
	vbe->Blit(neander, 0, 0, 200, 0, neander->GetWidth(), neander->GetHeight());

	Wait->Execute();
}

