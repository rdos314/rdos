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
# datetime.h
# Date & time class
#
########################################################################*/

#ifndef _DATETIME_H
#define _DATETIME_H

#ifndef __RDOS__
#include <time.h>
#endif

/**
 * Converts a given date and time into a binary representation of the number of
 * seconds since the Unix epoch (January 1, 1970, 00:00:00 UTC).
 *
 * @param year The year of the date.
 * @param month The month of the date (1-12).
 * @param day The day of the month (1-31).
 * @param hour The hour of the day (0-23).
 * @param min The minute of the hour (0-59).
 * @param sec The second of the minute (0-59).
 * @return The binary representation of the given date and time as the number
 *         of seconds since the Unix epoch.
 */
long TimeToBinary(int year, int month, int day, int hour, int min, int sec);

/**
 * Converts a binary representation of the number of seconds since the Unix epoch
 * (January 1, 1970, 00:00:00 UTC) into a human-readable date and time.
 *
 * @param time The binary representation of the number of seconds since the Unix epoch.
 * @param year Pointer to an integer where the year will be stored.
 * @param month Pointer to an integer where the month (1-12) will be stored.
 * @param day Pointer to an integer where the day of the month (1-31) will be stored.
 * @param hour Pointer to an integer where the hour of the day (0-23) will be stored.
 * @param min Pointer to an integer where the minutes (0-59) will be stored.
 * @param sec Pointer to an integer where the seconds (0-59) will be stored.
 */
void BinaryToTime(long time, int *year, int *month, int *day, int *hour, int *min, int *sec);

/**
 * Sets the system time to the specified binary representation of the time
 * in seconds since the Unix epoch (January 1, 1970, 00:00:00 UTC).
 *
 * On non-RDOS systems, sets the local time offset based on the difference
 * between the given time and the current system time. On RDOS systems, converts
 * the binary time to its constituent date and time components and updates the
 * system time using RDOS-specific functions.
 *
 * @param time The binary representation of the time, in seconds since the
 *        Unix epoch.
 */
void SetTime(long time);

/**
 * Retrieves the current time as the number of seconds since the Unix epoch
 * (January 1, 1970, 00:00:00 UTC). The method adapts to the specific underlying
 * operating system to obtain the time.
 *
 * @return The current time represented as the number of seconds since the Unix epoch.
 */
long GetTime();

/**
 * Retrieves the current system time as the number of seconds since the Unix epoch
 * (January 1, 1970, 00:00:00 UTC).
 *
 * Depending on the platform, the implementation either:
 * - For RDOS: Decodes the system time from hardware ticks and converts it into
 *   a binary representation of seconds via the TimeToBinary function.
 * - For other platforms: Uses the `clock_gettime` function to retrieve the current time.
 *
 * @return The current system time represented as the number of seconds since
 *         the Unix epoch.
 */
long GetSystemTime();

/**
 * Pauses the execution of the current thread for a specified duration in milliseconds.
 *
 * @param ms The amount of time, in milliseconds, for which the thread should be paused.
 */
void WaitMilli(int ms);

/**
 * Represents a date and time with year, month, day, hour, minute, and second components.
 *
 * This class provides functionality for manipulating, comparing, and obtaining
 * various representations of a specific date and time. Operations can include
 * calculating differences, formatting, or adjusting values.
 *
 * The class ensures that the date and time values remain valid within their
 * expected ranges during manipulation. Behaviors with respect to time zones
 * or daylight saving may depend on implementation details.
 */
class TDateTime
{
public:
    TDateTime();
    TDateTime(const TDateTime &Source);
    TDateTime(unsigned long Msb, unsigned long Lsb);
    TDateTime(unsigned long long Raw);
    TDateTime(long double real);
    TDateTime(int Year, int Month, int Day);
    TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec);
    TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec, int ms, int us);
    const TDateTime &operator=(const TDateTime &src);
    operator long double () const;
    void SetLinuxTimestamp(long long val);
    void SetLinuxMilliTimestamp(long long val);
    void SetCurrent();
    unsigned long GetMsb() const;
    unsigned long GetLsb() const;
    void SetRaw(unsigned long Msb, unsigned long Lsb);
    bool HasExpired() const;
    void WaitUntilExpired() const;
    void AddTics(long tics);
    void AddMicro(long us);
    void AddMilli(long ms);
    void AddSec(long sec);
    void AddMin(long min);
    void AddHour(long hour);
    void AddDay(long day);
    void AddMonth(long month);
    void AddYear(long year);
    void NextDay();
    int GetDayOfWeek() const;
    int GetYear() const;
    int GetMonth() const;
    int GetDay() const;
    int GetHour() const;
    int GetMin() const;
    int GetSec() const;
    int GetMilliSec() const;
    int GetMicroSec() const;
    long long GetLinuxTimestamp() const;
    long long GetLinuxMilliTimestamp() const;
    void Set();
protected:

    /**
     * Populates the individual date and time fields of the TDateTime object based
     * on its internal raw time representation.
     *
     * This method decodes the raw time information stored within the object
     * and updates the year, month, day, hour, minute, second, millisecond,
     * and microsecond fields with the corresponding values.
     *
     * On RDOS platforms, it uses Rdos-specific decoding of the MSB and LSB values.
     * On non-RDOS platforms, it uses the BinaryToTime method and additional
     * calculations to derive time components.
     */
    void RawToRecord();

    /**
     * Updates the raw time representation of the TDateTime object based on its
     * current date and time components.
     *
     * This method calculates and sets either a platform-specific representation
     * of time (for RDOS systems) or a standard time format (on other platforms).
     * For RDOS systems, it utilizes `RdosCodeMsbTics` and `RdosCodeLsbTics` to
     * encode the time. On non-RDOS systems, it calculates seconds since the Unix
     * epoch and nanoseconds based on the object's components.
     *
     * This method is called internally after modifications to date or time
     * components to ensure that the raw time representation remains consistent.
     *
     * Note: This function should not be directly invoked by users; it is meant
     * to be used internally by the class or its methods after time-related
     * changes are made.
     */
    void RecordToRaw();

private:
#ifdef __RDOS__
    /**
     * The most significant 32 bits of a raw timestamp used for internal
     * representation of date and time. This variable is part of the
     * raw storage mechanism for timestamp data and is typically managed
     * in conjunction with the least significant 32 bits (FLsb) to form
     * a complete 64-bit representation of time.
     */
    unsigned long FMsb;
    /**
     * Stores the least significant bits (LSB) of the raw datetime value for
     * encoding and manipulating date and time data in a low-level binary format.
     *
     * This value is typically used in conjunction with a most significant bits
     * (MSB) counterpart to represent a complete raw datetime value in systems
     * where datetime computations or storage rely on a binary representation.
     */
    unsigned long FLsb;
#else
    /**
     * Represents a structure containing time specifications with seconds and
     * nanoseconds precision since the Unix epoch.
     *
     * The `FTs` variable usually holds detailed time information relevant
     * for high-resolution time operations. It includes:
     * - `tv_sec`: Seconds since the epoch (January 1, 1970).
     * - `tv_nsec`: Additional nanoseconds component to extend precision beyond seconds.
     *
     * This structure is leveraged for operations requiring precise timekeeping
     * or elapsed time measurements.
     */
    struct timespec FTs;
#endif

    /**
     * Represents the year component of a date in the TDateTime class.
     *
     * This variable stores the four-digit year (e.g., 2023) associated with a
     * specific instance of TDateTime. The value is internally set or updated
     * through class constructors or assignment operations, and it is used
     * in conjunction with other date and time components to define a complete
     * date-time representation.
     */
    int FYear;
    /**
     * Represents the month component of a date within the TDateTime class.
     *
     * This variable stores the numerical value of the month (1 for January, 2 for February,
     * ..., 12 for December) as part of the internal date representation.
     *
     * It is used in various operations and methods within the TDateTime class to
     * handle and manipulate date information.
     */
    int FMonth;
    /**
     * Represents the day of the month in a date.
     *
     * This variable holds a value corresponding to the day component
     * of a specific date. Its value should fall within the range of 1 to
     * 31, depending on the month and year, and is used in the internal
     * representation and manipulation of dates within the TDateTime class.
     */
    int FDay;
    /**
     * Holds the hour component of a date and time, represented as an integer
     * in the range from 0 to 23.
     *
     * This variable is used internally within the `TDateTime` class to
     * store the hour portion of a specific datetime value. It is initialized
     * during the construction of a `TDateTime` object or updated when related
     * operations are performed on the instance.
     */
    int FHour;
    /**
     * Stores the minute component of a date and time.
     *
     * This variable represents the minute (0–59) within an hour in the context
     * of the TDateTime class. It is used for time representation and manipulation
     * throughout the class's operations, such as construction, assignment, and
     * date/time calculations.
     */
    int FMin;
    /**
     * Represents the second component of a time value in the context of a
     * TDateTime object. It typically ranges from 0 to 59 and is used to store
     * the number of seconds in a given time representation.
     */
    int FSec;
    /**
     * Stores the millisecond component of a timestamp in the TDateTime class.
     *
     * This variable represents the fractional seconds component of a datetime
     * instance, expressed in milliseconds (0-999). It is used in conjunction with
     * the other components (year, month, day, hour, minute, second, and microseconds)
     * to construct and manipulate a complete timestamp.
     */
    int FMilli;
    /**
     * Stores the microsecond component of a datetime value. This represents the
     * fractional part of a second at the microsecond precision level.
     *
     * FMicro is typically used for operations requiring precise time
     * calculations, such as high-resolution timestamps or computing
     * durations with microsecond accuracy. It complements the millisecond
     * component stored in FMilli and other time components like FSec, FMin, etc.
     *
     * The range of FMicro is 0 to 999,999, corresponding to the valid range of
     * microseconds within one second.
     */
    int FMicro;
};

#endif

