#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "modbus.h"
#include "disc.h"
#include "md5.h"
#include "ini.h"

#define FALSE 0
#define TRUE !FALSE


long DiffTime = 0;
const int DaysInMonth[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
const char AppSection[] = "r1";

/*##################  PassedDays  ###############
*   Purpose....: Return passed days since 1/1 1970                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long PassedDays(int year, int month, int day)
{
    int i;
    long days = 0;

    if (year >= 1970)
    {
        for (i = 1970; i < year; i++)
            if (i % 4)
                days += 365;
            else
                days += 366;
    }
    else
    {
        for (i = 0; i < year; i++)
            if (i % 4)
                days += 365;
            else
                days += 366;
    }

    for (i = 1; i < month; i++)
        if (i == 2)
        {
            if (year % 4)
                days += 28;
            else
                days += 29;     
        }
        else
            days += DaysInMonth[i - 1];

    days += day - 1;

    return days;
}

/*##################  TimeToBinary  ###############
*   Purpose....: Convert time to binary form                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TimeToBinary(int year, int month, int day, int hour, int min, int sec)
{
    long result;

    result = PassedDays(year, month, day);
    result = result * 24 + hour;
    result = result * 60 + min;
    result = result * 60 + sec;

    return result;
}

/*##################  GetSystemTime  ###############
*   Purpose....: Get system time                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long GetSystemTime()
{
    int year, month, day, hour, min, sec, milli, micro;
    unsigned long msb, lsb;

    RdosGetSysTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &min, &sec, &milli, &micro);
    return TimeToBinary(year, month, day, hour, min, sec);
}

/*##########################################################################
#
#   Name       : ReadRuntimeSetting
#
#   Purpose....: Read runtime setting
#
##########################################################################*/
bool ReadRuntimeSetting(const char *Name, char *Value, int MaxSize)
{
    bool ok;
    TIniFile ini("c:\\run.ini");

    ini.GotoSection(AppSection);
    ok = ini.ReadVar(Name, Value, MaxSize);

    return ok;
}

/*##########################################################################
#
#   Name       : WriteRuntimeSetting
#
#   Purpose....: Write runtime setting
#
##########################################################################*/
void WriteRuntimeSetting(const char *Name, const char *Value)
{
    TIniFile ini("c:\\run.ini");

    ini.GotoSection(AppSection);
    ini.WriteVar(Name, Value);
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void main()
{
    int total = 0;

    for (;;) 
    {
        char previousValueString[20];
        char newValue[20];
        char label[100];
        label[0] = '0';
        label[1] = 0;

        sprintf(label, "total_volume_p%d_n%d", 99, 1);

        // Read the old total from permanent storage
        ReadRuntimeSetting(label, previousValueString, 11);
        long previousVolume = atol(previousValueString);

        // Write the new value to permanent storage
        sprintf(newValue, "%d", total);
        WriteRuntimeSetting(label, newValue);

        sprintf(label, "total_volume_time_p%d_n%d", 99, 1);

        // Read the old total time from permanent storage
        ReadRuntimeSetting(label, previousValueString, 11);
        long previousVolumeTime = atol(previousValueString);

        // Write the new value to permanent storage
        sprintf(newValue, "%d", GetSystemTime());
        WriteRuntimeSetting(label, newValue);

        total++;
        RdosWaitMilli(50);
    }

    RdosTestGate("");
}
