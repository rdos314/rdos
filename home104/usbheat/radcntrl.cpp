/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# radcntrl.cpp
# Radiator control class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "radcntrl.h"

#define BACK_R  100
#define BACK_G  100
#define BACK_B  100

#define TEXT_R  0
#define TEXT_G  0
#define TEXT_B  0

#define WIDTH 85
#define SPACE 12
#define HEIGHT 25

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRadControl::TRadControl
#
#   Purpose....: Radiator control constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRadControl::TRadControl(TControlThread *dev, int xmin, int ymin, int width, int height)
 : TControl(dev, xmin, ymin, width, height),
   FSection("Rad.Ctrl.Section")

{
    int i;

    FDrawHeader = TRUE;

    for (i = 0; i < MAX_RAD_COUNT; i++)
    {
        FChangedName[i] = FALSE;
        FName[i] = 0;
        FChangedRef[i] = FALSE;
        FHasRef[i] = FALSE;
        FChangedTemp[i] = FALSE;
        FHasTemp[i] = FALSE;
        FChangedMotor[i] = FALSE;
        FHasMotor[i] = FALSE;
        FChangedLight[i] = FALSE;
        FHasLight[i] = FALSE;
        FChangedAuxTemp[i] = FALSE;
        FHasAuxTemp[i] = FALSE;
    }

    Enable();
    Show();
    Redraw(500);
}

/*##########################################################################
#
#   Name       : TRadControl::~TRadControl
#
#   Purpose....: Radiator control destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRadControl::~TRadControl()
{
    int i;

    for (i = 0; i < MAX_RAD_COUNT; i++)
        if (FName[i])
            delete FName[i];
}

/*##########################################################################
#
#   Name       : TRadControl::Define
#
#   Purpose....: Define ref & name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::Define(int rad, const char *name)
{
        int size;

        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FName[rad])
                delete FName[rad];

            size = strlen(name);
            FName[rad] = new char[size + 1];
            strcpy(FName[rad], name);

                 FChangedName[rad] = TRUE;
        }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetRef
#
#   Purpose....: Set ref to invalid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetRef(int rad)
{
        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasRef[rad])
            {
            FHasRef[rad] = FALSE;
            FChangedRef[rad] = TRUE;
        }
    }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetRef
#
#   Purpose....: Set ref
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetRef(int rad, int val)
{
        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasRef[rad])
            {
                if (FRef[rad] != val)
                {
                    FRef[rad] = val;
                    FChangedRef[rad] = TRUE;
                }
            }
            else
            {
                FHasRef[rad] = TRUE;
                FRef[rad] = val;
                FChangedRef[rad] = TRUE;
            }
        }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetTemp
#
#   Purpose....: Set temp to invalid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetTemp(int rad)
{
        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasTemp[rad])
            {
                FHasTemp[rad] = FALSE;
            FChangedTemp[rad] = TRUE;
        }
    }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetTemp
#
#   Purpose....: Set temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetTemp(int rad, int val)
{
        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasTemp[rad])
            {
                if (FTemp[rad] != val)
                {
                    FTemp[rad] = val;
                    FChangedTemp[rad] = TRUE;
                }
            }
            else
            {
                FHasTemp[rad] = TRUE;
                FTemp[rad] = val;
                FChangedTemp[rad] = TRUE;
            }
        }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetMotor
#
#   Purpose....: Set motor to invalid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetMotor(int rad)
{
        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasMotor[rad])
            {
            FHasMotor[rad] = FALSE;
            FChangedMotor[rad] = TRUE;
        }
    }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetMotor
#
#   Purpose....: Set motor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetMotor(int rad, int val)
{
        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasMotor[rad])
            {
                if (FMotor[rad] != val)
                {
                    FMotor[rad] = val;
                    FChangedMotor[rad] = TRUE;
                }
            }
            else
            {
                FHasMotor[rad] = TRUE;
                FMotor[rad] = val;
                FChangedMotor[rad] = TRUE;
            }
        }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetLight
#
#   Purpose....: Set light to invalid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetLight(int rad)
{
        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasLight[rad])
            {
                FHasLight[rad] = FALSE;
                FChangedLight[rad] = TRUE;
            }
    }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetLight
#
#   Purpose....: Set light
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetLight(int rad, int val)
{
        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasLight[rad])
            {
                if (FLight[rad] != val)
                {
                    FLight[rad] = val;
                    FChangedLight[rad] = TRUE;
                }
            }
            else
            {
                FHasLight[rad] = TRUE;
                FLight[rad] = val;
                          FChangedLight[rad] = TRUE;
            }
        }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetAuxTemp
#
#   Purpose....: Set aux temp to invalid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetAuxTemp(int rad)
{
    FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasAuxTemp[rad])
            {
            FHasAuxTemp[rad] = FALSE;
                FChangedAuxTemp[rad] = TRUE;
            }
    }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::SetAuxTemp
#
#   Purpose....: Set aux temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::SetAuxTemp(int rad, int val)
{
        FSection.Enter();

        if (rad < MAX_RAD_COUNT)
        {
            if (FHasAuxTemp[rad])
            {
                if (FAuxTemp[rad] != val)
                {
                    FAuxTemp[rad] = val;
                    FChangedAuxTemp[rad] = TRUE;
                }
                 }
            else
                 {
                FHasAuxTemp[rad] = TRUE;
                FAuxTemp[rad] = val;
                FChangedAuxTemp[rad] = TRUE;
            }
        }

        FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
        int i;
        int xmax = xmin + width - 1;
        int ymax = ymin + height - 1;
        int x;
    int y;
    char str[80];
    TFont Font(25);

    if (IsVisible())
    {
        dev->SetLgopNone();
        dev->SetFilledStyle();

        dev->SetClipRect(  xmin, ymin,
                           xmax, ymax);

        dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
        dev->SetFont(&Font);

        if (FDrawHeader)
        {
            dev->DrawString(xmin + 315, ymin, "   Ref");
            dev->DrawString(xmin + 400, ymin, "  Temp");
            dev->DrawString(xmin + 485, ymin, "Pådrag");
            dev->DrawString(xmin + 565, ymin, "  Ljus");
            dev->DrawString(xmin + 650, ymin, "Temp 2");

            FDrawHeader = FALSE;
        }

        for (i = 0; i < MAX_RAD_COUNT; i++)
        {
            if (FName[i])
            {
                FSection.Enter();

                x = xmin + 315;
                y = ymin + (HEIGHT + 5) * (i + 1);

                if (FChangedName[i])
                {
                    dev->DrawString(xmin, y, FName[i]);
                    FChangedName[i] = FALSE;
                }

                if (FChangedRef[i])
                {
                    if (FHasRef[i])
                                sprintf(str, "%4ld.%ld ", FRef[i] / 10, FRef[i] % 10);
                        else
                                strcpy(str, "------ ");

                            dev->SetFilledStyle();

                            dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
                            dev->DrawRect(x, y, x + WIDTH - SPACE, y + HEIGHT - 1);

                        dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
                        dev->DrawString(x, y, str);

                        FChangedRef[i] = FALSE;
                    }

                    if (FChangedTemp[i])
                    {
                    if (FHasTemp[i])
                        sprintf(str, "%4ld.%ld ", FTemp[i] / 10, FTemp[i] % 10);
                        else
                                strcpy(str, "------ ");

                            dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
                        dev->DrawRect(x + WIDTH, y, x + 2 * WIDTH - SPACE, y + HEIGHT - 1);

                            dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
                            dev->DrawString(x + WIDTH, y, str);

                            FChangedTemp[i] = FALSE;
                        }

                        if (FChangedMotor[i])
                        {
                    if (FHasMotor[i])
                                sprintf(str, "%4ld.%ld ", FMotor[i] / 10, FMotor[i] % 10);
                        else
                                strcpy(str, "------ ");

                    dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
                        dev->DrawRect(x + 2 * WIDTH, y, x + 3 * WIDTH - SPACE, y + HEIGHT - 1);

                        dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
                        dev->DrawString(x + 2 * WIDTH, y, str);

                        FChangedMotor[i] = FALSE;
                    }

                    if (FChangedLight[i])
                    {
                            if (FHasLight[i])
                                sprintf(str, "%4ld.%ld ", FLight[i] / 10, FLight[i] % 10);
                        else
                                strcpy(str, "------ ");

                            dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
                            dev->DrawRect(x + 3 * WIDTH, y, x + 4 * WIDTH - SPACE, y + HEIGHT - 1);

                        dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
                            dev->DrawString(x + 3 * WIDTH, y, str);

                            FChangedLight[i] = FALSE;
                        }

                if (FChangedAuxTemp[i])
                {
                            if (FHasAuxTemp[i])
                                sprintf(str, "%4ld.%ld ", FAuxTemp[i] / 10, FAuxTemp[i] % 10);
                        else
                                strcpy(str, "------ ");

                        dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
                            dev->DrawRect(x + 4 * WIDTH, y, x + 5 * WIDTH - SPACE, y + HEIGHT - 1);

                        dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
                            dev->DrawString(x + 4 * WIDTH, y, str);

                            FChangedAuxTemp[i] = FALSE;
                        }

                FSection.Leave();
            }
            }

    }

    TControl::Paint(dev, xmin, ymin, width, height);
    Redraw(500);
}
