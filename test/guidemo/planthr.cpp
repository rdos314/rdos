/*####################################  PLANTHR.CPP                      #################################################
##    Description: Planet thread class                                                ##
##                                                                                                                  ##
##    Created....: 02-11-04 le                                                        Printed...: 90-10-25 an      ##
####################################################################################################################*/

#include "planthr.h"
#include "graphdev.h"
#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define STACK_SIZE  0x4000

#define FALSE   0
#define TRUE    !FALSE

/*##################  TPlanetThread::TPlanetThread ##########################
*   Purpose....: Constructor                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 02-11-06 le                                                #
*##########################################################################*/
TPlanetThread::TPlanetThread(TGraphicDevice *dest, int MaxPlanets)
  : FDev(*dest)
{
        int i;

        if (MaxPlanets > MAX_PLANETS)
                MaxPlanets = MAX_PLANETS;
        FMaxPlanets = MaxPlanets;

        for (i = 0; i < MAX_PLANETS; i++)
                PlanetArr[i] = 0;

        Start("PLANET", STACK_SIZE);
}

/*##################  TPlanetThread::~TPlanetThread ##########################
*   Purpose....: Destructor                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 02-11-06 le                                                #
*##########################################################################*/
TPlanetThread::~TPlanetThread()
{
        int i;

        for (i = 0; i < MAX_PLANETS; i++)
                if (PlanetArr[i])
                        delete PlanetArr[i];

}

/*##################  TPlanetThread::DeviceName ##########################
*   Purpose....: Get device name                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 02-11-06 le                                                #
*##########################################################################*/
void TPlanetThread::DeviceName(char *Name, int MaxLen) const
{
        strncpy(Name, "Planet", MaxLen);
}

/*##################  TPlanetThread::RandomPlanet ##########################
*   Purpose....: Create a random planet                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 02-11-06 le                                                #
*##########################################################################*/
TPlanet *TPlanetThread::RandomPlanet()
{
        int r;
        int m;
        TPlanet *planet;

        m = 2500 * RdosGetRandom(100) / 100 + 10;
        for (r = 3; r < FDev.GetHeight() / 2; r++)
                if (r * r * r * 25 > m)
                        break;

        planet = new TPlanet(&FDev, r);
        planet->m = m;

        switch (RdosGetRandom(4))
        {
                case 0:
                        planet->x = 0;
                        planet->y = RdosGetRandom(100) * FDev.GetHeight();
                        planet->vx = RdosGetRandom(1000);
                        planet->vy = RdosGetRandom(1000);
                        break;

                case 1:
                        planet->x = 100 * FDev.GetWidth();
                        planet->y = RdosGetRandom(100) * FDev.GetHeight();
                        planet->vx = -RdosGetRandom(1000);
                        planet->vy = RdosGetRandom(1000);
                        break;

                case 2:
                        planet->x = RdosGetRandom(100) * FDev.GetWidth();
                        planet->y = 0;
                        planet->vx = RdosGetRandom(1000);
                        planet->vy = RdosGetRandom(1000);
                        break;

                case 3:
                        planet->x = RdosGetRandom(100) * FDev.GetWidth();
                        planet->y = FDev.GetHeight() * 100;
                        planet->vx = RdosGetRandom(1000);
                        planet->vy = -RdosGetRandom(1000);
                        break;
        }


        planet->ela = RdosGetRandom(95);
        planet->vmax = 1500;

        return planet;
}

/*##################  TPlanetThread::RecreatePlanet ##########################
*   Purpose....: Recreate planet after merge                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 02-11-06 le                                                #
*##########################################################################*/
TPlanet *TPlanetThread::RecreatePlanet(TPlanet *templ)
{
        TPlanet *planet;
        int r;
        int m;

        m = templ->m;
        for (r = 3; r < FDev.GetHeight() / 2; r++)
                if (r * r * r * 25 > m)
                        break;

        planet = new TPlanet(&FDev, r);
        planet->m = m;
        planet->x = templ->x;
        planet->y = templ->y;
        planet->vx = templ->vx;
        planet->vy = templ->vy;
        planet->ela = templ->ela;
        planet->vmax = templ->vmax;

        return planet;
}

/*##################  TPlanetThread::UpdatePlanets ##########################
*   Purpose....: Update positions of planets                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 02-11-06 le                                                #
*##########################################################################*/
void TPlanetThread::UpdatePlanets()
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

        for (i = 0; i < FMaxPlanets; i++)
        {
                planet = PlanetArr[i];

                if (planet)
                {

                        fx = 0;
                        fy = 0;

                        for (j = 0; j < FMaxPlanets; j++)
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

        for (i = 0; i < FMaxPlanets; i++)
        {
                planet = PlanetArr[i];
                if (planet)
                {
                        planet->vx += planet->gx;
                        planet->vy += planet->gy;
                }
        }

        for (i = 0; i < FMaxPlanets; i++)
        {
                planet = PlanetArr[i];
                if (planet)
                {
                        planet->x += planet->vx / 10;
                        planet->y += planet->vy / 10;

                        if (planet->x < 0)
                        {
                                planet->vx = -planet->vx * planet->ela / 100;
                                planet->x = -planet->x * planet->ela / 100;
                        }

                        if (planet->y  < 0)
                        {
                                planet->vy = -planet->vy * planet->ela / 100;
                                planet->y = - planet->y * planet->ela / 100;
                        }

                        if (planet->x / 100 > FDev.GetWidth())
                        {
                                planet->vx = -planet->vx * planet->ela / 100;

                                planet->x = 100 * FDev.GetWidth() - (planet->x - 100 * FDev.GetWidth()) * planet->ela / 100;
                        }

                        if (planet->y / 100 > FDev.GetHeight())
                        {
                                planet->vy = -planet->vy * planet->ela / 100;
                                planet->y = 100 * FDev.GetHeight() - (planet->y - 100 * FDev.GetHeight()) * planet->ela / 100;
                        }
                }
        }

        for (i = 0; i < FMaxPlanets; i++)
        {
                planet = PlanetArr[i];

                if (planet)
                {

                        if (planet->vx * planet->vx + planet->vy * planet->vy +
                                                planet->gx * planet->gx + planet->gy * planet->gy  == 0)
                        {
                                delete planet;
                                planet = RandomPlanet();
                                PlanetArr[i] = planet;
                        }

                        if (planet->r > 30)
                        {
                                delete planet;
                                planet = RandomPlanet();
                                PlanetArr[i] = planet;
                        }
                }
        }

        changed = TRUE;

        while (changed)
        {
                changed = FALSE;

                for (i = 0; i < FMaxPlanets; i++)
                {
                        planet = PlanetArr[i];

                        if (planet)
                        {
                                for (j = i + 1; j < FMaxPlanets; j++)
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
                                                        planet->ela = 100 - (100 - planet->ela) * (100 - comp->ela) / 100;

                                                        PlanetArr[i] = RecreatePlanet(planet);
                                                        delete planet;
                                                        planet = PlanetArr[i];

                                                        delete comp;
                                                        comp = RandomPlanet();
                                                        PlanetArr[j] = comp;
                                                }
                                        }
                                }
                        }
                }
        }

        for (i = 0; i < FMaxPlanets; i++)
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

/*##################  TPlanetThread::Execute ##########################
*   Purpose....: Recreate planet after merge                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 02-11-06 le                                                #
*##########################################################################*/
void TPlanetThread::Execute()
{
    int i;
    
        for (i = 0; i < FMaxPlanets; i++)
                PlanetArr[i] = RandomPlanet();

    PlanetArr[0]->Move(543, 477);
    PlanetArr[0]->Show();

    while (FInstalled)
    {
                UpdatePlanets();
                RdosWaitMilli(10);
    }
}
