/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# datetime.cpp
# Date & time class
#
########################################################################*/

#include <math.h>
#include <string.h>
#include <unistd.h>
#include "datetime.h"

#ifdef __RDOS__
#include "rdos.h"
#else
#include <time.h>
#include "section.h"

/**
 * @brief Indicates whether the time zone information has been initialized.
 *
 * The `has_time_zone` variable is a static boolean flag used to determine
 * whether the system's time zone information has been initialized and adjusted.
 * It is initially set to `false` and updated to `true` when the time zone
 * is first calculated or modified.
 *
 * This variable is used internally within time management functions to ensure
 * that time zone adjustments and related computations are performed only once,
 * preventing redundant calculations.
 *
 * Note: Modifications to this variable are intended to occur within controlled
 * time-handling routines to maintain consistency and thread safety.
 */
static bool has_time_zone = false;
/**
 * @brief A static instance of TSection to manage thread-safe access to time-related operations.
 *
 * The `time_section` variable is an instance of the `TSection` class, initialized with the name "sys.time".
 * It is used to provide synchronization and ensure thread-safe access to the system time operations
 * encapsulated within critical sections.
 *
 * This variable is designed to enforce mutual exclusion by using platform-specific synchronization mechanisms.
 * For example:
 * - On POSIX-compliant systems, it employs a pthread mutex.
 *
 * The `time_section` object uses its `Enter` and `Leave` methods to respectively acquire and release
 * the lock, ensuring that only one thread can execute within the critical section at a time. Proper use
 * of these methods helps avoid race conditions when accessing or modifying shared time resources.
 *
 * The name "sys.time" provides a descriptive identifier for the synchronization section, aiding in debugging
 * and readability of the code.
 *
 * Note: Every call to `Enter` must be matched with a corresponding call to `Leave` to properly manage
 * resource locking and prevent deadlocks.
 */
static TSection time_section("sys.time");
/**
 * @brief Stores the time difference in seconds between local time and UTC.
 *
 * The time_diff variable is used to adjust system clock values to account for
 * the timezone offset between local time and Coordinated Universal Time (UTC).
 * The value is calculated as the difference between the local time and UTC time
 * when the timezone information is initialized.
 *
 * This variable is updated during the execution of functions that interact
 * with the system clock and depends on the system's timezone configuration.
 *
 * Note: Proper initialization of the timezone information is required for the
 * value of time_diff to be meaningful.
 */
static int time_diff = 0;

#endif

/**
 * @brief Variable representing the difference in time, measured in seconds.
 *
 * DiffTime is a long integer used to store the computed or assigned difference
 * between two time points. The value is typically expressed in seconds and can
 * be either positive or negative, depending on the calculation context.
 *
 * This variable is utilized in operations where time intervals or differences
 * are an essential factor, such as time synchronization, scheduling, or
 * elapsed time computation.
 *
 * Note: The value of DiffTime is initialized to zero by default, representing
 * no difference in time.
 */
long DiffTime = 0;
/**
 * @brief Array representing the number of days in each month of a non-leap year.
 *
 * DaysInMonth is a constant array containing the number of days in each month
 * of the Gregorian calendar for a standard non-leap year. The array follows
 * a zero-based index where the first element (index 0) represents January and
 * the last element (index 11) represents December.
 *
 * The values are as follows:
 * - January: 31 days
 * - February: 28 days
 * - March: 31 days
 * - April: 30 days
 * - May: 31 days
 * - June: 30 days
 * - July: 31 days
 * - August: 31 days
 * - September: 30 days
 * - October: 31 days
 * - November: 30 days
 * - December: 31 days
 *
 * Note: Leap year calculations are not included in this array. For leap years,
 * the number of days in February should be adjusted to 29 days.
 */
const int DaysInMonth[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

#ifndef __RDOS__
/**
 * @brief Retrieves the current local time with time zone adjustments accounted for.
 *
 * This function calculates the current local time by first determining
 * the system's time zone difference if it hasn't been calculated yet.
 * Subsequent calls reuse the adjusted time zone difference for efficiency.
 * The resulting local time is updated in the provided `struct timespec`.
 *
 * @param ts A pointer to a `struct timespec` that will be populated with
 *           the adjusted local time. The `tv_sec` field will include the
 *           calculated time zone difference.
 *
 * @note The function ensures thread safety by utilizing a time section
 *       lock during the computation and update process.
 */
void GetLocalTime(struct timespec *ts)
{
    time_t t, lt, gt;
    struct tm tm;

    time_section.Enter();

    if (!has_time_zone)
    {
        has_time_zone = true;
        t = time(NULL);
        lt = mktime(localtime(&t));
        gt = mktime(gmtime(&t));
        time_diff = difftime(lt, gt);
    }
    clock_gettime(CLOCK_REALTIME, ts);
    ts->tv_sec += time_diff;

    time_section.Leave();
}
#endif

#ifndef __RDOS__
/**
 * @brief Adjusts the system's local time by calculating the difference from a provided reference time.
 *
 * This function calculates the time difference between the provided reference time
 * and the current system time. It ensures that this calculation is performed accurately
 * by repeatedly verifying the system's real-time clock until a consistent value is achieved.
 * To manage concurrency, the function utilizes a synchronization mechanism to safely update shared resources.
 *
 * @param time The reference time in seconds since the epoch used to calculate and adjust the local time difference.
 */
void SetLocalTime(long time)
{
    struct timespec now;
    int sec;

    time_section.Enter();

    clock_gettime(CLOCK_REALTIME, &now);
    sec = now.tv_sec - 1;

    has_time_zone = true;
    while (sec != now.tv_sec)
    {
        sec = now.tv_sec;
        clock_gettime(CLOCK_REALTIME, &now);
        time_diff =  time - now.tv_sec;
    }

    time_section.Leave();
}

#endif

/**
 * Calculates the total number of days passed since January 1, 1970, given a specific date.
 *
 * @param year The year of the date.
 * @param month The month of the date (1-based, e.g., 1 for January, 12 for December).
 * @param day The day of the date.
 * @return The total number of days that have passed since January 1, 1970, up to the specified date.
 */
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

    for (i = 1; i < month; i++) {
        if (i == 2)
        {
            if (year % 4)
                days += 28;
            else
                days += 29;
        }
        else
            days += DaysInMonth[i - 1];
    }
    days += day - 1;

    return days;
}

/**
 * Converts a given date and time into a binary representation of seconds
 * elapsed since an epoch-like starting point (typically 1970-01-01 00:00:00).
 *
 * @param year The year component of the date.
 * @param month The month component of the date (1-12).
 * @param day The day component of the date (1-31).
 * @param hour The hour component of the time (0-23).
 * @param min The minute component of the time (0-59).
 * @param sec The second component of the time (0-59).
 * @return The total number of seconds calculated from the given date and time.
 */
long TimeToBinary(int year, int month, int day, int hour, int min, int sec)
{
    long result;

    result = PassedDays(year, month, day);
    result = result * 24 + hour;
    result = result * 60 + min;
    result = result * 60 + sec;

    return result;
}

/**
 * Converts a binary time value into its corresponding components: year, month, day, hour, minute, and second.
 *
 * @param time The binary time value in seconds since 1 January 1970, 00:00:00 UTC.
 * @param year Pointer to an integer where the calculated year will be stored.
 * @param month Pointer to an integer where the calculated month (1-12) will be stored.
 * @param day Pointer to an integer where the calculated day (1-31) will be stored.
 * @param hour Pointer to an integer where the calculated hour (0-23) will be stored.
 * @param min Pointer to an integer where the calculated minute (0-59) will be stored.
 * @param sec Pointer to an integer where the calculated second (0-59) will be stored.
 */
void BinaryToTime(long time, int *year, int *month, int *day, int *hour, int *min, int *sec)
{
    *sec = (int)(time % 60L);
    time = time / 60L;
    *min = (int)(time % 60L);
    time = time / 60L;
    *hour = (int)(time % 24L);
    time = time / 24L;
    *year = (int)(1970L + time / 365L);     // based on 1/1 1970 05.00
    time -= PassedDays(*year, 1, 1);
    while (time < 0)
    {
        (*year)--;
        if ((*year) % 4)
            time += 365L;
        else
            time += 366L;
    }

    *month = 1;
    while (time >= 0)
    {
        if (*month == 2)
        {
            if ((*year) % 4)
                time -= 28L;
            else
                time -= 29L;
        }
        else
            time -= DaysInMonth[(*month) - 1];
        (*month)++;
    }

    (*month)--;
    if (*month == 2)
    {
        if ((*year) % 4)
            time += 28L;
        else
            time += 29L;
    }
    else
        time += DaysInMonth[(*month) - 1];

    *day = (int)time + 1;
}

/**
 * @brief Sets the system time.
 *
 * The method adjusts the system's internal time representation based on the
 * supplied time value. It takes into account platform-specific implementations.
 * On platforms supporting RDOS, it translates the binary time to individual
 * date and time components and sets the system time accordingly using RDOS-specific
 * APIs. On other platforms, it uses the default implementation to set the local time.
 *
 * @param time The time to be set, represented as a long integer in seconds
 *             since the Unix epoch (January 1, 1970, 00:00:00 UTC).
 */
void SetTime(long time)
{
#ifdef __RDOS__
    int year, month, day, hour, min, sec;
    unsigned long msb, lsb;

    BinaryToTime(time, &year, &month, &day, &hour, &min, &sec);
    msb = RdosCodeMsbTics(year, month, day, hour);
    lsb = RdosCodeLsbTics(min, sec, 0, 0);
    RdosSetTime(msb, lsb);
#else
    SetLocalTime(time);
#endif
}

/**
 * Retrieves the current time in a platform-independent format.
 *
 * @return The current time as a long integer. It represents the number of seconds since the Unix epoch.
 */
long GetTime()
{
#ifdef __RDOS__
    int year, month, day, hour, min, sec, milli;
    int micro;
    unsigned long msb, lsb;

    RdosUserGetTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &min, &sec, &milli, &micro);
    return TimeToBinary(year, month, day, hour, min, sec);
#else
    struct timespec ts;

    GetLocalTime(&ts);
    return ts.tv_sec;
#endif
}

/**
 * Retrieves the current system time.
 *
 * On RDOS, the time is determined using `RdosUserGetSysTime` to extract
 * the most significant and least significant bits of the system time, which
 * are then decoded into year, month, day, hour, minute, second, millisecond,
 * and microsecond values. The result is converted to a binary representation
 * of the timestamp.
 *
 * On non-RDOS systems, the time is obtained using the `clock_gettime` function
 * for the `CLOCK_REALTIME` clock, and the seconds portion of the time is returned.
 *
 * @return The current system time as a long integer. This represents the
 *         number of seconds since the Unix epoch.
 */
long GetSystemTime()
{
#ifdef __RDOS__
    int year, month, day, hour, min, sec, milli, micro;
    unsigned long msb, lsb;

    RdosUserGetSysTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &min, &sec, &milli, &micro);
    return TimeToBinary(year, month, day, hour, min, sec);
#else
    struct timespec ts;

    clock_gettime(CLOCK_REALTIME, &ts);
    return ts.tv_sec;
#endif
}

/**
 * Suspends the execution of the program for a specified number of milliseconds.
 *
 * @param ms The number of milliseconds to wait. If the value is less than or equal to zero, the function has no effect.
 */
void WaitMilli(int ms)
{
#ifdef __RDOS__
    while (ms > 1000)
    {
        RdosWaitMilli(1000);
        ms -= 1000;
    }
    if (ms > 0)
        RdosWaitMilli(ms);
#else
    usleep(ms * 1000);
#endif
}

#ifndef __RDOS__
/**
 * Converts a Linux `timespec` structure to RDOS time representation.
 * The converted time is split into two 32-bit unsigned long values,
 * `msb` (most significant bits) and `lsb` (least significant bits).
 *
 * @param ts The input `timespec` structure, which represents a time value in
 *           seconds and nanoseconds since the epoch.
 * @param msb Pointer to an unsigned long where the most significant part of the
 *            RDOS time will be stored.
 * @param lsb Pointer to an unsigned long where the least significant part of the
 *            RDOS time will be stored.
 */
static void LinuxToRdos(const struct timespec ts, unsigned long *msb, unsigned long *lsb)
{
    int ival;
    int min;
    int sec;
    u_int64_t usec;
    u_int64_t l;
    u_int64_t m;

    m = ts.tv_sec / 3600 + 17269032;

    ival = ts.tv_sec % 3600;

    sec = ival % 60;
    min = ival / 60;

    usec = ts.tv_nsec / 1000;

    usec += sec * 1000000;
    usec += min * 60000000;

    l = (usec << 32) / 3600000000;
    if (l >= 0x100000000)
    {
        l -= 0x100000000;
        m++;
    }

    *lsb = (unsigned long)l;
    *msb = (unsigned long)m;
}
#endif

#ifndef __RDOS__
/**
 * Converts a date and time represented by two unsigned long values (MSB and LSB)
 * into a `timespec` structure, adjusting for the epoch difference between Rdos
 * and Linux operating systems.
 *
 * @param msb The most significant bits (MSB) of the date and time value.
 * @param lsb The least significant bits (LSB) of the date and time value.
 * @param ts A pointer to a `timespec` structure where the converted time is stored,
 *           with `tv_sec` representing seconds since the Unix epoch and
 *           `tv_nsec` representing nanoseconds.
 */
static void RdosToLinux(unsigned long msb, unsigned long lsb, struct timespec *ts)
{
    u_int64_t val;
    int sec;

    val = (u_int64_t)lsb;
    val = 3600 * val;
    sec = (int)(val >> 32);
    val = val - ((u_int64_t)sec << 32);

    ts->tv_sec = 3600 * (msb - 17269032) + sec;
    ts->tv_nsec = (1000000000 * val) >> 32;
}
#endif

/**
 * @brief Default constructor for the TDateTime class.
 *
 * This constructor initializes the date and time attributes of a TDateTime object.
 * Depending on the operating system, it retrieves the current date and time
 * either through the RdosGetTime function in RDOS environments or
 * the GetLocalTime function in non-RDOS systems.
 *
 * @return An instance of the TDateTime class with initialized date and time values.
 */
TDateTime::TDateTime()
{
#ifdef __RDOS__
    RdosGetTime(&FMsb, &FLsb);
#else
    GetLocalTime(&FTs);
#endif
    RawToRecord();
}

/**
 * @brief Constructs a new TDateTime object by performing a copy from the specified source.
 *
 * This constructor initializes the TDateTime instance by copying the internal
 * representation from another TDateTime object. It ensures the internal data is
 * correctly transferred depending on the platform and converts it into a usable record format.
 *
 * @param source The TDateTime object to copy from.
 * @return A new TDateTime instance initialized with values copied from the source object.
 */
TDateTime::TDateTime(const TDateTime &source)
{
#ifdef __RDOS__
    FMsb = source.FMsb;
    FLsb = source.FLsb;     
#else
    memcpy(&FTs, &source.FTs, sizeof(struct timespec));
#endif
    RawToRecord();
}

/**
 * Constructor for the TDateTime class that initializes a date and time
 * object using the provided most significant bits (Msb) and least significant
 * bits (Lsb). The initialization approach varies depending on the system.
 *
 * @param Msb The most significant bits representing a part of the date/time.
 * @param Lsb The least significant bits representing a part of the date/time.
 * @return A new instance of the TDateTime object with date/time initialized
 *         based on the given parameters.
 */
TDateTime::TDateTime(unsigned long Msb, unsigned long Lsb)
{
#ifdef __RDOS__
    FMsb = Msb;
    FLsb = Lsb;
#else
    RdosToLinux(Msb, Lsb, &FTs);
#endif
    RawToRecord();
}

/**
 * @brief Constructs a TDateTime object from a raw 64-bit unsigned integer value.
 *
 * This constructor initializes the TDateTime object by interpreting the
 * provided raw 64-bit value, either using platform-specific logic for RDOS or
 * converting it to a timestamp for other platforms.
 *
 * @param Raw The raw 64-bit unsigned integer representing the date and time.
 *            On RDOS, this is split into two 32-bit values. On other systems,
 *            it is converted into a timestamp.
 * @return A TDateTime object initialized with the converted or processed date
 *         and time values from the input.
 */
TDateTime::TDateTime(unsigned long long Raw)
{
#ifdef __RDOS__
    unsigned long Val[2];

    memcpy(Val, &Raw, 8);

    FMsb = Val[1];
    FLsb = Val[0];
#else
    unsigned long msb = (unsigned long)(Raw >> 32);
    unsigned long lsb = (unsigned long)(Raw & 0xFFFFFFFF);

    RdosToLinux(msb, lsb, &FTs);
#endif
    RawToRecord();
}

/**
 * Constructs a TDateTime object from a long double value representing a date and time.
 *
 * @param real A long double representing the date and time. The integer part represents
 *             the date, and the fractional part represents the time.
 *
 * @return None.
 */
TDateTime::TDateTime(long double real)
{
#ifdef __RDOS__
    FMsb = (unsigned long)floor(real);
    FLsb = (unsigned long)((real - (long double)FMsb) * 65536.0 * 65536.0);
#else
    unsigned long msb = (unsigned long)floor(real);
    unsigned long lsb = (unsigned long)((real - (long double)msb) * 65536.0 * 65536.0);

    RdosToLinux(msb, lsb, &FTs);
#endif
    RawToRecord();
}

/**
 * Constructs a TDateTime object representing a specific date
 * with time components initialized to default values (midnight).
 *
 * @param Year The year component of the date.
 * @param Month The month component of the date, where 1 corresponds to January and 12 corresponds to December.
 * @param Day The day component of the date, representing the day of the month.
 * @return A TDateTime object initialized with the specified date and time set to 00:00:00.000000.
 */
TDateTime::TDateTime(int Year, int Month, int Day)
{
    FYear = Year;
    FMonth = Month;
    FDay = Day;
    FHour = 0;
    FMin = 0;
    FSec = 0;
    FMilli = 0;
    FMicro = 0;
    RecordToRaw();
}

/**
 * Constructs a TDateTime object with the specified date and time values.
 *
 * @param Year The year component of the date.
 * @param Month The month component of the date (1-12).
 * @param Day The day component of the date (1-31 depending on the month).
 * @param Hour The hour component of the time (0-23).
 * @param Min The minute component of the time (0-59).
 * @param Sec The second component of the time (0-59).
 * @return A new instance of TDateTime initialized with the provided date and time values.
 */
TDateTime::TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec)
{
    FYear = Year;
    FMonth = Month;
    FDay = Day;
    FHour = Hour;
    FMin = Min;
    FSec = Sec;
    FMilli = 0;
    FMicro = 0;
    RecordToRaw();
}

/**
 * Constructs a TDateTime object with the specified date and time components.
 *
 * @param Year The year component of the date.
 * @param Month The month component of the date (1-12).
 * @param Day The day component of the date (1-31, depending on the month and year).
 * @param Hour The hour component of the time (0-23).
 * @param Min The minute component of the time (0-59).
 * @param Sec The second component of the time (0-59).
 * @param Milli The millisecond component of the time (0-999).
 * @param Micro The microsecond component of the time (0-999).
 * @return A TDateTime instance initialized with the specified date and time components.
 */
TDateTime::TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec, int Milli, int Micro)
{
    FYear = Year;
    FMonth = Month;
    FDay = Day;
    FHour = Hour;
    FMin = Min;
    FSec = Sec;
    FMilli = Milli;
    FMicro = Micro;
    RecordToRaw();
}

/**
 * Assigns the values from another TDateTime object to this object.
 *
 * @param src The source TDateTime object from which to copy the values.
 * @return A reference to this TDateTime object with updated values.
 */
const TDateTime &TDateTime::operator=(const TDateTime &src)
{
    FYear = src.FYear;
    FMonth = src.FMonth;
    FDay = src.FDay;
    FHour = src.FHour;
    FMin = src.FMin;
    FSec = src.FSec;
    FMilli = src.FMilli;
    FMicro = src.FMicro;
#ifdef __RDOS__
    FMsb = src.FMsb;
    FLsb = src.FLsb;
#else
    memcpy(&FTs, &src.FTs, sizeof(struct timespec));
#endif
    return *this;
}

/**
 * @brief Converts the TDateTime object to a long double representation.
 *
 * This operator provides a conversion of the TDateTime instance to a
 * long double value. On RDOS systems, it uses FLsb and FMsb for conversion.
 * On other systems, it utilizes the LinuxToRdos function to compute the
 * necessary values for conversion.
 *
 * @return A long double value representing the TDateTime instance.
 */
TDateTime::operator long double () const
{
#ifdef __RDOS__
    long double fract;

    fract = (long double)FLsb / 65536.0 / 65536.0;
    return (long double)FMsb + fract;
#else
    unsigned long msb, lsb;
    long double fract;

    LinuxToRdos(FTs, &msb, &lsb);

    fract = (long double)lsb / 65536.0 / 65536.0;
    return (long double)msb + fract;
#endif
}

/**
 * @brief Sets the current object timestamp based on a Linux timestamp value.
 *
 * Converts the given Linux timestamp value (seconds since the Unix epoch) into
 * the appropriate internal format depending on the operating environment.
 * On RDOS, it converts the timestamp into specific system values.
 * On other systems, it modifies the timespec structure.
 *
 * @param val The Linux timestamp value (seconds since the Unix epoch).
 */
void TDateTime::SetLinuxTimestamp(long long val)
{
#ifdef __RDOS__
    long long temp;
    int ival;
    int min;
    int sec;

    temp = val / 3600 + 17269032;
    FMsb = (unsigned long)temp;

    ival = (int)(val % 3600);

    sec = ival % 60;
    min = ival / 60;

    FLsb = RdosCodeLsbTics(min, sec, 0, 0);

#else
    FTs.tv_sec = val;
    FTs.tv_nsec = 0;

#endif
    RawToRecord();
}

/**
 * @brief Sets the datetime value using a Linux millisecond-based timestamp.
 *
 * This method converts a Linux millisecond timestamp into the internal
 * representation of TDateTime and updates the object's state accordingly.
 * The implementation varies depending on the platform.
 *
 * @param val The Linux millisecond timestamp to be set.
 */
void TDateTime::SetLinuxMilliTimestamp(long long val)
{
#ifdef __RDOS__
    long long temp;
    int ival;
    int min;
    int sec;
    int milli;

    temp = val / 3600 / 1000 + 17269032;
    FMsb = (unsigned long)temp;

    ival = (int)(val % 3600000);

    milli = ival % 1000;
    ival = ival / 1000;

    sec = ival % 60;
    min = ival / 60;

    FLsb = RdosCodeLsbTics(min, sec, milli, 0);
#else
    FTs.tv_sec = val / 10000000;
    FTs.tv_nsec = (val % 10000000) * 1000;
#endif
    RawToRecord();
}

/**
 * @brief Sets the current date and time for the TDateTime object.
 *
 * This method retrieves the current system date and time and updates the
 * TDateTime object with the retrieved values. On certain platforms,
 * platform-specific functions may be used for retrieving the time.
 *
 * For RDOS systems, it uses the RdosGetTime function to fetch the time
 * and updates internal variables FMsb and FLsb. For other platforms,
 * it retrieves the time using GetLocalTime and updates the FTs structure.
 *
 * Once the raw time is retrieved, the method converts it into the
 * internal record format by calling RawToRecord.
 *
 * @note Behavior may vary depending on the operating system and platform.
 */
void TDateTime::SetCurrent()
{
#ifdef __RDOS__
    RdosGetTime(&FMsb, &FLsb);
#else
    GetLocalTime(&FTs);
#endif
    RawToRecord();
}

/**
 * Sets the raw date and time using the provided most significant and least significant bits.
 *
 * Depending on the operating system, this method either directly sets the internal representation
 * of the date and time or converts the provided values to the appropriate format before updating
 * the internal state.
 *
 * @param Msb The most significant bits representing the date and time.
 * @param Lsb The least significant bits representing the date and time.
 */
void TDateTime::SetRaw(unsigned long Msb, unsigned long Lsb)
{
#ifdef __RDOS__
    FMsb = Msb;
    FLsb = Lsb;
#else
    RdosToLinux(Msb, Lsb, &FTs);
#endif
    RawToRecord();
}

/**
 * Retrieves the most significant bits (MSB) of the internal timestamp value.
 * On RDOS systems, the MSB is stored directly in the FMsb member.
 * On non-RDOS systems, the MSB is calculated by converting the internal
 * timestamp representation using the LinuxToRdos function.
 *
 * @return The most significant bits (MSB) of the timestamp as an unsigned long.
 */
unsigned long TDateTime::GetMsb() const
{
#ifdef __RDOS__
    return FMsb;
#else
    unsigned long msb, lsb;

    LinuxToRdos(FTs, &msb, &lsb);
    return msb;
#endif
}

/**
 * Retrieves the least significant bits (LSB) of the timestamp associated with the TDateTime object.
 *
 * This method returns the LSB value of the timestamp, which may differ depending on the underlying
 * operating system. On RDOS, the value is directly retrieved from the class variable FLsb. On non-RDOS systems,
 * the LSB is determined by converting the internal timestamp representation using a platform-specific function.
 *
 * @return The least significant bits of the timestamp as an unsigned long.
 */
unsigned long TDateTime::GetLsb() const
{
#ifdef __RDOS__
    return FLsb;
#else
    unsigned long msb, lsb;

    LinuxToRdos(FTs, &msb, &lsb);
    return lsb;
#endif
}

/**
 * @brief Determines whether the current instance of the object has expired
 *        based on the current time and its stored expiration time.
 *
 * This method compares the stored expiration time against the current local
 * time to determine if the object has exceeded its validity period. On RDOS systems,
 * the time comparison uses higher and lower significant parts; on other systems,
 * it uses the seconds and nanoseconds values of the current time.
 *
 * @return true if the object has expired; false otherwise.
 */
bool TDateTime::HasExpired() const
{
#ifdef __RDOS__
    unsigned long msb, lsb;

    RdosGetTime(&msb, &lsb);

    if (msb > FMsb)
        return true;

    if (msb < FMsb)
        return false;

    if (lsb > FLsb)
        return true;
    else
        return false;
#else
    struct timespec now;

    GetLocalTime(&now);
    if (now.tv_sec > FTs.tv_sec)
        return true;
    else if (now.tv_sec < FTs.tv_sec)
        return false;
    else if (now.tv_nsec >= FTs.tv_nsec)
        return true;
    else
        return false;
#endif
}

/**
 * @brief Blocks execution until the expiration time represented by the current TDateTime object is reached.
 *
 * Depending on the platform, the method calculates the remaining time until expiration
 * and suspends the thread for the necessary duration. On RDOS systems, a platform-specific
 * mechanism is used. On other systems, the method uses local system time to perform
 * the waiting until the target expiration time is reached.
 *
 * @note This function makes use of platform-specific APIs under the hood,
 *       such as RdosWaitRealUntil on RDOS and usleep elsewhere, to achieve the waiting functionality.
 *
 * @warning Potential discrepancies may occur if the system time is modified while
 *          the function is waiting on non-RDOS platforms.
 *
 * @exception None
 */
void TDateTime::WaitUntilExpired() const
{
#ifdef __RDOS__
    RdosWaitRealUntil(FMsb, FLsb);
#else
    struct timespec now;
    int diff;
    int usec;

    GetLocalTime(&now);
    diff = (int)(FTs.tv_sec - now.tv_sec);
    if (diff > 0)
    {
        usec = 1000000 * diff;
        usec += (int)(FTs.tv_nsec - now.tv_nsec) / 1000;
        usleep(usec);
    }

#endif
}

/**
 * Retrieves the day of the week for the current date represented by the TDateTime object.
 * The day of the week is returned as an integer value, where typically 0 represents Sunday,
 * 1 represents Monday, and so forth, depending on the platform's implementation.
 *
 * @return Integer representing the day of the week (0-6), where the mapping of values
 *         to days depends on the underlying platform.
 */
int TDateTime::GetDayOfWeek() const
{
#ifdef __RDOS__
    return RdosDayOfWeek(FYear, FMonth, FDay);
#else
    struct tm tm;

    localtime_r(&FTs.tv_sec, &tm);
    return tm.tm_wday;
#endif
}

/**
 * Retrieves the year component of the date.
 *
 * @return The year as an integer.
 */
int TDateTime::GetYear() const
{
    return FYear;
}

/**
 * Retrieves the month component of the TDateTime instance.
 *
 * @return The month as an integer value, where 1 represents January and 12 represents December.
 */
int TDateTime::GetMonth() const
{
    return FMonth;
}

/**
 * Retrieves the day component of the date.
 *
 * @return The day of the month as an integer.
 */
int TDateTime::GetDay() const
{
    return FDay;
}

/**
 * Retrieves the hour component of the date-time value.
 *
 * @return The hour component as an integer, typically in the range 0-23.
 */
int TDateTime::GetHour() const
{
    return FHour;
}

/**
 * Retrieves the minute component of the date-time object.
 *
 * @return The minute value as an integer.
 */
int TDateTime::GetMin() const
{
    return FMin;
}

/**
 * Retrieves the number of seconds stored in the TDateTime object.
 *
 * @return The number of seconds as an integer.
 */
int TDateTime::GetSec() const
{
    return FSec;
}

/**
 * Retrieves the millisecond component of the TDateTime object.
 *
 * @return The millisecond value as an integer.
 */
int TDateTime::GetMilliSec() const
{
    return FMilli;
}

/**
 * Retrieves the microsecond part of the datetime object.
 *
 * @return The microsecond value as an integer.
 */
int TDateTime::GetMicroSec() const
{
    return FMicro;
}

/**
 * Retrieves the Linux/Unix timestamp representation of the date and time
 * stored in the TDateTime object. The timestamp represents the number of
 * seconds since the Unix epoch (January 1, 1970, 00:00:00 UTC).
 *
 * @return A long long integer representing the Linux/Unix timestamp. In systems
 *         where the __RDOS__ macro is defined, the timestamp is calculated
 *         based on custom logic. Otherwise, it retrieves the value from
 *         `FTs.tv_sec`.
 */
long long TDateTime::GetLinuxTimestamp() const
{
#ifdef __RDOS__
    int ival;
    long long val;

    ival = FMin;
    ival = 60 * ival + FSec;

    val = (long long)FMsb - 17269032;
    val = 3600 * val + (long long)ival;

    return val;
#else
    return FTs.tv_sec;
#endif
}

/**
 * @brief Retrieves the Linux timestamp in milliseconds for the current date and time.
 *
 * This method returns the number of milliseconds since the Unix epoch
 * (January 1, 1970, 00:00:00 UTC) for the current system.
 * The calculation method depends on the operating system.
 *
 * @return The Linux timestamp in milliseconds as a long long integer.
 */
long long TDateTime::GetLinuxMilliTimestamp() const
{
#ifdef __RDOS__
    int ival;
    long long val;

    ival = FMin;
    ival = 60 * ival + FSec;
    ival = 1000 * ival + FMilli;

    val = (long long)FMsb - 17269032;
    val = 3600 * 1000 * val + (long long)ival;

    return val;
#else
    return FTs.tv_sec * 1000 + FTs.tv_nsec / 1000000;
#endif
}

/**
 * @brief Updates the system time based on the current TDateTime instance.
 *
 * This method sets the system's current time using the TDateTime instance's
 * internal time attributes. The behavior varies depending on the compilation
 * target. For `__RDOS__`, it uses the `RdosSetTime` function with the
 * most significant (`FMsb`) and least significant (`FLsb`) byte values.
 * Otherwise, it sets the time using the local time derived from `FTs.tv_sec`.
 *
 * @note This method directly modifies the system's time and should
 * only be used when system-wide changes are necessary.
 */
void TDateTime::Set()
{
#ifdef __RDOS__
    RdosSetTime(FMsb, FLsb);
#else
    SetLocalTime(FTs.tv_sec);
#endif
}

/**
 * @brief Converts raw timestamp data into a structured date and time record.
 *
 * This method processes raw timestamp values stored within the object
 * and extracts year, month, day, hour, minute, second, millisecond,
 * and microsecond information. It handles platform-specific differences
 * based on whether the environment is RDOS or not.
 *
 * On RDOS systems, the method uses `RdosDecodeMsbTics` and `RdosDecodeLsbTics`
 * to extract the date and time components from `FMsb` and `FLsb`. For non-RDOS systems,
 * it utilizes `BinaryToTime` and derives millisecond and microsecond values
 * directly from nanosecond data within the `FTs` structure.
 *
 * Platform-specific behavior:
 * - RDOS: Relies on MSB and LSB decoding functions.
 * - Non-RDOS: Works with binary time and nanosecond data.
 */
void TDateTime::RawToRecord()
{
#ifdef __RDOS__
    RdosDecodeMsbTics(FMsb, &FYear, &FMonth, &FDay, &FHour);
    RdosDecodeLsbTics(FLsb, &FMin, &FSec, &FMilli, &FMicro);
#else
    BinaryToTime(FTs.tv_sec, &FYear, &FMonth, &FDay, &FHour, &FMin, &FSec);
    FMilli = FTs.tv_nsec / 1000000;
    FMicro = FTs.tv_nsec / 1000 - (FMilli * 1000);
#endif
}

/**
 * @brief Converts the internal date and time values to a raw representation.
 *
 * This method encodes the internal date and time fields into a raw format that is
 * platform-specific. On systems with the __RDOS__ preprocessor directive defined,
 * it uses `RdosCodeMsbTics` and `RdosCodeLsbTics` to compute the raw representation.
 * On other systems, it encodes to seconds and nanoseconds using `TimeToBinary`.
 *
 * For RDOS systems:
 * - `RdosCodeMsbTics` encodes the most significant bits of the date and time.
 * - `RdosCodeLsbTics` encodes the least significant bits of the minute, second,
 *   millisecond, and microsecond components.
 *
 * For non-RDOS systems:
 * - The seconds since the epoch are calculated using `TimeToBinary`.
 * - Nanoseconds are computed from the millisecond and microsecond values.
 *
 * This method updates the appropriate member variables (`FMsb`, `FLsb`, or `FTs`) based
 * on the target platform.
 */
void TDateTime::RecordToRaw()
{
#ifdef __RDOS__
    FMsb = RdosCodeMsbTics(FYear, FMonth, FDay, FHour);
    FLsb = RdosCodeLsbTics(FMin, FSec, FMilli, FMicro);
#else
    FTs.tv_sec = TimeToBinary(FYear, FMonth, FDay, FHour, FMin, FSec);
    FTs.tv_nsec = (FMilli * 1000000) + (FMicro * 1000);
#endif
}

/**
 * @brief Adjusts the date and time by adding the specified number of tics.
 *
 * This method updates the internal date and time representation by adding
 * the given number of tics. A tic represents an interval of time, and
 * its impact on the date and time is determined by the system-specific
 * implementation.
 *
 * @param tics The number of tics to add to the current date and time.
 */
void TDateTime::AddTics(long tics)
{
#ifdef __RDOS__
    RdosAddTics(&FMsb, &FLsb, tics);
#else
    FTs.tv_nsec += 1000000000 * tics / 1193046;
    FTs.tv_sec += FTs.tv_nsec / 1000000000;
    FTs.tv_nsec %= 1000000000;
#endif
    RawToRecord();
}

/**
 * @brief Adds the specified number of milliseconds to the current date and time value.
 *
 * This method updates the internal representation of the date and time by adding
 * the provided number of milliseconds. The date and time representation varies
 * depending on the platform.
 *
 * @param ms The number of milliseconds to add. Can be positive or negative.
 */
void TDateTime::AddMilli(long ms)
{
#ifdef __RDOS__
    RdosAddMilli(&FMsb, &FLsb, ms);
#else
    FTs.tv_nsec += 1000000 * ms;
    FTs.tv_sec += FTs.tv_nsec / 1000000000;
    FTs.tv_nsec %= 1000000000;
#endif
    RawToRecord();
}

/**
 * Adds the specified number of microseconds to the current TDateTime object.
 *
 * This method updates the internal time representation by adding the given
 * microseconds. It adjusts the nanoseconds and seconds fields accordingly
 * to ensure proper normalization of the time components.
 *
 * @param us The number of microseconds to add. This parameter should be a
 *           positive or negative integer representing the offset to adjust
 *           the time by.
 */
void TDateTime::AddMicro(long us)
{
#ifdef __RDOS__
    RdosAddMicro(&FMsb, &FLsb, us);
#else
    FTs.tv_nsec += 1000 * us;
    FTs.tv_sec += FTs.tv_nsec / 1000000000;
    FTs.tv_nsec %= 1000000000;
#endif
    RawToRecord();
}

/**
 * @brief Adds the specified number of seconds to the current date and time.
 *
 * This method updates the internal representation of the date and time
 * by adding the given number of seconds. The modification is handled
 * differently depending on the platform.
 *
 * @param sec The number of seconds to add to the current date and time.
 */
void TDateTime::AddSec(long sec)
{
#ifdef __RDOS__
    RdosAddSec(&FMsb, &FLsb, sec);
#else
    FTs.tv_sec += sec;
#endif
    RawToRecord();
}

/**
 * Adds the specified number of minutes to the current date and time instance.
 *
 * @param min The number of minutes to be added. Can be negative to subtract minutes.
 */
void TDateTime::AddMin(long min)
{
#ifdef __RDOS__
    RdosAddMin(&FMsb, &FLsb, min);
#else
    FTs.tv_sec += 60 * min;
#endif
    RawToRecord();
}

/**
 * Adds the specified number of hours to the current TDateTime object.
 *
 * This method adjusts the internal representation of the time to increase
 * the hour component by the specified value. The adjustment respects
 * platform-specific implementations for handling the update.
 *
 * @param hour The number of hours to add. Can be positive or negative.
 */
void TDateTime::AddHour(long hour)
{
#ifdef __RDOS__
    RdosAddHour(&FMsb, &FLsb, hour);
#else
    FTs.tv_sec += 60 * 60 * hour;
#endif
    RawToRecord();
}

/**
 * @brief Adds the specified number of days to the current date and time.
 *
 * This method updates the internal representation of the date and time
 * by adding the given number of days. It accounts for the platform-specific
 * implementation to handle the internal date-time structure.
 *
 * @param day The number of days to add. Can be a positive or negative value.
 */
void TDateTime::AddDay(long day)
{
#ifdef __RDOS__
    RdosAddDay(&FMsb, &FLsb, day);
#else
    FTs.tv_sec += 60 * 60 * 24 * day;
#endif
    RawToRecord();
}

/**
 * @brief Adjusts the date by adding or subtracting the specified number of months.
 *
 * This method modifies the internal date representation by adding or subtracting
 * the given number of months. If the resulting month value exceeds 12, the year
 * is incremented accordingly. Similarly, if the resulting month value is less
 * than or equal to 0, the year is decremented. The changes are reflected in the
 * internal raw date representation.
 *
 * @param month The number of months to add. Use a negative value to subtract months.
 */
void TDateTime::AddMonth(long month)
{
    FMonth += month;

    if (month > 0)
    {
        while (FMonth > 12)
        {
            FYear++;
            FMonth -= 12;
        }
    }

    if (month < 0)
    {
        while (FMonth <= 0)
        {
            FYear--;
            FMonth += 12;
        }
    }
    RecordToRaw();
}

/**
 * @brief Adds the specified number of years to the current TDateTime instance.
 *
 * This method modifies the year component of the TDateTime object by the given value.
 * After updating the year, the internal representation is synchronized.
 *
 * @param year The number of years to add to the current TDateTime object.
 *             Can be a positive or negative value.
 */
void TDateTime::AddYear(long year)
{
    FYear += year;
    RecordToRaw();
}

/**
 * @brief Advances the current date to the next day.
 *
 * This method resets the time components (hour, minute, second, millisecond, and microsecond)
 * of the TDateTime object to zero, representing the start of a new day. It then increments
 * the date component by one day.
 *
 * The method operates on the internal state of the TDateTime object and ensures the
 * transition from the current day to the next is correctly reflected.
 */
void TDateTime::NextDay()
{
    FHour = 0;
    FMin = 0;
    FSec = 0;
    FMilli = 0;
    FMicro = 0;
    RecordToRaw();
    AddDay(1);
}
