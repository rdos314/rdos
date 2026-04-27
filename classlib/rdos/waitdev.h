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
# waitdev.h
# A waitable device class
#
########################################################################*/

#ifndef _WAIT_DEV_H
#define _WAIT_DEV_H

#include "device.h"
#include "datetime.h"

#ifdef __RDOS__
class TWait;
#endif

/**
 * @class TWaitDevice
 * @brief Abstract base class for devices that support wait mechanisms, extending the functionality of TDevice.
 *
 * TWaitDevice provides interfaces and mechanisms for handling waits with or without time constraints.
 * It supports features for both time-bound and indefinite waits.
 * The class is designed with platform-specific implementations,
 * toggling between generic and RDOS-specific functionalities.
 */
class TWaitDevice : public TDevice
{
#ifdef __RDOS__
friend class TWait;
#endif

public:
	TWaitDevice(const char *DeviceName);
	virtual ~TWaitDevice();

#ifdef __RDOS__
	TWaitDevice *WaitForever();
	TWaitDevice *WaitTimeout(int MilliSec);
	TWaitDevice *WaitUntil(TDateTime &time);
	void StartHandler(const char *Name, int StackSize);
#else
/**
 * @brief Abstract method for implementing indefinite wait functionality in a device.
 *
 * This method is intended to be overridden by derived classes to provide
 * platform-specific or device-specific behavior for waiting indefinitely
 * without a timeout. The method blocks the execution until either the
 * wait is interrupted or some condition is met, as defined by the
 * implementation. Must be implemented in all derived classes.
 *
 * @return Returns true if the wait completes successfully, or false
 * if there is an interruption or failure during the wait.
 */
virtual bool WaitForever() = 0;

/**
 * @brief Pure virtual method for performing a time-constrained wait operation in derived devices.
 *
 * This method is designed to allow implementations to wait for a specified duration, expressed in milliseconds.
 * Depending on the implementation, the method will return:
 * - `true` if the wait operation completes successfully within the given time frame.
 * - `false` if the wait operation times out or fails.
 *
 * @param MilliSec Specifies the time duration, in milliseconds, for the timeout wait.
 * @return `true` if the wait operation was successful, `false` otherwise.
 */
virtual bool WaitTimeout(int MilliSec) = 0;

/**
 * @brief Abstract method to wait until a specific point in time.
 *
 * This method forces implementing classes to provide functionality for
 * waiting until the specified time is reached. The behavior of this method
 * may vary depending on the time provided and platform-specific implementations.
 *
 * @param time The reference time until which the wait operation should occur.
 *             This parameter is passed as a reference and may contain platform-
 *             specific time data or formatting.
 *
 * @return A boolean value indicating whether the wait was successful.
 *         Returns true if the operation completed successfully, false otherwise.
 */
virtual bool WaitUntil(TDateTime &time) = 0;
#endif

	int ID;

protected:
#ifdef __RDOS__
    void CreateWait();
	void Remove(TWait *Wait);
	virtual void Add(TWait *Wait) = 0;
#endif

/**
 * @brief Abstract method to signal the availability of new data in a device.
 *
 * This pure virtual method must be implemented by all derived classes
 * to handle scenarios where new data is ready to be processed or consumed.
 * The implementation of this method should ensure appropriate actions are
 * taken upon the arrival of new data, such as notifying listeners, triggering
 * processing, or updating device state.
 *
 * The behavior of this method may vary depending on the specific use case
 * or device requirements.
 */
    virtual void SignalNewData() = 0;

#ifdef __RDOS__
    virtual void Execute();

	TWait *FWait;
#endif

private:
    void Init();
};

#ifdef __RDOS__
/**
 * @class TWaitList
 * @brief Represents a linked list of waitable devices, with each node containing a reference to a TWaitDevice and the next TWaitList node.
 *
 * TWaitList facilitates the organization and management of waitable devices by forming a structure where
 * multiple devices can be linked together. Each node in the list holds a reference to a device, represented
 * as a TWaitDevice instance, and a pointer to the next node in the list, forming a chain-like structure.
 *
 * This class is useful for scenarios where a collection of waitable devices needs to be iterated or
 * managed collectively. Users are responsible for correctly managing the lifespan and relationships
 * between the devices and the list nodes.
 */
class TWaitList
{
    /**
     * @var TWaitDevice* WaitDev
     * @brief Pointer to a TWaitDevice instance, representing a device capable of handling wait operations.
     *
     * This variable serves as a reference to a TWaitDevice object, allowing interaction
     * with devices that implement wait mechanisms for operations such as waiting indefinitely,
     * waiting with a timeout, or waiting until a specific time is reached.
     *
     * The specific behavior of the device is determined by the platform and the derived
     * implementation of TWaitDevice. On RDOS systems, additional platform-specific
     * functionalities may be supported.
     */
public:
    TWaitDevice *WaitDev;
    /**
     * @class TWaitList::List
     * @brief Pointer to the next `TWaitList` element in a linked list structure.
     *
     * Represents the linkage between elements within the wait list functionality.
     * This variable is used to chain multiple `TWaitList` objects together,
     * enabling traversal and management of linked device wait states.
     */
    TWaitList *List;
};

class TWait
{

public:
	TWait();
	virtual ~TWait();

	void StartThreadHandler(const char *ThreadName, int StackSize);
	virtual void Execute();

	TWaitDevice *Check();
	TWaitDevice *WaitForever();
	TWaitDevice *WaitTimeout(int MilliSec);
	TWaitDevice *WaitUntil(TDateTime &time);
	void Abort();

	void Add(TWaitDevice *dev);
	void Remove(TWaitDevice *dev);

	int GetHandle();

private:

    /**
     * @var TWaitList *FWaitList
     * @brief Pointer to the list of wait devices managed by the TWait class.
     *
     * FWaitList represents the head of a linked list structure that keeps track of all TWaitDevice instances
     * added to the wait mechanism. This allows TWait to manage and coordinate the waiting processes
     * for multiple devices effectively. The list supports operations such as adding and removing devices,
     * as well as facilitating checks and wait operations.
     */
    TWaitList *FWaitList;
    /**
     * @var TWait::FListSection
     * @brief Synchronization control mechanism for thread-safe access to the wait list.
     *
     * The FListSection is a member variable of type TSection used to manage access to
     * the internal list of waiting devices (FWaitList) in a thread-safe manner. It ensures
     * that operations such as adding or removing devices to/from the list are performed
     * without race conditions in a multithreaded environment.
     *
     * This synchronization utility encapsulates platform-specific implementations
     * for controlling critical sections, adapting to either RDOS-specific futexes
     * or generic mutex constructs as needed.
     */
    TSection FListSection;

    /**
     * @var FHandle
     * @brief Internal handle used to manage wait operations within the TWait class.
     *
     * FHandle is a platform-dependent integer value that serves as a unique identifier
     * or reference for performing synchronization and wait-related functionality in
     * the context of TWait.
     */
    int FHandle;
    /**
     * @var FThreadRunning
     * @brief Internal flag to track the running state of a thread within the TWait class.
     *
     * This variable is used to indicate whether a thread, associated with the TWait object's execution,
     * is currently active. It plays a critical role in managing thread lifecycle and ensuring
     * proper synchronization while the TWait class performs its operations.
     */
    int FThreadRunning;
    /**
     * @var int FInstalled
     * @brief Indicates whether the waiting mechanism subsystem has been successfully installed.
     *
     * Represents the installation status of the system's wait handling functionality.
     * Used internally within the TWait class to manage and verify subsystem readiness.
     */
    int FInstalled;
};
#endif

#endif

