
#ifndef _PLANTHR_H
#define _PLANTHR_H

#include "planet.h"
#include "device.h"
#include "graphdev.h"

#define MAX_PLANETS 1024

class TPlanetThread : public TDevice
{
public:
	TPlanetThread(TGraphicDevice *dev, int PlanetCount);
	virtual ~TPlanetThread();
	virtual void DeviceName(char *Name, int MaxLen) const;

protected:
	TPlanet *RandomPlanet();
	TPlanet *RecreatePlanet(TPlanet *templ);
	void UpdatePlanets();
	virtual void Execute();

	TGraphicDevice FDev;
	int FMaxPlanets;
	TPlanet *PlanetArr[MAX_PLANETS];
};

#endif
