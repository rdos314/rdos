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
# sigdev.cpp
# Signal device class
#
########################################################################*/

#include <string.h>
#include "device.h"
#include "sigdev.h"

#ifdef __RDOS__
#include <rdos.h>
#else
#include <pthread.h>
#include <time.h>
#endif

/**
 * @brief Constructor for the TSignalDevice class.
 *
 * Initializes a new instance of the TSignalDevice class. This constructor
 * invokes the Init() method to perform internal initialization required for
 * the proper functioning of the object. The TSignalDevice class provides
 * mechanisms for thread-safe signaling and synchronization, inheriting its
 * core functionality from the TWaitDevice base class.
 *
 * This constructor is typically called when creating an instance of
 * TSignalDevice in multithreaded applications, ensuring that the internal
 * state and synchronization primitives are properly set up before usage.
 *
 * @return An instance of the TSignalDevice class with its internal state initialized.
 */
TSignalDevice::TSignalDevice()
    : TWaitDevice("Signal")
{
    Init();
}

/**
 * @brief Destructor for the TSignalDevice class.
 *
 * Cleans up resources associated with the TSignalDevice instance. On platforms
 * where `__RDOS__` is defined, it ensures proper deallocation of the signal handle
 * using the `RdosFreeSignal` function.
 *
 * This destructor is responsible for platform-specific cleanup tasks and ensures
 * that any system-level resources utilized by the signal device are released
 * before the object is destroyed. Failure to invoke this destructor when required
 * may result in resource leaks on RDOS platforms.
 */
TSignalDevice::~TSignalDevice()
{
#ifdef __RDOS__
    RdosFreeSignal(FHandle);
#endif
}

/**
 * @brief Initializes the signal device with platform-specific resources.
 *
 * This method is responsible for setting up the necessary synchronization
 * primitives or handles required for signal management. The implementation
 * varies depending on the operating system.
 *
 * In systems with RDOS (`__RDOS__` defined), this method creates a signal
 * object using `RdosCreateSignal()` and assigns it to the `FHandle` variable.
 *
 * In non-RDOS environments, this method initializes a POSIX mutex (`FMutex`)
 * and condition variable (`FCond`) to enable thread synchronization, and
 * sets the initial signaling state (`FSignalled`) to `false`.
 *
 * It is typically invoked during the initialization phase of the `TSignalDevice`
 * instance to prepare it for signal and synchronization operations.
 */
void TSignalDevice::Init()
{
#ifdef __RDOS__
    FHandle = RdosCreateSignal();
#else
    FMutex = PTHREAD_MUTEX_INITIALIZER;
    FCond = PTHREAD_COND_INITIALIZER;
    FSignalled = false;
#endif
}

/**
 * @brief Adds a waiting object to the signal device.
 *
 * This method registers a wait object to the TSignalDevice, enabling it to be notified
 * when the signal device's state changes. It ensures that the specified wait object
 * (TWait) is linked with the signal handling mechanism provided by the device.
 *
 * The implementation is platform-dependent and specific to RDOS systems, utilizing
 * low-level system calls to manage the wait object.
 *
 * @param Wait A pointer to a TWait object to be added to the signal device.
 */
#ifdef __RDOS__
void TSignalDevice::Add(TWait *Wait)
{
    if (FHandle)
        RdosAddWaitForSignal(Wait->GetHandle(), FHandle, (int)this);
}
#endif

/**
 * @brief Clears the signal state of the device.
 *
 * This method resets the signal state of the TSignalDevice instance, making it
 * unsignaled. The behavior is platform-dependent:
 * - On RDOS platforms, it invokes `RdosResetSignal` to clear the state using the
 *   device's handle.
 * - On non-RDOS platforms, it sets the `FSignalled` flag to `false`, indicating
 *   that the device is no longer signaled.
 *
 * This operation is typically used in scenarios where the signal state needs to
 * be explicitly reset, ensuring that the device can be reused or re-signaled as
 * needed.
 */
void TSignalDevice::Clear()
{
#ifdef __RDOS__
    RdosResetSignal(FHandle);
#else
    FSignalled = false;
#endif
}

/**
 * @brief Checks whether the device is currently signaled.
 *
 * This method determines the signal status of the device. It provides
 * platform-specific implementation depending on the target operating system.
 * On RDOS platforms, it utilizes the `RdosIsSignalled` function to check
 * the signal state using the device handle. On non-RDOS platforms, it
 * checks the value of the internally maintained `FSignalled` flag.
 *
 * @return `true` if the device is signaled, `false` otherwise.
 */
bool TSignalDevice::IsSignalled()
{
#ifdef __RDOS__
    return RdosIsSignalled(FHandle);
#else
    return FSignalled;
#endif
}

/**
 * @brief Signals the availability of a resource or event in the device.
 *
 * This method is designed to signal the occurrence of an event or the availability
 * of a resource to other threads waiting for it. The implementation is platform-specific:
 *
 * - On RDOS platforms, it invokes `RdosSetSignal` to signal the event using the device handle.
 * - On non-RDOS platforms, it uses POSIX threading primitives, including a mutex, condition variable,
 *   and a signaling flag to notify other threads of the event.
 *
 * This mechanism is commonly used in multithreaded applications to ensure proper coordination
 * and synchronization of operations among threads. It ensures that waiting threads are notified
 * when the signaling condition is met.
 */
void TSignalDevice::Signal()
{
#ifdef __RDOS__
    RdosSetSignal(FHandle);
#else
    pthread_mutex_lock(&FMutex);
    FSignalled = true;
    pthread_cond_signal(&FCond);
    pthread_mutex_unlock(&FMutex);
#endif
}

#ifndef __RDOS__
/**
 * @brief Waits indefinitely for the device to be signaled.
 *
 * This method blocks the calling thread until the signaling condition is met.
 * It utilizes a mutex (`FMutex`) and a condition variable (`FCond`) to achieve
 * synchronization in a multithreaded environment. If the signal state (`FSignalled`)
 * is not set, the thread will enter a waiting state until it is awakened by a signal.
 *
 * Once a signal is received, the method updates the signal state, invokes the
 * `SignalNewData()` method to handle new data notification, and then returns `true`.
 *
 * This method ensures thread-safe interaction with the signaling mechanism
 * and provides a robust way to handle synchronization needs where threads need
 * to wait until notified.
 *
 * @return `true` when the device receives a signal and the method completes successfully.
 */
bool TSignalDevice::WaitForever()
{
    pthread_mutex_lock(&FMutex);
    while (!FSignalled)
        pthread_cond_wait(&FCond, &FMutex);
    pthread_mutex_unlock(&FMutex);
    FSignalled = false;
    SignalNewData();
    return true;
}
#endif

#ifndef __RDOS__
/**
 * @brief Waits for a signal from the device for a specified timeout duration.
 *
 * This method blocks the calling thread until a signal is received or the
 * specified timeout period elapses. It utilizes platform-specific synchronization
 * primitives, including a mutex and condition variable, to manage thread-safe
 * signaling. If the signal is received within the timeout period, the signal
 * state is cleared, and appropriate actions, such as invoking SignalNewData(),
 * are performed.
 *
 * @param MilliSec The timeout duration specified in milliseconds. The calling
 *                 thread will block for this duration if no signal is received.
 * @return true if the signal was received before the timeout expired, indicating
 *         the signal state was active; false otherwise.
 */
bool TSignalDevice::WaitTimeout(int MilliSec)
{
    struct timespec ts;
    bool signalled;

    clock_gettime(CLOCK_REALTIME, &ts);

    ts.tv_sec += MilliSec / 1000;
    ts.tv_nsec += 1000000 * (MilliSec % 1000);

    pthread_mutex_lock(&FMutex);
    pthread_cond_timedwait(&FCond, &FMutex, &ts);
    signalled = FSignalled;
    pthread_mutex_unlock(&FMutex);

    if (signalled)
    {
        FSignalled = false;
        SignalNewData();
    }

    return signalled;
}
#endif

/**
 * @brief Waits until a specific time for the device to be signaled.
 *
 * This method blocks the calling thread until the TSignalDevice is signaled,
 * or until the provided time is reached. It uses a condition variable and
 * mutex for thread synchronization. If the device is signaled before the
 * specified time, the signal state is cleared, and the SignalNewData method
 * is called to notify about the new data.
 *
 * This method is useful for coordinating threads in scenarios where
 * one or more threads need to wait for an event or data availability
 * controlled by the TSignalDevice object.
 *
 * @param time A reference to a TDateTime object representing the time
 *             until which the thread should wait. The method converts
 *             this to a real timestamp for timing purposes.
 * @return True if the device was signaled within the specified time,
 *         false if the timeout expired without a signal.
 */
#ifndef __RDOS__
bool TSignalDevice::WaitUntil(TDateTime &time)
{
    struct timespec ts;
    bool signalled;

    time.GetRealTimestamp(&ts);

    pthread_mutex_lock(&FMutex);
    pthread_cond_timedwait(&FCond, &FMutex, &ts);
    signalled = FSignalled;
    pthread_mutex_unlock(&FMutex);

    if (signalled)
    {
        FSignalled = false;
        SignalNewData();
    }

    return signalled;
}
#endif

/**
 * @brief Notifies that new data is available in the device.
 *
 * This method is responsible for signaling the availability of new data,
 * enabling other components or threads waiting for this data to proceed with
 * processing. It is particularly useful in multithreaded environments where
 * coordination between producer and consumer threads is required.
 *
 * The implementation of this method may involve notifying listeners, waking up
 * waiting threads, or updating internal state variables to reflect the signaling
 * event. The exact behavior is platform-dependent and designed to ensure thread-safe
 * synchronization.
 *
 * Derived classes may override this method to provide platform-specific behavior
 * for signaling new data.
 */
void TSignalDevice::SignalNewData()
{
}
