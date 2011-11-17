#ifndef _WIN32_H
#define _WIN32_H

void WaitMilli(long MilliSec);

#ifdef __cplusplus
extern "C" {
#endif

void __stdcall Win32GetTics(unsigned long wintick, unsigned long *msb, unsigned long *lsb);
void __stdcall Win32TicsToRecord(unsigned long msb, unsigned long lsb, int *year, int *month, int *day, int *hour, int *min, int *sec, int *milli);
void __stdcall Win32RecordToTics(unsigned long *msb, unsigned long *lsb, int year, int month, int day, int hour, int min, int sec, int milli);
void __stdcall Win32AddTics(unsigned long *msb, unsigned long *lsb, long tics);
void __stdcall Win32AddMilli(unsigned long *msb, unsigned long *lsb, long ms);
void __stdcall Win32AddSec(unsigned long *msb, unsigned long *lsb, long sec);
void __stdcall Win32AddMin(unsigned long *msb, unsigned long *lsb, long min);
void __stdcall Win32AddHour(unsigned long *msb, unsigned long *lsb, long hour);
void __stdcall Win32AddDay(unsigned long *msb, unsigned long *lsb, long day);

void __stdcall Win32InitCrc(unsigned short int *buf, unsigned short int poly);
unsigned short int __stdcall Win32CalcCrc(unsigned short int *buf, unsigned short int crcin, const char *data, int size);


#ifdef __cplusplus
}
#endif

#endif

