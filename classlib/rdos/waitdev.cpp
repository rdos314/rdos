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
# waitdev.cpp
# Waitable device class
#
########################################################################*/

#include "waitdev.h"

#ifdef __RDOS__
#include <rdos.h>
#endif

/*##########################################################################
#
#   Name       : ThreadStartup
#
#   Purpose....: Startup procedure for thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#ifdef __RDOS__
/**
 * Initiates the execution of a thread by invoking the Execute method
 * on the provided TWait object.
 *
 * @param ptr A pointer to a TWait object that contains the thread execution logic.
 */
static void ThreadStartup(void *ptr)
{
    ((TWait *)ptr)->Execute();
}
#endif

/**
 * @brief Constructs a TWaitDevice object and initializes its internal state.
 *
 * This constructor is responsible for setting up the initial state of the
 * TWaitDevice object. It calls the private Init() method to perform
 * necessary setup tasks related to the internal state of the object.
 *
 * On platforms where the __RDOS__ preprocessor directive is defined,
 * additional initialization specific to the platform may be performed.
 *
 * @return A newly initialized TWaitDevice object.
 */
TWaitDevice::TWaitDevice(const char *DeviceName)
    : TDevice(DeviceName)
{
    Init();
}

/**
 * @brief Destructor for the TWaitDevice class.
 *
 * Cleans up any platform-specific resources associated with the wait functionality.
 * Specifically, if compiled on an RDOS platform and the internal wait object
 * (`FWait`) is not null, the destructor deletes the `FWait` object to release
 * memory and avoid resource leaks. This cleanup ensures that the TWaitDevice
 * instance is properly dismantled when its lifecycle ends.
 *
 * The destructor functionality is conditionally compiled only for RDOS
 * platforms, and does nothing on other platforms.
 */
TWaitDevice::~TWaitDevice()
{
#ifdef __RDOS__
    if (FWait)
        delete FWait;
#endif
}

/**
 * @brief Initializes the TWaitDevice instance.
 *
 * This method is used internally to perform platform-specific initialization
 * of a TWaitDevice instance. On the __RDOS__ platform, it ensures that the
 * FWait member is initialized to 0.
 *
 * This method is automatically called during the construction of the TWaitDevice
 * instance and should not be called directly by the user.
 */
void TWaitDevice::Init()
{
#ifdef __RDOS__
    FWait = 0;
#endif
}

/**
 * @brief Creates and initializes a wait object if it does not already exist.
 *
 * This method is responsible for ensuring the creation of a `TWait` instance
 * and attaching the current device (`this`) to it. If the wait object (`FWait`)
 * is already initialized, the method does nothing. Otherwise, it creates a new
 * `TWait` instance and calls its `Add` method to associate the current device
 * with the wait object.
 *
 * This functionality may be platform-specific and conditionally compiled
 * depending on the presence of `__RDOS__`.
 */
#ifdef __RDOS__
void TWaitDevice::CreateWait()
{       
    if (!FWait)
    {
        FWait = new TWait;
        FWait->Add(this);
    }
}
#endif

/**
 * @brief Removes a wait handle from the device's wait queue.
 *
 * This method removes the specified wait handle associated with the current device instance
 * from the underlying system's wait mechanism. It is typically used to manage the lifecycle
 * of wait operations and to ensure that the system does not retain stale or unnecessary wait objects.
 *
 * @param Wait Pointer to the TWait object to be removed.
 */
#ifdef __RDOS__
void TWaitDevice::Remove(TWait *Wait)
{
    RdosRemoveWait(Wait->GetHandle(), (int)this);
}
#endif

/**
 * @brief Waits indefinitely until an external condition or signal is fulfilled.
 *
 * This method ensures that the device waits indefinitely without a specified timeout.
 * If the internal wait mechanism (`FWait`) does not already exist, it creates one
 * using the `CreateWait` method. Once the wait mechanism is initialized, it delegates
 * the wait operation to the platform-specific implementation of `WaitForever`. If
 * the wait mechanism is not created or fails to initialize, it returns `nullptr`.
 *
 * @return Returns a pointer to the `TWaitDevice` instance if the wait completes successfully.
 *         Returns `nullptr` if the wait mechanism fails to initialize or no implementation exists.
 */
#ifdef __RDOS__
TWaitDevice *TWaitDevice::WaitForever()
{       
    if (!FWait)
        CreateWait();

    if (FWait)
        return FWait->WaitForever();
    else
        return 0;
}
#endif

/**
 * @brief Waits for a specified duration or until the wait condition is met.
 *
 * This method attempts to perform a time-constrained wait operation for the
 * specified number of milliseconds. If the internal wait object does not exist,
 * it creates the wait object before proceeding with the operation. The method
 * then delegates the wait request to the internal wait object, if available.
 *
 * @param MilliSec The timeout duration in milliseconds for the wait operation.
 *                 The method will wait for this specified duration unless the
 *                 condition is met earlier.
 *
 * @return A pointer to the TWaitDevice instance if the wait operation is successful,
 *         or a nullptr if the internal wait object is not available or the wait
 *         operation fails.
 */
#ifdef __RDOS__
TWaitDevice *TWaitDevice::WaitTimeout(int MilliSec)
{       
    if (!FWait)
        CreateWait();

    if (FWait)
        return FWait->WaitTimeout(MilliSec);
    else
        return 0;
}
#endif

/**
 * @brief Waits until the specified time is reached or returns immediately if no wait functionality is available.
 *
 * This method ensures that the device waits until the given time is reached. If the associated wait mechanism
 * is not initialized, it attempts to create it. If the wait mechanism is available, the method delegates the
 * waiting operation to it; otherwise, it returns `nullptr`.
 *
 * @param time The reference time until which the wait operation should occur. This is passed as a reference
 *             to a `TDateTime` object that specifies the target time to wait for.
 *
 * @return A pointer to the `TWaitDevice` instance that completed the wait. Returns `nullptr` if the wait
 *         mechanism is not available or fails to initialize.
 */
#ifdef __RDOS__
TWaitDevice *TWaitDevice::WaitUntil(TDateTime &time)
{       
    if (!FWait)
        CreateWait();

    if (FWait)
        return FWait->WaitUntil(time);
    else
        return 0;
}
#endif

/**
 * @brief Starts a handler thread with the specified name and stack size.
 *
 * This method initializes and starts a new handler thread associated with the device.
 * The thread is configured with the provided thread name and stack size.
 *
 * @param Name The name of the thread being started. It is expected to be a string literal
 *             or a null-terminated character array.
 * @param StackSize The size of the stack, in bytes, allocated for the thread.
 */
#ifdef __RDOS__
void TWaitDevice::StartHandler(const char *Name, int StackSize)
{
    Start(Name, StackSize);
}
#endif

/**
 * @brief Executes an infinite wait loop for the device.
 *
 * This method is intended to perform an indefinite wait operation
 * using the `WaitForever` method in a loop until interrupted or
 * terminated. It is expected to be used within the context of
 * platforms or devices requiring continuous waiting for events or
 * conditions.
 *
 * Note: This method does not return; it blocks indefinitely.
 */
#ifdef __RDOS__
void TWaitDevice::Execute()
{
    for (;;)
        WaitForever();
}
#endif

#ifdef __RDOS__

/**
 * @brief Constructs a TWait object and initializes the wait mechanism.
 *
 * This constructor initializes the internal handle using RdosCreateWait
 * and sets the initial states for the installed flag, thread running status,
 * and wait list pointer.
 *
 * @return A newly constructed TWait object with initialized properties.
 */
TWait::TWait()
 : FListSection("Wait.List")
{
    FHandle = RdosCreateWait();

    FInstalled = true;
    FThreadRunning = false;
    FWaitList = 0;
}

/**
 * @brief Destructor for the TWait class. Cleans up resources associated with the object.
 *
 * This destructor ensures that any running threads are stopped and properly cleaned up.
 * It iterates through the wait list, removes associated devices, and deallocates memory.
 * Finally, it closes the wait handle to release system resources.
 *
 * @return No return value.
 */
TWait::~TWait()
{
    TWaitList *ptr;

    FInstalled = false;

    if (FThreadRunning)
        RdosStopWait(FHandle);

    while (FThreadRunning)
        RdosWaitMilli(25);

    while (FWaitList)
    {
        ptr = FWaitList->List;
                FWaitList->WaitDev->Remove(this);
        delete FWaitList;
        FWaitList = ptr;
    }

    RdosCloseWait(FHandle);
}

/**
 * Retrieves the handle associated with this instance.
 *
 * @return An integer representing the handle.
 */
int TWait::GetHandle()
{
    return FHandle;
}

/**
 * @brief Adds a wait device to the list of objects being waited on by this instance.
 *
 * This method creates a new entry in the wait list and associates the provided
 * `TWaitDevice` instance with this `TWait` object. It ensures thread-safety by
 * entering and leaving a critical section while modifying the wait list.
 *
 * @param dev A pointer to the `TWaitDevice` instance to be added to the wait list.
 *            This device will be monitored or interacted with by the `TWait` instance.
 */
void TWait::Add(TWaitDevice *dev)
{
    TWaitList *entry = new TWaitList;
    
    dev->Add(this);

    FListSection.Enter();
    entry->WaitDev = dev;
    entry->List = FWaitList;
    FWaitList = entry;
    FListSection.Leave();
}

/**
 * @brief Removes a device from the wait list.
 *
 * This method searches the internal wait list for the specified device and removes it if found.
 * If the device is removed, any associated resources or references are also cleaned up appropriately.
 * This method is thread-safe and uses synchronization mechanisms to ensure consistency.
 *
 * @param dev Pointer to the TWaitDevice object to be removed from the wait list.
 */
void TWait::Remove(TWaitDevice *dev)
{
    TWaitList *ptr;
    TWaitList *prev;

    FListSection.Enter();

    prev = 0;
    ptr = FWaitList;
    while (ptr && ptr->WaitDev != dev)
    {
        prev = ptr;
        ptr = ptr->List;
    }

    if (ptr->WaitDev == dev)
    {
        dev->Remove(this);

        if (prev == 0)
            FWaitList = FWaitList->List;
        else
            prev->List = ptr->List;

        delete ptr;
    }

    FListSection.Leave();
}

/**
 * @brief Starts a new thread with the specified name and stack size.
 *
 * This method creates and starts a thread using the specified thread name and stack size.
 *
 * @param ThreadName A pointer to a null-terminated string representing the thread's name.
 *                   The caller is responsible for ensuring the string remains valid
 *                   during the thread creation process.
 * @param StackSize An integer specifying the size of the stack for the thread.
 *                  This value must be greater than zero.
 */
void TWait::StartThreadHandler(const char *ThreadName, int StackSize)
{
    RdosCreateThread(ThreadStartup, ThreadName, this, StackSize);
}

/**
 * @brief Checks the current wait state and retrieves the associated device.
 *
 * This method calls `RdosCheckWait` internally using the current handle (`FHandle`)
 * and returns a pointer to the corresponding `TWaitDevice` instance, if available.
 *
 * @return A pointer to a `TWaitDevice` object representing the device associated
 * with the current wait state. Returns `nullptr` if no device is associated or
 * the wait state is invalid.
 */
TWaitDevice *TWait::Check()
{
    return (TWaitDevice *)RdosCheckWait(FHandle);
}

/**
 * @brief Waits indefinitely for a device event and signals new data if available.
 *
 * This method blocks the execution until an event occurs. If an event is successfully
 * received, the associated device's SignalNewData method is called to handle the new data.
 *
 * @return A pointer to a TWaitDevice object if an event occurs, or nullptr if no event is received.
 */
TWaitDevice *TWait::WaitForever()
{
    TWaitDevice *Wait;

    Wait = (TWaitDevice *)RdosWaitForever(FHandle);
    if (Wait)
        Wait->SignalNewData();

    return Wait;
}

/**
 * @brief Waits for a specified timeout duration and signals the arrival of new data if the wait is successful.
 *
 * This method uses a platform-specific function to perform the wait operation for a given
 * timeout in milliseconds. If the wait is successful and a corresponding device is ready,
 * it signals the arrival of new data by calling the `SignalNewData` method on the related
 * TWaitDevice instance.
 *
 * @param MilliSec Specifies the timeout duration in milliseconds for the wait operation.
 * @return A pointer to a TWaitDevice instance if the wait was successful and a device is ready;
 *         returns nullptr if the wait operation timed out or failed.
 */
TWaitDevice *TWait::WaitTimeout(int MilliSec)
{
    TWaitDevice *Wait;

    Wait = (TWaitDevice *)RdosWaitTimeout(FHandle, MilliSec);
    if (Wait)
        Wait->SignalNewData();

    return Wait;
}

/**
 * @brief Waits until the specified time is reached or exceeded.
 *
 * This method blocks the execution until the provided time is reached or exceeded.
 * Upon successful completion, the method signals the availability of new data
 * via the associated device, if applicable.
 *
 * @param time Reference to a TDateTime object representing the target time
 *             for the wait operation. The time is internally converted to
 *             high and low components (MSB and LSB) as required by the
 *             underlying implementation.
 *
 * @return A pointer to a TWaitDevice object if the wait operation is successful
 *         and a relevant device is available. Returns nullptr if the wait fails
 *         or is interrupted.
 */
TWaitDevice *TWait::WaitUntil(TDateTime &time)
{
    TWaitDevice *Wait;

    Wait = (TWaitDevice *)RdosWaitUntilTimeout(FHandle, time.GetMsb(), time.GetLsb());
    if (Wait)
        Wait->SignalNewData();

    return Wait;
}

/**
 * @brief Aborts the wait operation.
 *
 * This method stops any ongoing wait operation associated with the current
 * instance by calling the underlying system function RdosStopWait.
 * It uses the handle stored in the instance to specify the wait operation
 * to be aborted.
 */
void TWait::Abort()
{
    RdosStopWait(FHandle);
}

/**
 * @brief Executes the main loop to monitor and handle wait conditions for a device.
 *
 * This method runs in a loop as long as the `FInstalled` flag is true. Inside the loop,
 * it continuously waits indefinitely for a signal or event to occur using the `RdosWaitForever`
 * function. When an event is detected, the associated `TWaitDevice` is retrieved and its
 * `SignalNewData` method is invoked to handle the new data or signal appropriately.
 *
 * @note This method is designed for systems where indefinite waiting is necessary, and
 * should be used with care in multithreaded environments or real-time applications.
 */
void TWait::Execute()
{
    TWaitDevice *Wait;

    while (FInstalled)
    {
        Wait = (TWaitDevice *)RdosWaitForever(FHandle);
        if (Wait)
            Wait->SignalNewData();
    }
}
#endif
