
#ifndef _PLANET_H
#define _PLANET_H

#include "sprite.h"

class TPlanet : public TSprite
{

public:
    TPlanet(TGraphicDevice *dest, int r);
	~TPlanet();

	void UpdatePos();

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

protected:
    TGraphicDevice *FBitmap;
    TGraphicDevice *FMask;

};

#endif

