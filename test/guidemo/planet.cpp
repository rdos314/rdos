/*####################################  PLANET.CPP                      #################################################
##    Description: Planet class                                                ##
##                                                                                                                  ##
##    Created....: 02-11-04 le                                                        Printed...: 90-10-25 an      ##
####################################################################################################################*/

#include "rdos.h"
#include "planet.h"
#include "bitdev.h"

/*##################  TPlanet::TPlanet ##########################
*   Purpose....: Constructor				                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 02-11-06 le                                                #
*##########################################################################*/
TPlanet::TPlanet(TGraphicDevice *dest, int radius)
{
	int w;
	int i;
	int R, G, B;
	int CR, CG, CB;

	r = radius;
	w = 2 * r + 2;
	FBitmap = new TBitmapGraphicDevice(dest->GetBpp(), w, w);

	FBitmap->SetLgopNone();
	FBitmap->SetFilledStyle();

	if (dest->GetBpp() == 1)
	{
		FBitmap->SetDrawColor(0, 0, 0);
		FBitmap->DrawEllipse(r, r, r, r);
		FBitmap->SetDrawColor(255, 255, 255);
		FBitmap->DrawEllipse(r, r, r - 1, r - 1);
	}
	else
	{
		R = 1024 / w;
		G = 128;
		B = 4 * w;

		for (i = r; i > 2; i--)
		{
			if (R * (r - i) / 10 > 127)
				CR = 255;
			else
				CR = 128 + R * i / 10;

			if (G * (r - i) / 10 > 127)
				CG = 255;
			else
				CG = 128 + G * i / 10;

			if (B * (r - i) / 10 > 127)
				CB = 255;
			else
				CB = 128 + B * i / 10;

			FBitmap->SetDrawColor(CR, CG, CB);
			FBitmap->DrawEllipse(r, r, i, i);
		}
	}

	FMask = new TBitmapGraphicDevice(1, w, w);

	FMask->SetLgopNone();
	FMask->SetFilledStyle();
	FMask->DrawEllipse(r, r, r, r);

	Define(dest, FBitmap, FMask, r, r);
}

/*##################  TPlanet::~TPlanet ##########################
*   Purpose....: Destructor				                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 02-11-06 le                                                #
*##########################################################################*/
TPlanet::~TPlanet()
{
	Hide();

    if (FBitmap)
        delete FBitmap;

    if (FMask)
        delete FMask;
}
