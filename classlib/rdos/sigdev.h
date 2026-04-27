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
# sigdev.h
# Basic user-level signal class
#
########################################################################*/

#ifndef _SIGDEV_H
#define _SIGDEV_H

#include "waitdev.h"

/**
 * @class TSignalDevice
 * @brief A device class leveraging signaling capabilities, derived from TWaitDevice.
 *
 * This class provides functionality for signaling and synchronization in a multithreaded
 * environment. It is particularly useful for scenarios where threads need to wait
 * on or signal events, such as device state changes or data availability. The class
 * includes platform-specific behaviors (e.g., RDOS or POSIX implementations) for
 * wait and signal mechanisms.
 */
class TSignalDevice : public TWaitDevice
{
public:
	TSignalDevice();
    virtual ~TSignalDevice();

    void Clear();
    void Signal();
    bool IsSignalled();

#ifndef __RDOS__
    virtual bool WaitForever();
    virtual bool WaitTimeout(int MilliSec);
    virtual bool WaitUntil(TDateTime &time);
#endif

	TSignalDevice *List;

protected:

    /**
     * @brief Signals the availability of new data in the device.
     *
     * This method is used to notify that new data is available for processing. It
     * provides a signaling mechanism for coordinating data availability in a
     * multithreaded environment. The implementation of this method is platform-specific
     * and ensures synchronization between threads waiting for data.
     *
     * Derived from the `TWaitDevice` base class, this method may involve notifying
     * listeners, waking up threads, or updating internal state to indicate that
     * new data has been signaled.
     */
	virtual void SignalNewData();

#ifdef __RDOS__
    virtual void Add(TWait *Wait);
#else
    /**
     * @var FMutex
     * @brief A POSIX threading mutex used for synchronization within the TSignalDevice class.
     *
     * This mutex ensures thread-safe access to critical sections of code, such as managing
     * the signaling state (`FSignalled`) or condition variable (`FCond`), within the
     * TSignalDevice implementation. It is initialized with the default settings provided
     * by `PTHREAD_MUTEX_INITIALIZER` and is primarily used to enforce mutual exclusion
     * when multiple threads interact with the signaling mechanisms.
     *
     * The mutex is locked and unlocked using standard POSIX threading functions
     * (`pthread_mutex_lock` and `pthread_mutex_unlock`), ensuring proper synchronization
     * in multithreaded environments where signal handling occurs.
     */
    pthread_mutex_t FMutex;
    /**
     * @var pthread_cond_t FCond
     * @brief Condition variable used for thread synchronization within TSignalDevice.
     *
     * This variable is part of the platform-specific implementation of the TSignalDevice class
     * and is utilized to coordinate thread signaling and waiting operations.
     * It enables efficient waiting mechanisms for threads, allowing one or more threads to
     * wait until they are signaled, subject to conditions like timeouts or specific deadlines.
     */
    pthread_cond_t FCond;
    /**
     * @var FSignalled
     * @brief Represents the signal state of the device in non-RDOS platforms.
     *
     * This variable is used to indicate whether the device has been signaled or not.
     * It plays a critical role in synchronization and event notification mechanisms
     * by tracking the state of signaling in the platform-specific implementation.
     * Primarily utilized in non-RDOS environments, it is manipulated through methods
     * such as `Signal`, `Clear`, and `IsSignalled` to ensure thread-safe signaling
     * and waiting operations.
     */
    bool FSignalled;
#endif

private:
    void Init();

#ifdef __RDOS__
    int FHandle;
#endif
};

#endif

