#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "serial.h"
#include "section.h"
#include "file.h"
#include "rdos.h"
#include "modbus.h"
#include "openweather.h"

#include <math.h>
#include "bignum.h"

#include "section.h"

#include "testlib.h"


#define FALSE 0
#define TRUE !FALSE


void main()
{
    TOpenWeather ws("2715946", "c88ba239c78cdbea4c1fe561ad4f7b3d");

    for (;;)
    {
        ws.WaitForData();

        printf("Temp %3.1Lf C\r\n", ws.GetTemperature());
        printf("Pressure %d hPa\r\n", (int)ws.GetPressure());
        printf("Humidity %d%%\r\n", (int)ws.GetHumidity());
        printf("Wind %3.1Lf m/s, deg:%d\r\n", ws.GetWindSpeed(), ws.GetWindDir());
        printf("Clouds %d%%\r\n", ws.GetCloud());
        printf("Visibility %d\r\n", ws.GetVisibility());
    }
}
