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

#define BACK_R	100
#define BACK_G	100
#define BACK_B	100

#define TEXT_R	0
#define TEXT_G	0
#define TEXT_B	0

#define WIDTH 100
#define SPACE 15
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
 : TControl(dev, xmin, ymin, width, height)
{
    int i;

    for (i = 0; i < MAX_RAD_COUNT; i++)
    {
        FHasRef[i] = FALSE;
        FHasTemp[i] = FALSE;
        FHasMotor[i] = FALSE;
        FHasLight[i] = FALSE;
        FHasAuxTemp[i] = FALSE;
    }

    Enable();
    Show();
    Redraw();
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
		  FHasRef[rad] = FALSE;

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
		  FHasRef[rad] = TRUE;
		  FRef[rad] = val;
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
		  FHasTemp[rad] = FALSE;

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
		  FHasTemp[rad] = TRUE;
		  FTemp[rad] = val;
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
		  FHasMotor[rad] = FALSE;

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
		  FHasMotor[rad] = TRUE;
		  FMotor[rad] = val;
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
		  FHasLight[rad] = FALSE;

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
		  FHasLight[rad] = TRUE;
		  FLight[rad] = val;
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
		  FHasAuxTemp[rad] = FALSE;

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
		  FHasAuxTemp[rad] = TRUE;
		  FAuxTemp[rad] = val;
	 }

	 FSection.Leave();
}

/*##########################################################################
#
#   Name       : TRadControl::Update
#
#   Purpose....: Update control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRadControl::Update()
{
	 Redraw(1);
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

	    dev->DrawString(xmin + 300, ymin, "   Ref");
	    dev->DrawString(xmin + 400, ymin, "  Temp");
	    dev->DrawString(xmin + 500, ymin, "P†drag");
	    dev->DrawString(xmin + 600, ymin, "  Ljus");
	    dev->DrawString(xmin + 700, ymin, "Temp 2");

    	for (i = 0; i < 8; i++)
	    {
		    switch (i)
    		{
	    		case 0:
		    		strcpy(str, "Datarum");
			    	break;

    			case 1:
	    			strcpy(str, "Vardagsrum, nedre plan");
		    		break;

    			case 2:
	    			strcpy(str, "Rosa sovrum, nedre plan");
		    		break;

    			case 3:
	    			strcpy(str, "Bl†tt sovrum, nedre plan");
		    		break;

    			case 4:
	    			strcpy(str, "K”k");
		    		break;

    			case 5:
	    			strcpy(str, "Sovrum, ”vre plan");
		    		break;

    			case 6:
	    			strcpy(str, "Trappa");
		    		break;

    			case 7:
	    			strcpy(str, "Badrum");
		    		break;
    		}

            FSection.Enter();
            
            y = ymin + 32 * (i + 1);
	    	dev->DrawString(xmin, y, str);

            if (FHasRef[i])
    			sprintf(str, "%4ld.%ld ", FRef[i] / 10, FRef[i] % 10);
    		else
	    		strcpy(str, "------ ");

		    dev->SetFilledStyle();

		    dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
		    dev->DrawRect(xmin + 300, y, xmin + WIDTH - SPACE, y + HEIGHT - 1);

    		dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
    		dev->DrawString(xmin + 300, y, str);

            if (FHasTemp[i])
                sprintf(str, "%4ld.%ld ", FTemp[i] / 10, FTemp[i] % 10);
    		else
	    		strcpy(str, "------ ");

    		dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
    		dev->DrawRect(xmin + WIDTH, y, xmin + 2 * WIDTH - SPACE, y + HEIGHT - 1);

		    dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
		    dev->DrawString(xmin + WIDTH, y, str);

            if (FHasMotor[i])
    			sprintf(str, "%4ld.%ld ", FMotor[i] / 10, FMotor[i] % 10);
    		else
    			strcpy(str, "------ ");

		    dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
		    dev->DrawRect(xmin + 2 * WIDTH, y, xmin + 3 * WIDTH - SPACE, y + HEIGHT - 1);

    		dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
		    dev->DrawString(xmin + 2 * WIDTH, y, str);

		    if (FHasLight[i])
    			sprintf(str, "%4ld.%ld ", FLight[i] / 10, FLight[i] % 10);
    		else
	    		strcpy(str, "------ ");

		    dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
		    dev->DrawRect(xmin + 3 * WIDTH, y, xmin + 4 * WIDTH - SPACE, y + HEIGHT - 1);

    		dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
		    dev->DrawString(xmin + 3 * WIDTH, y, str);

		    if (FHasAuxTemp[i])
    			sprintf(str, "%4ld.%ld ", FAuxTemp[i] / 10, FAuxTemp[i] % 10);
    		else
	    		strcpy(str, "------ ");

    		dev->SetDrawColor(BACK_R, BACK_G, BACK_B);
		    dev->DrawRect(xmin + 4 * WIDTH, y, xmin + 5 * WIDTH - SPACE, y + HEIGHT - 1);

    		dev->SetDrawColor(TEXT_R, TEXT_G, TEXT_B);
		    dev->DrawString(xmin + 4 * WIDTH, y, str);

            FSection.Leave();
	    }

    }

    TControl::Paint(dev, xmin, ymin, width, height);
}
