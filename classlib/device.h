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
# device.h
# Basic device class
#
########################################################################*/

#ifndef _DEVICE_H
#define _DEVICE_H

#include <stdlib.h>

#include "section.h"
#include "thread.h"
#include "str.h"
#include "datetime.h"
#include "file.h"

#define MAX_DEVICE_NOTIFY_COUNT	10

class TDevice;

class TDeviceDebug : public TThread
{
public:
    TDeviceDebug();
    virtual ~TDeviceDebug();

    virtual TFile *RequestFile(TDevice *Device);
    virtual void ReleaseFile(TDevice *Device);
    virtual int MaxFileSize();
};

class TDeviceNotify
{
public:
    TDeviceNotify();
    virtual ~TDeviceNotify();

    virtual bool IsBase();
    virtual void NotifyOnline(TDevice *Device);
    virtual void NotifyOffline(TDevice *Device);
    virtual void NotifyIdle(TDevice *Device);
    virtual void NotifyBusy(TDevice *Device);
    virtual void NotifyOpen(TDevice *Device);
    virtual void NotifyClose(TDevice *Device);
    virtual void NotifyEnable(TDevice *Device);
    virtual void NotifyDisable(TDevice *Device);
    virtual void NotifyReset(TDevice *Device);
    virtual void NotifyStateChange(TDevice *Device);
};    

class TDevice : public TThread
{

public:
    TDevice(const char *DeviceName);
    virtual ~TDevice();

    virtual void NotifyReset();
    bool IsReseted() const;

    void Open();
    void Close();
    void Enable();
    void Disable();
    bool IsEnabled();
        
    virtual bool IsOpen();
    virtual bool IsActive();
    virtual bool IsBusy();
    virtual bool IsOnline();
    virtual const char *DeviceName() const;

    static void GetDevices(void (*DeviceCallb)(TDevice *Device));

    void Install(TDeviceDebug *Debug);
    virtual void StartDeviceDebug();
    virtual void StopDeviceDebug();

    void AddNotify(TDeviceNotify *Notify);
    void RemoveNotify(TDeviceNotify *Notify);

    void (*OnOnline)(TDevice *Device);
    void (*OnOffline)(TDevice *Device);
    void (*OnIdle)(TDevice *Device);
    void (*OnBusy)(TDevice *Device);
    void (*OnOpen)(TDevice *Device);
    void (*OnClose)(TDevice *Device);

    void *StateData;
    void (*OnStateChange)(TDevice *Device);

    /**
     * @brief Notifies all registered observers about a state change in the device.
     *
     * This method is used internally to propagate state change notifications to all
     * registered listeners (e.g., observers in the notification array) and to invoke
     * the user-defined state change callback function, if defined.
     *
     * The method first checks whether the `OnStateChange` callback is set. If so, the callback
     * is called with the `TDevice` instance as its parameter.
     *
     * Subsequently, all objects in the `NotifyArr` array are iterated, and their
     * respective `NotifyStateChange()` methods are called with the current device as a parameter.
     *
     * This function can be called as part of other public methods, such as `Open()`, `Close()`,
     * `Enable()`, `Disable()`, or `Online()`, to notify state changes when operations
     * on the device are performed.
     */
protected:
    void NotifyStateChange();

    /**
     * @brief Notifies that the device has been successfully opened.
     *
     * This method handles the Open state of the device and performs
     * the following actions:
     * - Sets the internal flag indicating the device is open.
     * - Invokes the user-defined callback, if assigned, to handle device-specific actions upon opening.
     * - Iterates through the list of registered notification objects and calls their respective
     *   `NotifyOpen` method to propagate this event to external listeners.
     *
     * It ensures that any registered event handlers or listeners are notified about
     * the change in the device's open state.
     */
    virtual void NotifyOpen();

    /**
     * @brief Handles the close event for the device and notifies associated observers.
     *
     * This method is called when the device is being closed. It sets the device's
     * open state to false, triggers the `OnClose` callback if assigned, and
     * iterates through the registered notification observers to notify them
     * about the close event using their `NotifyClose` method.
     *
     * The method is typically invoked internally as part of the `Close` process and
     * ensures that all relevant components and observers are properly updated or
     * informed about the device closure.
     *
     * @note This method is virtual and can be overridden by derived classes
     *       to implement custom behavior for the close notification process.
     */
    virtual void NotifyClose();

    /**
     * @brief Activates the notification mechanism for the device.
     *
     * This method is responsible for enabling the notification system of the device and
     * informs all registered notification objects by calling their respective
     * `NotifyEnable` method. It sets the `FEnabled` flag to `true` and iterates
     * through the array of registered notification objects, if any, notifying them
     * of the enable event.
     *
     * @note This method is typically invoked internally as part of the enable sequence
     *       for the device.
     */
    virtual void NotifyEnable();

    /**
     * Disables the current device instance and notifies associated observers.
     *
     * This method performs the following actions:
     * - Sets the enabled state of the device to `false`.
     * - Iterates through all registered observers in the `NotifyArr` array
     *   and invokes their `NotifyDisable` method, passing the current device
     *   as an argument.
     *
     * This method is typically called as part of the `Disable` process to update
     * the internal state of the device and signal any dependent components
     * about the state change.
     */
    virtual void NotifyDisable();

    /**
     * @brief Notifies the system that the device is idle.
     *
     * This method marks the device as no longer busy by setting the `FBusy` flag to false.
     * It triggers the `OnIdle` callback, if it is defined. Additionally, it iterates
     * through the registered notify objects and invokes their `NotifyIdle` methods,
     * passing a reference to the current device.
     *
     * @note This method ensures that any registered interest in the device's idle state is
     * notified, enabling external components to respond to this state change appropriately.
     */
    virtual void NotifyIdle();

    /**
     * Notifies that the device is now in a busy state and triggers the corresponding events or actions.
     *
     * This method sets the internal busy flag (`FBusy`) to `true` to indicate that the device is currently busy.
     * If a callback is assigned to the `OnBusy` event handler, it will be invoked with the current device instance.
     * Additionally, it notifies all registered observers by calling their `NotifyBusy` method.
     *
     * The observers are stored in the `NotifyArr` array, and each observer is notified sequentially.
     * The number of observers is determined by the `NotifyCount` property.
     */
    virtual void NotifyBusy();

    /**
     * Marks the device as online by performing the following actions:
     * 1. Acquires a lock on the property section to ensure thread safety.
     * 2. Checks if the device is not currently marked as online.
     * 3. If the device is offline, triggers the relevant notifications:
     *    - Notifies about the device going online using `NotifyOnline`.
     *    - Notifies about a general state change using `NotifyStateChange`.
     * 4. Releases the lock on the property section upon completion.
     *
     * This method is invoked when the status of the device needs to transition
     * from offline to online. It ensures that the proper events are triggered
     * during this status change.
     */
    virtual void Online();

    /**
     * Sets the device to an offline state.
     *
     * This method ensures that the device will transition to an offline state if it is currently online.
     * The method secures access to the relevant properties using an internal locking mechanism
     * (via FPropertySection). If the device is online, it triggers the `NotifyOffline` method
     * to notify any registered listeners that the device has transitioned to offline, and also
     * invokes `NotifyStateChange` to update the state information. After completing the operations,
     * the lock on the property section is released.
     *
     * Thread safety is guaranteed through the use of the `FPropertySection` locking mechanism.
     */
    virtual void Offline();

    /**
     * Handles the transition of the device to an idle state.
     *
     * This method ensures thread-safe access to device properties by locking
     * the internal property section. If the device is identified as "busy"
     * during this operation, it performs the following:
     * - Invokes the NotifyIdle method for notifying the idle state.
     * - Triggers NotifyStateChange to signal a state change for the device.
     *
     * Thread safety is implemented using the FPropertySection lock mechanism.
     */
    void Idle();

    /**
     * Marks the device as busy and triggers associated notifications.
     *
     * This method ensures thread-safety by entering and leaving the
     * property section. If the device is not already busy, it notifies
     * the system that the device is busy and triggers a state change
     * notification.
     *
     * The following steps are performed in this method:
     * - Acquires thread-safe access using the FPropertySection.
     * - Checks if the device is not already marked as busy.
     * - If the device is not busy:
     *   - Calls NotifyBusy() to handle specific busy state notifications.
     *   - Calls NotifyStateChange() to update any observers of the state change.
     * - Releases thread-safe access by leaving the FPropertySection.
     */
    void Busy();

    /**
     * @brief Clears the reset state of the device.
     *
     * This method sets the internal reset flag (`FReset`) to `false`, indicating
     * that the device is no longer in a reset state.
     */
    void ClearReset();

    /**
     * @brief Represents the open state of a device in the TDevice class.
     *
     * This variable indicates whether the device is currently open
     * or not. It is managed internally by the TDevice class and is
     * updated through methods such as Open(), Close(), NotifyOpen(),
     * and NotifyClose().
     *
     * - `true`: The device is open.
     * - `false`: The device is closed.
     *
     * Changes to this variable trigger notifications and callbacks
     * such as OnOpen and OnClose, allowing external components to
     * respond to the open/close state transitions.
     */
    bool FOpen;
    /**
     * @brief Indicates whether the device is currently enabled or not.
     *
     * This boolean variable maintains the internal state of the device's
     * enabled status. It is set to `true` when the device is enabled
     * through the `Enable()` method and changes to `false` when the
     * `Disable()` method is called. The value of `FEnabled` is used
     * internally to manage and track the operational state of the
     * device's enabled functionality.
     *
     * Modifications to this variable are typically performed within
     * the `NotifyEnable()` and `NotifyDisable()` methods, which ensure
     * that related notifications are triggered whenever the enabled
     * state changes. Access to this variable is synchronized using
     * `FPropertySection` to prevent data races in multi-threaded
     * environments.
     */
    bool FEnabled;
    /**
     * @brief Indicates the online status of the device.
     *
     * This variable reflects whether the device is currently online or offline.
     * It is set to `true` when the device transitions to an online state via
     * `TDevice::NotifyOnline()` and set to `false` when transitioning to an offline state
     * via `TDevice::NotifyOffline()`. The online status can also be checked or updated
     * within the `TDevice::Online()` and `TDevice::Offline()` methods.
     *
     * Changes to this variable may trigger callbacks, such as `OnOnline` or `OnOffline`,
     * to notify interested observers about the state transition.
     */
    bool FOnline;
    /**
     * Indicates whether the device is currently busy performing a task.
     *
     * This variable is set to `true` to signal that the device is actively engaged
     * in an operation, and set to `false` when the device becomes idle.
     *
     * The value of `FBusy` is managed internally by the class and is updated during
     * specific transitions, such as when the device enters or exits a busy state.
     *
     * - `true`: The device is busy.
     * - `false`: The device is idle.
     *
     * It is updated in conjunction with methods such as `NotifyBusy` and `NotifyIdle`,
     * and it is also used for thread-safe state checks in critical sections where
     * `FPropertySection` is accessed.
     */
    bool FBusy;
    /**
     * @brief Indicates whether the device is in a reset state.
     *
     * The `FReset` variable is a boolean flag used to track the reset state of the device.
     * When `true`, it means the device has been reset via the `NotifyReset()` method.
     * Otherwise, it remains `false`. This flag can be cleared by invoking the `ClearReset()` method.
     *
     * This member is primarily managed internally by the `TDevice` class, with its value
     * being set during a reset operation and cleared explicitly when required.
     */
    bool FReset;
    /**
     * @brief Synchronization mechanism for thread-safe operations in the TDevice class.
     *
     * The `FPropertySection` variable is an instance of the `TSection` class, which provides
     * mechanisms to manage critical sections in a multithreaded environment. It is used to
     * ensure that operations related to the properties of a device, such as adding or removing
     * notifications, are performed in a thread-safe manner. By locking and unlocking this
     * section, concurrent threads are prevented from simultaneously modifying shared resources.
     *
     * The `FPropertySection` is initialized in the constructor of the `TDevice` class with
     * an identifier ("Device.Property") to facilitate debugging and identification of the
     * synchronization context.
     *
     * @see TSection
     */
    TSection FPropertySection;

    /**
     * @brief Pointer to the TDeviceDebug instance associated with the device.
     *
     * This variable is used to manage debugging functionality for the device. It is
     * set using the Install method of the TDevice class and allows the device to
     * interact with a TDeviceDebug object for debugging purposes.
     *
     * TDeviceDebug provides mechanisms to log or monitor the device's state and operations.
     * The variable may be null if debugging is not enabled for the device.
     *
     * Operations such as StartDeviceDebug and StopDeviceDebug utilize this variable
     * to manage device-specific debug resources or actions. Under specific operating
     * systems (e.g., __RDOS__), it may also interact with additional debug file handling logic.
     */
    TDeviceDebug *FDebug;
    /**
     * @brief The name of the device.
     *
     * Represents the identifier or label used to name the device. This variable
     * can be used to ensure proper identification and management of the device
     * across various operations within the system.
     */
    TString FDeviceName;

    /**
     * @brief Pointer to a file object used for debugging purposes.
     *
     * This variable is intended to hold a reference to a file that is used to log
     * or store debugging information during the runtime of the application.
     * It provides a mechanism to trace internal states or operations for diagnostic
     * and troubleshooting purposes.
     *
     * The file referenced by this pointer may need to be explicitly opened and
     * managed by the application. Proper handling, such as ensuring the file is
     * closed after use, is recommended to prevent resource leaks.
     */
    TFile *FDebugFile;

    /**
     * @brief Tracks the number of registered notify handlers for a device.
     *
     * NotifyCount represents the count of notification handlers currently
     * registered in the device instance. It is updated when notification
     * handlers are added or removed using AddNotify() or RemoveNotify() methods.
     *
     * The value of NotifyCount is initialized to 0 during the construction of the
     * device object. It increases as handlers are added, ensuring that the total
     * count reflects the current state of registered handlers. If handlers are
     * removed, the count is adjusted accordingly.
     *
     * This variable is used internally within the device class to manage and
     * synchronize handler operations, contributing to the overall functionality
     * of the notification system.
     */
    int NotifyCount;
    /**
     * @brief Array to store device notification objects.
     *
     * This array holds pointers to `TDeviceNotify` instances, which are used to manage
     * notifications for the device. The size of the array is determined by the constant
     * `MAX_DEVICE_NOTIFY_COUNT`, which defines the maximum number of notifications that
     * can be registered with a device. Each element of the array initially points to
     * `nullptr` and is updated when notifications are added or removed.
     *
     * @note The management of this array, including adding and removing notifications,
     *       is handled by the `AddNotify` and `RemoveNotify` methods of the `TDevice` class.
     */
    TDeviceNotify *NotifyArr[MAX_DEVICE_NOTIFY_COUNT];

private:
    /**
     * @brief Initializes the device to its default state.
     *
     * This method resets all internal state variables and configuration settings of the device
     * to their default values. It prepares the device for operation by ensuring all flags,
     * callbacks, and notification arrays are set appropriately.
     *
     * The initialization process includes:
     * - Resetting all boolean flags (`FReset`, `FOpen`, `FEnabled`, etc.) to false.
     * - Setting all callback function pointers (e.g., `OnOnline`, `OnOffline`, etc.) to null.
     * - Clearing the notification array (`NotifyArr`) by setting all elements to null.
     * - Resetting the notification count (`NotifyCount`) to zero.
     * - Invoking the `InsertDevice()` method to register the device in the device tracking system.
     *
     * This method is typically called during the creation or reset of a device instance
     * and is required for the proper functioning of other methods that depend on the
     * initialized state of the device.
     */
    void Init();

    /**
     * Inserts the current device instance into the global list of devices.
     *
     * This method ensures thread-safe insertion by utilizing the FListSection
     * locking mechanism. The current instance of TDevice is added to the
     * beginning of the static device list (FDeviceList).
     *
     * Thread-safety:
     * FListSection.Enter() is called at the beginning of the method to
     * lock the section, preventing simultaneous modifications to the
     * device list. The lock is released with FListSection.Leave()
     * after the device is successfully inserted.
     *
     * Behavior:
     * - The current TDevice instance (represented by `this`) is set as the
     *   new head of the global linked device list.
     * - The previous head of the list is preserved in the current instance's
     *   FList attribute.
     */
    void InsertDevice();

    /**
     * Removes the current device instance from the global device list.
     *
     * This method ensures thread-safety by utilizing a critical section lock
     * before performing modifications to the global device list.
     * The list is traversed to locate the current device instance (`this`)
     * and removes it from the linked list structure.
     *
     * If the device being removed is the head of the list, the head pointer
     * (`FDeviceList`) is updated to point to the next device in the list.
     * Otherwise, the previous device's link pointer is updated to skip
     * the current device.
     *
     * This function is also invoked in the destructor of the `TDevice` class
     * to ensure that a device gets cleanly removed from the list.
     *
     * Thread Safety:
     * - The method utilizes `FListSection.Enter()` and `FListSection.Leave()`
     *   to provide synchronization, ensuring that only one thread can modify
     *   the device list at any given time.
     */
    void RemoveDevice();

    /**
     * @brief Notifies that the device is now online and triggers related events.
     *
     * This method sets the internal online state of the device to true and
     * invokes the `OnOnline` callback if it is defined. It also notifies
     * all registered objects in the notification array by calling their
     * respective `NotifyOnline()` methods.
     *
     * The method is typically used to handle the transition of the device
     * to an online state and ensure that all registered observers are updated
     * accordingly.
     *
     * Note: Ensure that the `NotifyArr` array and `NotifyCount` are properly
     * managed to avoid invalid or null pointers in the notification process.
     */
    void NotifyOnline();

    /**
     * @brief Notifies that the device has transitioned to an offline state.
     *
     * This method sets the internal state of the device to offline (FOnline = false)
     * and notifies any registered handlers or observers of this state transition.
     *
     * The following operations are performed:
     * - Sets the device's internal online status to false.
     * - If a callback for the `OnOffline` event is specified, it invokes that callback.
     * - Iterates through the registered notification array and invokes the NotifyOffline
     *   method for each non-null notification.
     *
     * This method is invoked internally when the device's state transitions to offline
     * as part of its operation lifecycle.
     */
    void NotifyOffline();

    /**
     * @brief Represents a synchronization section used to manage access to shared resources
     *        among instances of the TDevice class.
     *
     * The FListSection is an instance of the TSection class and is specifically initialized
     * with the name "Device.List". It is utilized to coordinate concurrent access to the
     * internal static list of devices (FDeviceList), ensuring thread-safe operations when
     * devices are added, removed, or accessed.
     *
     * The synchronization methods Enter() and Leave() are used to lock and unlock the critical
     * section, protecting shared resources across multiple threads.
     *
     * @note This is a private static member of the TDevice class.
     */
    static TSection FListSection;
    /**
     * @brief A static pointer to the head of the global linked list of TDevice instances.
     *
     * FDeviceList serves as the linked list's entry point, maintaining a global registry
     * of all TDevice objects. Each TDevice instance inserts itself into this list upon
     * creation and removes itself upon destruction or as needed. This is managed by
     * the InsertDevice and RemoveDevice methods.
     *
     * Thread safety for list modifications is ensured through the use of a static TSection
     * object, FListSection.
     *
     * @note Access to this list may require synchronization due to its shared nature
     *       across multiple threads.
     */
    static TDevice *FDeviceList;
    /**
     * @brief Linked list pointer for managing TDevice instances.
     *
     * This variable serves as a pointer to the next device in a linked list of
     * TDevice objects. It is used internally to maintain and manage the ordered
     * list of devices. The list is manipulated through methods like InsertDevice
     * and RemoveDevice, ensuring thread-safe operations via the associated
     * synchronization mechanism (FListSection).
     *
     * @note This variable is private to the class and not intended for direct
     *       external access. Its state and usage are controlled internally.
     */
    TDevice *FList;
};

#endif

