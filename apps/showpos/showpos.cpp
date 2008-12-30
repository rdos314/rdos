#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "solar.h"

#define FALSE	0
#define	TRUE	!FALSE

int main(int argc, char **argv)
{
	long double altitude;
	long double azimuth;
	long double phase;
	int ph;

	int i;
	TDateTime time(2008, 12, 29, 0, 0, 0);

	TSolar solar(55, 49, 5, 13, 14, 43);
//	TSolar solar(60, 0, 0, 15, 0, 0);

//	solar.SetTime(TDateTime(1990, 4, 19, 0, 0, 0), 0);
	solar.SetTime(TDateTime(), 1);

	solar.GetSunPosition(&altitude, &azimuth);
	printf("Sun Alt: %5.2Lf, Azi: %5.2Lf\r\n", altitude, azimuth);

	solar.GetMoonPosition(&altitude, &azimuth);
	phase = 100.0 * solar.GetMoonPhase();
	ph = (int)phase;
	printf("Moon Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

	solar.GetMercuryPosition(&altitude, &azimuth);
	phase = 100.0 * solar.GetMercuryPhase();
	ph = (int)phase;
	printf("Mercury Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

	solar.GetVenusPosition(&altitude, &azimuth);
	phase = 100.0 * solar.GetVenusPhase();
	ph = (int)phase;
	printf("Venus Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

	solar.GetMarsPosition(&altitude, &azimuth);
	phase = 100.0 * solar.GetMarsPhase();
	ph = (int)phase;
	printf("Mars Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

	solar.GetJupiterPosition(&altitude, &azimuth);
	phase = 100.0 * solar.GetJupiterPhase();
	ph = (int)phase;
	printf("Jupiter Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

	solar.GetSaturnPosition(&altitude, &azimuth);
	phase = 100.0 * solar.GetSaturnPhase();
	ph = (int)phase;
	printf("Saturn Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

	solar.GetUranusPosition(&altitude, &azimuth);
	phase = 100.0 * solar.GetUranusPhase();
	ph = (int)phase;
	printf("Uranus Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

	solar.GetNeptunePosition(&altitude, &azimuth);
	phase = 100.0 * solar.GetNeptunePhase();
	ph = (int)phase;
	printf("Neptune Alt: %5.2Lf, Azi: %5.2Lf, Ph: %d%\r\n", altitude, azimuth, ph);

	return 0;
}

