#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

//#define DEBUG	1

#define FALSE	0
#define TRUE	!FALSE

int VbeHandle;
int bpp;
int width;
int height;
int rowsize;
int sprite;
void *buf;
int counter = 0;

#define MAX_PLANETS	75

struct TPlanet
{
	long x;
	long y;
	int r;
	long vx;
	long vy;
	long gx;
	long gy;
	long ela;
	long m;
	long vmax;
	int handle;
	int bitmap;
	int mask;
	int hide;
	int recreate;
};

TPlanet *PlanetArr[MAX_PLANETS];
long m0 = 1000;

int font;
char str[60];

void CreateSprite(TPlanet *planet)
{
	int w;
	int i;
	int r, g, b;
	char cr, cg, cb;

	w = 2 * planet->r;
	planet->r;
	planet->bitmap = RdosCreateBitmap(bpp, w, w);
	RdosSetLGOP(planet->bitmap, LGOP_NONE);
	RdosSetFilledStyle(planet->bitmap);

	r = 1024 / w;
	g = 128;
	b = 4 * w;

	for (i = planet->r; i > 2; i--)
	{
		if (r * (planet->r - i) / 10 > 127)
			cr = 255;
		else
			cr = 128 + r * i / 10;

		if (g * (planet->r - i) / 10 > 127)
			cg = 255;
		else
			cg = 128 + g * i / 10;

		if (b * (planet->r - i) / 10 > 127)
			cb = 255;
		else
			cb = 128 + b * i / 10;

		RdosSetDrawColor(planet->bitmap, mkcolor(cr, cg, cb));
		RdosDrawEllipse(planet->bitmap, planet->r - i, planet->r - i, 2 * i, 2 * i);
	}

	planet->mask = RdosCreateBitmap(1, w, w);
	RdosSetLGOP(planet->mask, LGOP_NONE);
	RdosSetFilledStyle(planet->mask);
	RdosDrawEllipse(planet->mask, 0, 0, w, w);

	planet->handle = RdosCreateSprite(VbeHandle, planet->bitmap, planet->mask, LGOP_NONE);
	if (planet->x / 100 < planet->r)
		planet->x = 100 * planet->r;

	if (planet->y / 100 < planet->r)
		planet->y = 100 * planet->r;

	if (planet->x > (width - planet->r - 2) * 100)
		planet->x = 100 * (width - planet->r - 2);

	if (planet->y > (height - planet->r - 2) * 100)
		planet->y = 100 * (height - planet->r - 2);

	RdosMoveSprite(planet->handle, planet->x / 100 - planet->r, planet->y / 100 - planet->r);
}

void CloseSprite(TPlanet *planet)
{
	RdosHideSprite(planet->handle);
	RdosCloseBitmap(planet->bitmap);
	RdosCloseBitmap(planet->mask);
	RdosCloseSprite(planet->handle);
}

void CreatePlanet(TPlanet *planet)
{
	planet->recreate = TRUE;

	planet->ela = random(90);
	planet->m = 2500 * random(100) / 100 + 10;
	m0 = m0 * 19 / 18;
	for (planet->r = 3; planet->r < height / 2; planet->r++)
		if (planet->r * planet->r * planet->r * 25 > planet->m)
			break;

	switch (random(4))
	{
		case 0:
			planet->x = planet->r;
			planet->y = random(100) * (height - planet->r);
			planet->vx = random(1000);
			planet->vy = random(1000);
			break;

		case 1:
			planet->x = (width - planet->r) * 100;
			planet->y = random(100)* (height - planet->r);
			planet->vx = -random(1000);
			planet->vy = random(1000);
			break;

		case 2:
			planet->x = random(100) * (width - planet->r);
			planet->y = planet->r;
			planet->vx = random(1000);
			planet->vy = random(1000);
			break;

		case 3:
			planet->x = random(100) * (width - planet->r);
			planet->y = (height - planet->r) * 100;
			planet->vx = random(1000);
			planet->vy = -random(1000);
			break;
	}

	planet->vmax = 1500;
}

void UpdatePlanets()
{
	long fx, fy;
	int i, j;
	long m;
	long r2;
	long dx, dy;
	long mrel;
	long min;
	long mvx, mvy;
	long temp;
	TPlanet *planet;
	TPlanet *comp;
	int changed;
	int x, y;

	for (i = 0; i < MAX_PLANETS; i++)
	{
		planet = PlanetArr[i];

		if (planet)
		{

			fx = 0;
			fy = 0;

			for (j = 0; j < MAX_PLANETS; j++)
			{

				comp = PlanetArr[j];
				if (comp)
				{
					m = planet->m + comp->m;
					dx = planet->x - comp->x;
					dy = planet->y - comp->y;
					r2 = dx / 100 * dx + dy / 100 * dy;
					min = 10 * planet->r + 10 * comp->r;

					if (r2 >= min * min)
					{
						if (dx)
						{
							temp = r2 / dx;
							fx += m / temp;
						}

						if (dy)
						{
							temp = r2 / dy;
							fy += m / temp;
						}
					}
				}
			}

			planet->gx = -fx * 100 / planet->m;
			planet->gy = -fy * 100 / planet->m;
		}
	}

	for (i = 0; i < MAX_PLANETS; i++)
	{
		planet = PlanetArr[i];
		if (planet)
		{
			planet->vx += planet->gx;
			planet->vy += planet->gy;
		}
	}

	for (i = 0; i < MAX_PLANETS; i++)
	{
		planet = PlanetArr[i];
		if (planet)
		{
			planet->x += planet->vx / 10;
			planet->y += planet->vy / 10;

			if (planet->x / 100 < planet->r)
			{
				planet->vx = -planet->vx * planet->ela / 100;
				planet->x = 100 * planet->r - (planet->x - 100 * planet->r) * planet->ela / 100;
			}

			if (planet->y / 100 < planet->r)
			{
				planet->vy = -planet->vy * planet->ela / 100;
				planet->y = 100 * planet->r - (planet->y - 100 * planet->r) * planet->ela / 100;
			}

			temp = (width - planet->r - 2) * 100;
			if (planet->x > temp)
			{
				planet->vx = -planet->vx * planet->ela / 100;

				planet->x = temp - (planet->x - temp) * planet->ela / 100;
			}

			temp = (height - planet->r - 2) * 100;
			if (planet->y > temp)
			{
				planet->vy = -planet->vy * planet->ela / 100;
				planet->y = temp - (planet->y - temp) * planet->ela / 100;
			}
		}
	}

	for (i = 0; i < MAX_PLANETS; i++)
	{
		planet = PlanetArr[i];

		if (planet)
		{

			if (planet->vx * planet->vx + planet->vy * planet->vy +
						planet->gx * planet->gx + planet->gy * planet->gy  == 0)
				CreatePlanet(planet);

			if (planet->r > 30)
				CreatePlanet(planet);
		}
	}

	changed = TRUE;

	while (changed)
	{
		changed = FALSE;

		for (i = 0; i < MAX_PLANETS; i++)
		{
			planet = PlanetArr[i];

			if (planet)
			{
				for (j = i + 1; j < MAX_PLANETS; j++)
				{
					comp = PlanetArr[j];
					if (comp)
					{
						dx = planet->x - comp->x;
						dy = planet->y - comp->y;
						r2 = dx / 100 * dx + dy / 100 * dy;
						min = 10 * planet->r + 10 * comp->r;
						if (r2 < min * min)
						{
							changed = TRUE;
							mvx = planet->m * planet->vx + comp->m * comp->vx;
							mvy = planet->m * planet->vy + comp->m * comp->vy;
							planet->m += comp->m;
							planet->vx = mvx / planet->m;
							planet->vy = mvy / planet->m;

							if (planet->m > comp->m)
							{
								mrel = planet->m * 10 / comp->m;
								if (mrel > 0 && mrel < 100)
								{
									planet->x = 100 * (planet->x / 100 * mrel + comp->x / 10) / (10 + mrel);
									planet->y = 100 * (planet->y / 100 * mrel + comp->y / 10) / (10 + mrel);
								}
							}
							else
							{
								mrel = comp->m * 10 / planet->m;
								if (mrel > 0 && mrel < 100)
								{
									planet->x = 100 * (comp->x / 100 * mrel + planet->x / 10) / (10 + mrel);
									planet->y = 100 * (comp->y / 100 * mrel + planet->y / 10) / (10 + mrel);
								}
								else
								{
									planet->x = comp->x;
									planet->y = comp->y;
								}
							}

							for (planet->r = 3; planet->r < height / 2; planet->r++)
								if (planet->r * planet->r * planet->r * 25 > planet->m)
									break;

							planet->recreate = TRUE;
							CreatePlanet(comp);
						}
					}
				}
			}
		}
	}

	for (i = MAX_PLANETS - 1; i >= 0 ; i--)
	{
		planet = PlanetArr[i];
		if (planet)
		{
			if (planet->recreate)
				CloseSprite(planet);

			if (planet->recreate)
				CreateSprite(planet);

			planet->hide = FALSE;
			planet->recreate = FALSE;
		}
	}

	for (i = 0; i < MAX_PLANETS; i++)
	{
		planet = PlanetArr[i];
		if (planet)
		{
			for (j = i + 1; j < MAX_PLANETS; j++)
			{
				comp = PlanetArr[j];
				if (comp)
				{
					dx = planet->x / 100 - comp->x / 100;
					if (dx < 0)
						dx = -dx;

					dy = planet->y / 100 - comp->y / 100;
					if (dy < 0)
						dy = -dy;

					temp = planet->r + comp->r + 1;

					if (dx <= temp && dy <= temp)
					{
						planet->hide = TRUE;
						comp->hide = TRUE;
					}
				}
			}
		}
	}

#ifdef DEBUG
	RdosSetDrawColor(VbeHandle, 0);
	RdosDrawRect(VbeHandle, 0, height + MAX_PLANETS / 4 * 15, width, 15);
	sprintf(str, "%d", counter);
	RdosSetDrawColor(VbeHandle, mkcolor(0, 255, 0));
	RdosDrawString(VbeHandle, 0, height + MAX_PLANETS / 4 * 15, str);
	counter++;

	for (i = 0; i < MAX_PLANETS; i++)
	{
		planet = PlanetArr[i];
		if (planet)
		{
			if (i % 4 == 0)
			{
				RdosSetDrawColor(VbeHandle, 0);
				RdosDrawRect(VbeHandle, 0, height + i / 4 * 15, width, 15);
			}

			sprintf(	str,
							"%d, r=%d, x=%d, y=%d",
							i,
							PlanetArr[i]->r,
							PlanetArr[i]->x / 100, PlanetArr[i]->y / 100);
			RdosSetDrawColor(VbeHandle, mkcolor(255, 0, 0));
			RdosDrawString(VbeHandle, (i % 4) * width / 4, height + i / 4 * 15, str);
		}
	}

#endif

	for (i = 0; i < MAX_PLANETS; i++)
	{
		planet = PlanetArr[i];
		if (planet)
		{
			x = planet->x / 100 - planet->r;
			y = planet->y / 100 - planet->r;
			if (x >= 0 && y >= 0 && x < width && y < height)
			{
				RdosMoveSprite(planet->handle, x, y);
				RdosShowSprite(planet->handle);
			}
			else
				RdosHideSprite(planet->handle);
		}
	}

}

struct TPos
{
	int x1;
    int y1;
	int x2;
    int y2;
};

#define POS_COUNT   12

TPos Pos[POS_COUNT] =
            {
				{552,     201,     567,     185},
                {551,     201,     567,     186},
                {551,     201,     567,     187},
                {551,     200,     567,     188},
				{550,     200,     568,     189},
				{550,     200,     568,     189},
                {549,     199,     568,     190},
                {549,     199,     569,     191},
                {548,     199,     568,     192},
                {548,     199,     568,     193},
                {548,     198,     569,     194},
                {547,     198,     569,     195}
            };
            

void SimPos()
{
    int i;

    TPlanet *planet1;
	TPlanet *planet2;

    planet1 = new TPlanet;
	planet2 = new TPlanet;

    planet1->r = 10;
    planet2->r = 8;

	planet1->x = Pos[0].x1;
	planet1->y = Pos[0].y1;
    planet2->x = Pos[0].x2;
    planet2->y = Pos[0].y2;

    CreateSprite(planet1);
    CreateSprite(planet2);

	RdosShowSprite(planet1->handle);
	RdosShowSprite(planet2->handle);


	for (i = 1; i < POS_COUNT; i++)
	{
		RdosReadKeyboard();
        planet1->x = Pos[i].x1;
		planet1->y = Pos[i].y1;
        planet2->x = Pos[i].x2;
		planet2->y = Pos[i].y2;
        RdosMoveSprite(planet1->handle, planet1->x - planet1->r, planet1->y - planet1->r);
        RdosMoveSprite(planet2->handle, planet2->x - planet2->r, planet2->y - planet2->r);
    }        

	for (;;)
		RdosWaitMilli(10);
}

void cdecl main()
{
	int i;

	RdosWaitMilli(250);
	bpp = 32;
	width = 800;
	height = 600;
	VbeHandle = RdosSetVBEMode(&bpp, &width, &height, &rowsize, &buf);
	if (VbeHandle == 0)
	{
		RdosSetFocus(0x3D);
		exit(1);
	}

#ifdef DEBUG
	height -= 100;
#else
	randomize();
#endif

	font = RdosOpenFont(15);
	RdosSetFont(VbeHandle, font);
	RdosSetFilledStyle(VbeHandle);

//	SimPos();

	for (i = 0; i < MAX_PLANETS; i++)
	{
		PlanetArr[i] = new TPlanet;
		CreatePlanet(PlanetArr[i]);
	}

	for (;;)
	{
//		if (counter > 6025)
//		{
//			RdosWaitMilli(750);
//		}
		UpdatePlanets();
	}
}

