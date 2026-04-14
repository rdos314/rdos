#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <math.h>

#include "rdos.h"
#include "datetime.h"


void main()
{
    int year, month, day;
    int hour, min, sec;
    int ms, us;
    int dow;
    TDateTime time(17654492, 786814295);
    
    year = time.GetYear();
    month = time.GetMonth();
    day = time.GetDay();
    hour = time.GetHour();
    min = time.GetMin();
    sec = time.GetSec();
    ms = time.GetMilliSec();
    us = time.GetMicroSec();
    
    printf("%d.%d.%d %d.%d.%d,%03d %03d\r\n", year, month, day, hour, min, sec, ms, us);

    dow = time.GetDayOfWeek();
    printf("dow: %d\r\n", dow);
    
    time.NextDay();
    dow = time.GetDayOfWeek();
    printf("dow: %d\r\n", dow);
    
    RdosTestGate("");
}



