#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "bitdev.h"
#include "vbedev.h"
#include "planet.h"

#define MAX_PLANETS	8

#define FALSE	0
#define TRUE	!FALSE

int count = 0;

TPlanet *PlanetArr[MAX_PLANETS];

void RandomColor(TGraphicDevice *dev)
{
	dev->SetDrawColor(random(256), random(256), random(256));
}  

void RandomLgop(TGraphicDevice *dev)
{
    switch (random(12))
    {
        case 0:
            dev->SetLgopNone();
            break;

        case 1:
            dev->SetLgopNull();
			break;

        case 2:
            dev->SetLgopOr();
            break;

        case 3:
            dev->SetLgopAnd();
            break;

        case 4:
            dev->SetLgopXor();
            break;

        case 5:
            dev->SetLgopInv();
            break;

        case 6:
            dev->SetLgopInvOr();
            break;

        case 7:
            dev->SetLgopInvAnd();
			break;

        case 8:
            dev->SetLgopInvXor();
            break;

        case 9:
            dev->SetLgopAdd();
            break;

        case 10:
            dev->SetLgopSub();
            break;

        case 11:
            dev->SetLgopMul();
            break;
    }
}  

void RandomFillStyle(TGraphicDevice *dev)
{
	if (random(2) == 0)
		dev->SetHollowStyle();
	else
		dev->SetFilledStyle();
}

void RandomLine(TGraphicDevice *dev)
{
	int x1, y1;
	int x2, y2;

	x1 = random(dev->GetWidth() + 200) - 100;
	y1 = random(dev->GetHeight() + 200) - 100;
	x2 = random(dev->GetWidth() + 200) - 100;
	y2 = random(dev->GetHeight() + 200) - 100;

    RandomColor(dev);
    RandomLgop(dev);

    dev->DrawLine(x1, y1, x2, y2);
}

void RandomRect(TGraphicDevice *dev)
{
	int x1, y1;
	int x2, y2;

	x1 = random(dev->GetWidth() + 200) - 100;
	y1 = random(dev->GetHeight() + 200) - 100;
	x2 = random(dev->GetWidth() + 200) - 100;
	y2 = random(dev->GetHeight() + 200) - 100;

    RandomColor(dev);
    RandomLgop(dev);
    RandomFillStyle(dev);

	dev->DrawRect(x1, y1, x2, y2);
}

void RandomEllipse(TGraphicDevice *dev)
{
	int x, y;
	int rx, ry;

	x = random(dev->GetWidth() + 200) - 100;
	y = random(dev->GetHeight() + 200) - 100;
	rx = random(dev->GetWidth() / 2 + 100);
	ry = random(dev->GetHeight() / 2 + 100);

    RandomColor(dev);
	RandomLgop(dev);
    RandomFillStyle(dev);
    
	dev->DrawEllipse(x, y, rx, ry);
}

void RandomText(TGraphicDevice *dev)
{
	int x, y;
	char str[80];

	x = random(dev->GetWidth() + 200) - 100;
	y = random(dev->GetHeight() + 200) - 100;

	sprintf(str, "%d", count);

    RandomColor(dev);
    RandomLgop(dev);

	dev->DrawString(x, y, str);
}

TPlanet *RandomPlanet(TGraphicDevice *dev)
{
	int r;
	int m;
	TPlanet *planet;

	m = 2500 * random(100) / 100 + 10;
	for (r = 3; r < dev->GetHeight() / 2; r++)
		if (r * r * r * 25 > m)
			break;

	planet = new TPlanet(dev, r);
	planet->m = m;

	switch (random(4))
	{
		case 0:
			planet->x = 0;
			planet->y = random(100) * dev->GetHeight();
			planet->vx = random(1000);
			planet->vy = random(1000);
			break;

		case 1:
			planet->x = 100 * dev->GetWidth();
			planet->y = random(100) * dev->GetHeight();
			planet->vx = -random(1000);
			planet->vy = random(1000);
			break;

		case 2:
			planet->x = random(100) * dev->GetWidth();
			planet->y = 0;
			planet->vx = random(1000);
			planet->vy = random(1000);
			break;

		case 3:
			planet->x = random(100) * dev->GetWidth();
			planet->y = dev->GetHeight() * 100;
			planet->vx = random(1000);
			planet->vy = -random(1000);
			break;
	}


	planet->ela = random(90);
	planet->vmax = 1500;

	return planet;
}

TPlanet *RecreatePlanet(TGraphicDevice *dev, TPlanet *templ)
{
	TPlanet *planet;

	planet = new TPlanet(dev, templ->r);
	planet->m = templ->m;
	planet->x = templ->x;
	planet->y = templ->y;
	planet->vx = templ->vx;
	planet->vy = templ->vy;
	planet->ela = templ->ela;
	planet->vmax = templ->vmax;

	return planet;
}

void UpdatePlanets(TGraphicDevice *dev)
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

			temp = dev->GetWidth() * 100;
			if (planet->x > temp)
			{
				planet->vx = -planet->vx * planet->ela / 100;

				planet->x = temp - (planet->x - temp) * planet->ela / 100;
			}

			temp = dev->GetHeight() * 100;
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
			{
				delete planet;
				planet = RandomPlanet(dev);
				PlanetArr[i] = planet;
			}

			if (planet->r > 30)
			{
				delete planet;
				planet = RandomPlanet(dev);
				PlanetArr[i] = planet;
			}
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

							PlanetArr[i] = RecreatePlanet(dev, planet);
							delete planet;
							planet = PlanetArr[i];

							delete comp;
							comp = RandomPlanet(dev);
							PlanetArr[j] = comp;
						}
					}
				}
			}
		}
	}

	for (i = 0; i < MAX_PLANETS; i++)
	{
		planet = PlanetArr[i];
		if (planet)
		{
			x = planet->x / 100;
			y = planet->y / 100;
			planet->Move(x, y);
			planet->Show();
		}
	}

}

void Pattern1(TGraphicDevice *dev)
{
	int i;

	dev->SetLgopAdd();
	dev->SetDrawColor(0, 0, 255);

	for (i = 0; i < 800; i++)
		dev->DrawLine(0, 3 * i, 3 * i, 0);
}

void Pattern2(TGraphicDevice *dev)
{
	int i;

	dev->SetLgopAdd();
	dev->SetDrawColor(0, 255, 0);

	for (i = -250; i < 250; i++)
		dev->DrawLine(dev->GetHeight(), dev->GetWidth() - 3 * i, 3 * i, 0);
}

void Pattern3(TGraphicDevice *dev)
{
	int i;

	dev->SetLgopAdd();
	dev->SetDrawColor(255, 0, 0);

	for (i = -250; i < 250; i++)
		dev->DrawLine(0, 3 * i, dev->GetHeight() - 3 * i, dev->GetWidth());
}

void TestAll(TGraphicDevice *dev)
{
	dev->SetLgopNone();
	dev->SetDrawColor(0, 0, 255);
	dev->SetFilledStyle();
	dev->DrawRect(50, 100, 250, 350);

	dev->SetDrawColor(0, 255, 0);
	dev->SetLgopAdd();
	dev->DrawRect(100, 150, 350, 350);

	dev->SetHollowStyle();
	dev->SetDrawColor(255, 0, 0);
	dev->DrawRect(50, 100, 250, 350);

	dev->DrawLine(350, 100, 50, 300);
	dev->DrawLine(350, 300, 50, 100);
	dev->DrawLine(350, 300, 350, 100);
	dev->DrawLine(50, 100, 50, 300);
	dev->DrawLine(350, 100, 50, 100);
	dev->DrawLine(350, 300, 50, 300);

	dev->SetFilledStyle();
	dev->DrawRect(200, 300, 350, 450);

	dev->SetDrawColor(100, 100, 0);
	dev->DrawEllipse(275, 425, 75, 125);

	dev->SetHollowStyle();
	dev->SetLgopNone();
	dev->SetDrawColor(0, 100, 100);
	dev->DrawEllipse(275, 425, 75, 125);

	dev->SetFilledStyle();
	dev->DrawEllipse(425, 175, 125, 125);
}

void cdecl main()
{
    int i;
	TGraphicDevice *vbe;
	TGraphicDevice *bitmap;
	TFont *font;

	RdosWaitMilli(250);


	vbe = new TVbeGraphicDevice(16, 800, 600);

//	vbe->SetClipRect(100, 100, vbe->GetWidth() - 100, vbe-GetHeight() - 100);

	Pattern1(vbe);
	RdosWaitMilli(5000);

	Pattern2(vbe);
	RdosWaitMilli(5000);

	Pattern3(vbe);
	RdosWaitMilli(5000);

	bitmap = new TBitmapGraphicDevice(vbe);
	TestAll(bitmap);

	vbe->SetLgopNone();
	vbe->Blit(bitmap, 0, 0, 0, 0, vbe->GetWidth(), vbe->GetHeight());

	delete bitmap;

	vbe->SetLgopAdd();
	vbe->Blit(vbe, 100, 50, 300, 450, vbe->GetWidth(), vbe->GetHeight());

	font = new TFont(50);
	vbe->SetFont(font);

	vbe->SetLgopNone();
	vbe->SetDrawColor(0, 255, 255);
	vbe->DrawString(40, 111, "RDOS operating system");

	delete font;

	font = new TFont(60);
	vbe->SetFont(font);

	for (i = 0; i < MAX_PLANETS; i++)
		PlanetArr[i] = RandomPlanet(vbe);

	for (i = 0; i < 5000; i++)
	{
		UpdatePlanets(vbe);
		RdosWaitMilli(10);
	}

	for (i = 0; i < MAX_PLANETS; i++)
		delete PlanetArr[i];

	for (;;)
	{
		count++;
		switch (random(4))
		{
			case 0:
				RandomLine(vbe);
				break;

			case 1:
				RandomRect(vbe);
				break;

			case 2:
				RandomEllipse(vbe);
				break;

			case 3:
				RandomText(vbe);
				break;
		}
	}
}

