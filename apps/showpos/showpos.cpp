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

	int i;
	TDateTime time(2008, 12, 29, 0, 0, 0);

	TSolar solar(55, 49, 5, 13, 14, 43);
//	TSolar solar(60, 0, 0, 15, 0, 0);

//	solar.SetTime(TDateTime(1990, 4, 19, 0, 0, 0), 0);

	for (i = 0; i < 20; i++)
	{
		solar.SetTime(time, 1);
		solar.GetSunPosition(&altitude, &azimuth);
		printf("Hour: %d, Sun Alt: %5.2Lf, Azi: %5.2Lf, ", i, altitude, azimuth);

		solar.GetMoonPosition(&altitude, &azimuth);
		printf("Moon Alt: %5.2Lf, Azi: %5.2Lf\r\n", altitude, azimuth);

		time.AddHour(1);
	}

	solar.SetTime(TDateTime(), 1);

	solar.GetSunPosition(&altitude, &azimuth);
	printf("Sun Alt: %5.2Lf, Azi: %5.2Lf\r\n", altitude, azimuth);

	solar.GetMoonPosition(&altitude, &azimuth);
	printf("Moon Alt: %5.2Lf, Azi: %5.2Lf\r\n", altitude, azimuth);

	return 0;
}

