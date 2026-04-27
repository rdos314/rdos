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
# device.cpp
# Basic device class
#
#######################################################################*/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "device.h"
#include "sigdev.h"

#ifdef __RDOS__
#include "rdos.h"
#endif

/**
 * @brief Static section object used for synchronizing access to the device list.
 *
 * `FListSection` is an instance of the `TSection` class specifically designed
 * to control access to shared resources related to the list of device instances
 * (`FDeviceList`). It is initialized with the name `"Device.List"` to identify
 * the section and facilitate debugging or logging in multi-threaded environments.
 *
 * This section object ensures thread-safe operations on the linked list
 * of devices, such as adding or removing devices, by using synchronization methods
 * (`Enter` and `Leave`) provided by the `TSection` class. These methods lock and
 * unlock the section, preventing simultaneous access and ensuring data consistency.
 *
 * It is used internally in methods like `InsertDevice`, `RemoveDevice`, and `GetDevices`
 * to manage and traverse the device list safely in a concurrent setting.
 */
TSection TDevice::FListSection("Device.List");
/**
 * @brief A static pointer to the head of the linked list of device instances.
 *
 * This static member stores the starting point of a linked list that maintains
 * all active instances of the `TDevice` class. Each `TDevice` object can use this
 * list to register itself or to be removed when necessary.
 *
 * The list is manipulated within the methods `InsertDevice` and `RemoveDevice`.
 * These methods ensure that device instances are added or removed from the list
 * in a thread-safe manner by using the `FListSection` critical section for concurrency control.
 *
 * The primary use of this list is to manage the lifecycle and access to all
 * created `TDevice` objects, which can aid in operations that require iterating
 * over all devices, such as shutdown handling or broadcasting notifications.
 *
 * @note Modifications to the `FDeviceList` pointer must be protected by the
 * `FListSection` critical section to ensure thread safety.
 */
TDevice *TDevice::FDeviceList = 0;

/**
 * @brief Constructs a new instance of the TDeviceDebug class.
 *
 * This default constructor initializes an object of the `TDeviceDebug` class,
 * allowing it to perform debugging operations specific to devices. As a derived
 * class of `TThread`, this object can execute tasks in a multi-threaded environment
 * while managing resources and handling device-specific debugging activities.
 *
 * The constructor does not perform any explicit operations but sets up the
 * foundation for the class's intended functionality.
 *
 * @return A newly created `TDeviceDebug` object.
 */
TDeviceDebug::TDeviceDebug()
{
}

/**
 * @brief Destructor for the `TDeviceDebug` class.
 *
 * Cleans up resources associated with a `TDeviceDebug` object.
 *
 * The `TDeviceDebug` class is a specialized thread class providing debugging
 * capabilities for device-related operations. The destructor ensures that
 * any resources or internal states utilized by the `TDeviceDebug` instance
 * are appropriately released when the object goes out of scope or is
 * explicitly deleted.
 *
 * This method is automatically invoked as part of the object lifecycle
 * management and does not require additional implementation in this context.
 */
TDeviceDebug::~TDeviceDebug()
{
}

/**
 * @brief Requests a file associated with a specific device for debugging purposes.
 *
 * This method attempts to retrieve a file object (`TFile`) that corresponds to
 * a given device object (`TDevice`). It is intended to be used in scenarios
 * where debugging requires file-level interaction with the specified device.
 *
 * Currently, the method returns a null pointer, indicating that no valid file
 * is associated with the device in its current implementation.
 *
 * @param Device A pointer to the `TDevice` object for which the corresponding
 *               file is being requested. The device represents the target
 *               resource to be linked with the file object.
 * @return A pointer to the `TFile` object associated with the provided `TDevice`.
 *         Returns null if no file is available for the specified device.
 */
TFile *TDeviceDebug::RequestFile(TDevice *Device)
{
    return 0;
}

/**
 * @brief Releases the file associated with the specified device.
 *
 * This method is responsible for handling the cleanup or disassociation
 * of any file that is currently linked to the provided device instance.
 * It ensures that any resources tied to the file are properly released,
 * preventing resource leaks and maintaining system stability.
 *
 * This operation is typically used when a device is no longer active or
 * needs to be reinitialized, and any associated file handles or data
 * streams need to be cleaned up as part of the process.
 *
 * @param Device A pointer to the `TDevice` instance whose associated file
 *               needs to be released.
 */
void TDeviceDebug::ReleaseFile(TDevice *Device)
{
}

/**
 * @brief Retrieves the maximum allowed file size for the device debug process.
 *
 * This method specifies the maximum file size value permitted for file operations
 * conducted during debugging within the `TDeviceDebug` class. The returned value
 * is configured based on internal constraints or default settings.
 *
 * Override or customize this method if specific subclasses require different
 * maximum file size limits.
 *
 * @return The maximum file size allowed for debugging, as an integer value in bytes.
 */
int TDeviceDebug::MaxFileSize()
{
    return 0;
}

/**
 * @brief Constructs a TDeviceNotify instance.
 *
 * This is the default constructor for the TDeviceNotify class, responsible
 * for initializing an instance of the class. It does not perform any specific
 * actions upon initialization.
 *
 * @return A new instance of TDeviceNotify.
 */
TDeviceNotify::TDeviceNotify()
{
}

/**
 * @brief Destructor for the TDeviceNotify class.
 *
 * Cleans up resources associated with the TDeviceNotify object.
 * This destructor is virtual to ensure proper cleanup in derived classes.
 */
TDeviceNotify::~TDeviceNotify()
{
}

/**
 * @brief Determines whether the current object is considered a base.
 *
 * This method is a virtual function intended to be overridden in derived classes.
 * The default implementation always returns true.
 *
 * @return A boolean value indicating whether the current object is a base (true by default).
 */
bool TDeviceNotify::IsBase()
{
    return true;
}

/**
 * Notifies that the specified device is now online.
 *
 * This method sets the device's internal state to online and triggers any
 * associated callbacks or notification mechanisms for registered observers.
 *
 * @param Device A pointer to the TDevice instance that has come online.
 */
void TDeviceNotify::NotifyOnline(TDevice *Device)
{
}

/**
 * Notifies that a device has gone offline.
 * This method is called when a device transitions to an offline state.
 * It also propagates the notification to other registered notification handlers.
 *
 * @param Device A pointer to the TDevice instance that has gone offline.
 */
void TDeviceNotify::NotifyOffline(TDevice *Device)
{
}

/**
 * @brief Notifies the observing object of the associated device's idle state.
 *
 * This virtual method is called when the device enters an idle state. It provides
 * an opportunity for observing objects to respond to the state change. Classes
 * inheriting from TDeviceNotify can override this method to implement custom
 * behaviors upon receiving the idle notification.
 *
 * @param Device A pointer to the TDevice object that has entered the idle state.
 */
void TDeviceNotify::NotifyIdle(TDevice *Device)
{
}

/**
 * @brief Notifies that the associated device has entered a "busy" state.
 *
 * This method is intended to be triggered when the state of a device changes
 * to "busy". It leverages the notification framework to propagate the "busy"
 * state to associated or dependent entities. The actual implementation in
 * the derived or extended methods of this function should ensure proper state
 * management and broadcasting of the "busy" status to other components that
 * registered for notifications.
 *
 * @param Device A pointer to the TDevice instance that is now in the "busy" state.
 */
void TDeviceNotify::NotifyBusy(TDevice *Device)
{
}

/**
 * @brief Notifies that a device has been opened.
 *
 * This function is called when a device is successfully opened. It serves
 * as a notification mechanism that can trigger associated callbacks or
 * actions. If the device's `OnOpen` callback is set, it will invoke the
 * callback. Additionally, this function propagates the notification to
 * any registered observers in the `NotifyArr` array.
 *
 * @param Device A pointer to the device object that has been opened.
 */
void TDeviceNotify::NotifyOpen(TDevice *Device)
{
}

/**
 * @brief Notifies the implementation of TDeviceNotify that a device has been closed.
 *
 * This function is a callback that is invoked when a device is closed.
 * It allows for custom behaviors to be executed as part of the device
 * close notification process. This method is typically overridden
 * in derived classes to handle device close events for specific purposes.
 *
 * @param Device A pointer to the TDevice that is being closed.
 *               This provides context about which device triggered the notification.
 */
void TDeviceNotify::NotifyClose(TDevice *Device)
{
}

/**
 * @brief Notifies the enablement of a specific device.
 *
 * This method is called when a device is enabled, allowing
 * any associated notify objects to be informed of the enable event.
 * It is part of the device notification mechanism in the TDeviceNotify class.
 *
 * @param Device Pointer to the TDevice instance that has been enabled.
 */
void TDeviceNotify::NotifyEnable(TDevice *Device)
{
}

/**
 * @brief Handles the notification when a given device is disabled.
 *
 * This method is called to notify the corresponding observers that the specified
 * device has been disabled. It allows any registered object to act or respond accordingly
 * when the device transitions into a disabled state.
 *
 * @param Device A pointer to the TDevice instance that is being disabled.
 */
void TDeviceNotify::NotifyDisable(TDevice *Device)
{
}

/**
 * Notifies the observer that the specified device has been reset.
 *
 * This method is called when a reset action occurs on a device. It provides
 * a mechanism for observers to react to the reset event and perform any
 * necessary actions or updates.
 *
 * @param Device A pointer to the TDevice instance that has been reset.
 */
void TDeviceNotify::NotifyReset(TDevice *Device)
{
}

/**
 * @brief Notifies registered observers about a change in the device state.
 *
 * This function is invoked to propagate state change notifications to all
 * the observers that are registered with the device. It triggers callbacks
 * for state change events and ensures that all relevant notifications are
 * delivered to the associated observers.
 *
 * @param Device Pointer to the device whose state has changed.
 */
void TDeviceNotify::NotifyStateChange(TDevice *Device)
{
}

/**
 * @brief Inserts the current device into the global device list.
 *
 * This method ensures thread-safe insertion of a device into the
 * static device list, `FDeviceList`, using `FListSection` for
 * synchronization. It adds the current device object (`this`)
 * to the front of the list and updates the `FDeviceList` pointer.
 *
 * The method performs the following steps:
 * 1. Acquires the synchronization lock on `FListSection` by calling `Enter`.
 * 2. Saves the current `FDeviceList` pointer into the instance's `FList` for
 *    potential future reference.
 * 3. Updates the static `FDeviceList` to point to the current device object.
 * 4. Releases the synchronization lock on `FListSection` by calling `Leave`.
 */
void TDevice::InsertDevice()
{
    FListSection.Enter();
    FList = FDeviceList;
    FDeviceList = this;
    FListSection.Leave();
}

/**
 * @brief Removes the current device instance from the global device list.
 *
 * This method removes the current device instance (`this`) from a linked list
 * of devices. The global device list (`FDeviceList`) acts as the head of the
 * list. The method ensures thread safety by entering a critical section via
 * `FListSection` before making modifications to the list, and leaves the
 * section after the operation is complete.
 *
 * The removal process involves iterating through the list to locate the
 * current device (`this`). If the device is found, it is removed from the list
 * by adjusting the relevant pointers:
 * - If the current device is the head of the list (i.e., `prev` is null),
 *   `FDeviceList` is updated to point to the next device.
 * - Otherwise, the previous device's pointer (`prev->FList`) is updated to
 *   skip over the current device.
 *
 * Thread safety is preserved by ensuring that the `Enter` method of
 * `FListSection` is called before accessing or modifying the list, and the
 * `Leave` method of `FListSection` is invoked upon completion.
 *
 * Note: This method is typically invoked during the destruction of a
 * `TDevice` instance to clean up its presence from the global device list.
 */
void TDevice::RemoveDevice()
{
    TDevice *ptr;
    TDevice *prev;

    prev = 0;
    FListSection.Enter();
    ptr = FDeviceList;

    while ((ptr != 0) && (ptr != this))
    {
        prev = ptr;
        ptr = ptr->FList;
    }

    if (prev == 0)
        FDeviceList = FDeviceList->FList;
    else
        prev->FList = ptr->FList;

    FListSection.Leave();
}

/**
 * Retrieves all devices in the device list and invokes the provided callback function for each device.
 *
 * The method traverses the list of devices, calling the provided callback function for each device found.
 * Thread-safe access to the device list is ensured using the FListSection.
 *
 * @param DeviceCallb A function pointer to the callback function that will be executed for each device.
 *                    This function should accept a single parameter of type TDevice* representing the device.
 */
void TDevice::GetDevices(void (*DeviceCallb)(TDevice *Device))
{
    TDevice *ptr;

    FListSection.Enter();
    ptr = FDeviceList;
    while (ptr != 0)
    {
        (*DeviceCallb)(ptr);
        ptr = ptr->FList;
    }
    FListSection.Leave();
}

/**
 * @brief Constructs a TDevice object and initializes its state.
 *
 * This constructor initializes the TDevice instance by setting up its
 * property section and the device name. It also calls the Init() method
 * to perform any additional initialization operations.
 *
 * @param DeviceName A C-string representing the name of the device.
 * @return None
 */
TDevice::TDevice(const char *DeviceName)
  : FPropertySection("Device.Property"),
    FDeviceName(DeviceName)
{
    Init();
}

/**
 * @brief Destructor for the TDevice class, responsible for device cleanup.
 *
 * The `~TDevice` destructor is invoked automatically when an instance of
 * the `TDevice` class is destroyed. Its primary responsibility is to ensure
 * that the device is safely removed from the device list by internally
 * calling the `RemoveDevice` method.
 *
 * This cleanup step helps maintain the integrity of the global device list
 * (`FDeviceList`) by removing references to the destroyed device, preventing
 * potential issues such as dangling pointers or resource conflicts in
 * multi-threaded or resource-sensitive environments.
 *
 * For derived classes, it is recommended to follow standard destructor
 * chaining practices to ensure proper resource cleanup beyond the scope
 * of the `TDevice` class.
 */
TDevice::~TDevice()
{
    RemoveDevice();
}

/**
 * @brief Initializes the device object to its default state.
 *
 * This method resets all internal properties of the device instance to their
 * default values. It sets the debug and state flags to inactive, clears callbacks,
 * and initializes the notification system. The method also ensures the device
 * is prepared for integration by registering it with the device management system.
 *
 * The following tasks are performed during initialization:
 * - Debugging-related properties (`FDebug` and `FDebugFile`) are disabled.
 * - Device state flags (`FReset`, `FOpen`, `FEnabled`, `FOnline`, `FBusy`) are set
 *   to their default states (primarily false).
 * - Event callback pointers (e.g., `OnOnline`, `OnOffline`, `OnStateChange`) are cleared.
 * - Notification counters and arrays are reset.
 * - The device instance is registered by calling `InsertDevice`.
 *
 * This method is generally called during the creation or reinitialization of the
 * `TDevice` instance to ensure it operates in a known and stable state.
 */
void TDevice::Init()
{
    int i;

    FDebug = 0;
    FDebugFile = 0;

    FReset = false;
    FOpen = false;
    FEnabled = false;
    FOnline = false;
    FBusy = false;
    OnOnline = 0;
    OnOffline = 0;
    OnIdle = 0;
    OnBusy = 0;
    OnOpen = 0;
    OnClose = 0;
    OnStateChange = 0;

    NotifyCount = 0;

    for (i = 0; i < MAX_DEVICE_NOTIFY_COUNT; i++)
        NotifyArr[i] = 0;

    InsertDevice();
}

/**
 * Adds a notify object to the device's notification list.
 * The method attempts to add the given TDeviceNotify object to the
 * first available slot in the internal notification array. If the notification
 * array is full, the notify object will not be added.
 *
 * @param Notify Pointer to a TDeviceNotify object to be added to the device's notification list.
 */
void TDevice::AddNotify(TDeviceNotify *Notify)
{
    int i;

    FPropertySection.Enter();

    for (i = 0; i < MAX_DEVICE_NOTIFY_COUNT; i++)
    {
        if (NotifyArr[i] == 0)
        {
            NotifyArr[i] = Notify;
            if (i >= NotifyCount)
                NotifyCount = i + 1;

            break;
        }
    }

    FPropertySection.Leave();
}

/**
 * Removes a notification object from the device's notification list.
 *
 * This method identifies the specified notification object in the device's
 * internal notification array and removes it by setting its slot to null. The
 * method then adjusts the count of active notifications to exclude any trailing
 * null slots from the array. Access to the notification list is synchronized
 * to ensure thread safety.
 *
 * @param Notify Pointer to the notification object to be removed. If the object
 *        is not found in the notification list, no changes will be made.
 */
void TDevice::RemoveNotify(TDeviceNotify *Notify)
{
    int i;

    FPropertySection.Enter();

    for (i = 0; i < NotifyCount; i++)
    {
        if (NotifyArr[i] == Notify)
        {
            NotifyArr[i] = 0;
            break;
        }
    }

    while (NotifyCount)
    {
        if (NotifyArr[NotifyCount - 1])
            break;
        else
            NotifyCount--;
    }

    FPropertySection.Leave();
}

/**
 * @brief Notifies the relevant listeners about a state change in the device.
 *
 * This method is responsible for triggering the `OnStateChange` callback
 * if it has been set, and iterating over all registered notifications to
 * propagate the state change event.
 *
 * - If the `OnStateChange` function pointer is not null, it will be
 *   invoked with a reference to the current device instance (`this`).
 * - Subsequently, all elements in the `NotifyArr` array are checked, and
 *   if not null, their `NotifyStateChange` method is called with the
 *   current device instance as the argument.
 *
 * This mechanism ensures that state changes in the device are properly
 * communicated to all registered listeners and handlers.
 *
 * @note This method is typically invoked internally by other operations
 *       such as Open, Close, Enable, Disable, or when transitioning
 *       the device's operational state.
 */
void TDevice::NotifyStateChange()
{
    int i;

    if (OnStateChange)
        (*OnStateChange)(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyStateChange(this);
}

/**
 * @brief Notifies all registered observers of the reset event for the device.
 *
 * This method sets the internal reset flag (`FReset`) to true and iterates
 * through the list of registered notification handlers (`NotifyArr`). For each
 * non-null handler, it invokes the `NotifyReset()` function, passing the current
 * device instance as a parameter.
 *
 * The method is used to inform all observers that the device has been reset
 * and allows external components to react accordingly.
 *
 * @note Each entry in the `NotifyArr` array is checked for null values before
 * invoking the `NotifyReset()` function.
 */
void TDevice::NotifyReset()
{
    int i;

    FReset = true;

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyReset(this);
}

/**
 * @brief Checks whether the device has been reset.
 *
 * This method returns the current reset state of the device.
 *
 * @return true if the device is reset, otherwise false.
 */
bool TDevice::IsReseted() const
{
    return FReset;
}

/**
 * @brief Resets the internal reset flag of the device.
 *
 * Clears the internal reset status (`FReset`) for the device by setting it to false.
 * This function is typically used to indicate that the reset state has been cleared
 * and the device can resume normal operations.
 */
void TDevice::ClearReset()
{
    FReset = false;
}

/**
 * Retrieves the name of the device as a string.
 *
 * @return A pointer to a constant character array representing the name of the device.
 */
const char *TDevice::DeviceName() const
{
    return FDeviceName.GetData();
}

/**
 * @brief Notifies that the device has been opened.
 *
 * This method handles the notification process when the device is opened. It performs the following actions:
 * - Sets the `FOpen` flag to `true`, indicating the device is open.
 * - If the `OnOpen` callback is set, it invokes this callback with the current device instance as its parameter.
 * - Iterates through the registered notification list (`NotifyArr`) and invokes the `NotifyOpen` method of each valid
 *   notifier with the current device instance as its parameter.
 *
 * This method is intended to be used within the device management lifecycle, particularly during the transition
 * of the device to an open state.
 */
void TDevice::NotifyOpen()
{
    int i;

    FOpen = true;

    if (OnOpen)
        (*OnOpen)(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyOpen(this);
}

/**
 * @brief Opens the device and triggers associated state change notifications.
 *
 * This method attempts to open the device if it is not already open.
 * It ensures thread safety by protecting the operation with a critical section
 * using the `FPropertySection` member. If the device is successfully opened,
 * it invokes the `NotifyOpen` and `NotifyStateChange` methods to notify the
 * relevant subscribers or handlers of the state change.
 *
 * @note The method is a no-op if the device is already open.
 */
void TDevice::Open()
{
    FPropertySection.Enter();

    if (!FOpen)
    {
        NotifyOpen();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/**
 * @brief Notifies all registered observers and performs cleanup when the device is being closed.
 *
 * This method performs the following:
 * - Sets the internal state of the device to closed by setting the `FOpen` flag to `false`.
 * - If the `OnClose` callback is assigned, it invokes the callback with the current device instance.
 * - Iterates through the list of registered notifications (`NotifyArr`) and calls the `NotifyClose`
 *   method of each non-null notification object, passing the current device as a parameter.
 *
 * This function is typically called as part of the device shutdown or cleanup process.
 */
void TDevice::NotifyClose()
{
    int i;

    FOpen = false;

    if (OnClose)
        (*OnClose)(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyClose(this);
}

/**
 * @brief Closes the device and updates its state if it is currently open.
 *
 * This method performs the following sequence of actions:
 * 1. Enters a critical section controlled by `FPropertySection`.
 * 2. Checks if the device is currently open (`FOpen` is true).
 * 3. If open, it invokes `NotifyClose` to handle device-specific close logic.
 * 4. Triggers a state change notification by calling `NotifyStateChange`.
 * 5. Leaves the critical section controlled by `FPropertySection`.
 *
 * This method ensures thread safety when performing the close operation by
 * utilizing the critical section, and it updates the device's state appropriately
 * when closed.
 */
void TDevice::Close()
{
    FPropertySection.Enter();
    if (FOpen)
    {
        NotifyClose();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/**
 * @brief Determines whether the device is currently open.
 *
 * This method checks the internal state of the device to verify if it is in an open state.
 *
 * @return true if the device is open, false otherwise.
 */
bool TDevice::IsOpen()
{
    return FOpen;
}

/**
 * @brief Notifies all registered notification objects about the enabling of the device.
 *
 * This method marks the device as enabled and iterates over the array of registered
 * notification objects (`NotifyArr`). For each non-null notification object, it invokes
 * the `NotifyEnable` method on the corresponding object, passing the current device
 * instance as a parameter.
 *
 * The method is intended to update all observers or listeners about the state change
 * of the device becoming enabled. It ensures that interested parties are aware
 * of changes to the device's operational state.
 *
 * @note This method is called internally, typically when a device is enabled via
 * another method, such as `Enable`.
 *
 * @see TDeviceNotify::NotifyEnable
 */
void TDevice::NotifyEnable()
{
    int i;

    FEnabled = true;

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyEnable(this);
}

/**
 * @brief Enables the device, if it is not already enabled.
 *
 * This method activates the device by setting its enabled state. It ensures
 * thread-safe access to the device properties by acquiring and releasing a
 * critical section. If the device is currently disabled, it performs the
 * necessary operations to notify that the device is now enabled and its
 * state has changed.
 *
 * @note This method internally calls NotifyEnable() and NotifyStateChange()
 * when the device is transitioned to the enabled state.
 */
void TDevice::Enable()
{
    FPropertySection.Enter();
    if (!FEnabled)
    {
        NotifyEnable();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/**
 * @brief Disables the device and notifies all registered observers.
 *
 * This method sets the device's internal enabled state to false
 * and iterates through the list of registered notification objects.
 * For each non-null notification object, it invokes the
 * `NotifyDisable` method, passing this device as a parameter.
 *
 * The notifications allow associated observers or components
 * to respond to the device's disabled state.
 */
void TDevice::NotifyDisable()
{
    int i;

    FEnabled = false;

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyDisable(this);
}

/**
 * @brief Disables the device and updates its state.
 *
 * This method disables the device if it is currently enabled. It executes
 * the `NotifyDisable` and `NotifyStateChange` methods to notify relevant
 * components and update the device state. Access to the device's properties
 * is thread-safe, as the operation is protected by `FPropertySection`.
 *
 * @note This method has no effect if the device is already disabled.
 */
void TDevice::Disable()
{
    FPropertySection.Enter();
    if (FEnabled)
    {
        NotifyDisable();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/**
 * @brief Checks if the device is currently enabled.
 *
 * This method returns the current enabled state of the device.
 * A device is considered enabled if its internal enabled flag is set to true.
 *
 * @return True if the device is enabled, false otherwise.
 */
bool TDevice::IsEnabled()
{
    return FEnabled;
}

/**
 * @brief Notifies that the device is now online.
 *
 * Sets the device's internal state to online and triggers the online event
 * callback if defined. Additionally, iterates through all registered notify
 * objects and invokes their NotifyOnline method to propagate the state change.
 *
 * @note The method will execute a callback (OnOnline) if it is provided.
 *       It will also iterate through the notify list (NotifyArr) to ensure that
 *       all associated notification mechanisms are informed of the device's
 *       change in state to online. Each valid entry in NotifyArr will have its
 *       NotifyOnline method invoked with the current device instance as a parameter.
 */
void TDevice::NotifyOnline()
{
    int i;

    FOnline = true;

    if (OnOnline)
        OnOnline(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyOnline(this);
}

/**
 * @brief Sets the device's status to online and triggers relevant notifications.
 *
 * This method sets the internal state of the device to online if it is not already online.
 * It is thread-safe, protecting the operation with a property section. If the device state
 * changes to online, it triggers both the online notification and a state change notification.
 *
 * @note The method ensures mutual exclusion to safeguard against concurrent access
 *       to the relevant state or properties during the operation.
 */
void TDevice::Online()
{
    FPropertySection.Enter();
    if (!FOnline)
    {
        NotifyOnline();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/**
 * @brief Handles the transition of the device to an offline state.
 *
 * This method updates the device's internal state to reflect that it is now offline.
 * Additionally, it triggers the following notification events:
 *
 * - If the `OnOffline` callback is set, it is invoked with the current device as the parameter.
 * - For each element in the notification array (`NotifyArr`), if the element is not null,
 *   its `NotifyOffline` method is called, passing the current device as the parameter.
 *
 * This method ensures all relevant parties are informed of the device's offline status.
 *
 * @details The `FOnline` member variable is set to `false` to record the offline state.
 * The `NotifyArr` array and `OnOffline` callback provide flexibility to attach
 * custom behaviors when the device transitions to the offline state.
 *
 * @note This method relies on external components to have correctly configured the
 * notification array and callbacks to ensure proper functionality.
 */
void TDevice::NotifyOffline()
{
    int i;

    FOnline = false;

    if (OnOffline)
        OnOffline(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyOffline(this);
}

/**
 * @brief Sets the device to an offline state if it is currently online.
 *
 * This method ensures thread-safe handling of the device's offline state
 * by using synchronization through a property section. If the device is
 * currently online, it triggers the notifications for the offline state
 * and state changes.
 *
 * @details
 * - Acquires a lock on the `FPropertySection` to manage concurrent access.
 * - Checks whether the device is currently in an online state (`FOnline`).
 * - If the device is online:
 *     - Calls `NotifyOffline()` to handle offline-related notifications.
 *     - Calls `NotifyStateChange()` to handle state change notifications.
 * - Releases the lock on the `FPropertySection` after performing the operations.
 *
 * @note This method relies on `NotifyOffline()` and `NotifyStateChange()`
 *       being implemented to perform the respective notifications.
 */
void TDevice::Offline()
{
    FPropertySection.Enter();
    if (FOnline)
    {
        NotifyOffline();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/**
 * @brief Indicates whether the device is currently online.
 *
 * This method checks the state of the device and determines if it is online.
 *
 * @return true if the device is online, otherwise false.
 */
bool TDevice::IsOnline()
{
    return FOnline;
}

/**
 * @brief Determines whether the device is currently active.
 *
 * This method checks the internal flags to evaluate if the device
 * is both enabled and open. A device is considered active only if
 * both conditions are true.
 *
 * @return true if the device is enabled and open, otherwise false.
 */
bool TDevice::IsActive()
{
    return FEnabled && FOpen;
}

/**
 * @brief Notifies that the device is now idle.
 *
 * This method updates the internal state of the device to indicate that it
 * is no longer busy. It triggers the `OnIdle` callback, if assigned, and
 * notifies all registered observers in the `NotifyArr` array by invoking
 * their `NotifyIdle` method.
 *
 * @details
 * - Sets the device's busy state (`FBusy`) to false.
 * - If the `OnIdle` callback is set, it gets triggered with a pointer to the
 *   current device as the parameter.
 * - Iterates through the registered observers in `NotifyArr`, and for each
 *   non-null observer, calls their `NotifyIdle` method with the current device
 *   as the parameter.
 */
void TDevice::NotifyIdle()
{
    int i;

    FBusy = false;

    if (OnIdle)
        OnIdle(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyIdle(this);
}

/**
 * @brief Puts the device into an idle state if it is currently busy.
 *
 * This method checks if the device is busy and performs the necessary
 * steps to transition the device to an idle state. It notifies
 * subscribed components of the idle state and state change.
 *
 * The method ensures thread safety by using a synchronization mechanism
 * to enter and leave a critical section.
 *
 * @note This method is thread-safe.
 */
void TDevice::Idle()
{
    FPropertySection.Enter();
    if (FBusy)
    {
        NotifyIdle();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/**
 * @brief Notifies that the device is in a busy state.
 *
 * This method sets the device's internal busy state to true and triggers the
 * `OnBusy` callback if it is defined. Additionally, it propagates the "busy"
 * notification to all registered notifiers in the `NotifyArr` array.
 *
 * The method is designed to keep all interested parties informed about the
 * device's busy status.
 *
 * @note The `OnBusy` callback, if assigned, is invoked with the current
 *       device instance (`this`). Similarly, each notifier in the `NotifyArr`
 *       array will have its `NotifyBusy` method called with the current
 *       device instance as its parameter.
 */
void TDevice::NotifyBusy()
{
    int i;

    FBusy = true;

    if (OnBusy)
        OnBusy(this);

    for (i = 0; i < NotifyCount; i++)
        if (NotifyArr[i])
            NotifyArr[i]->NotifyBusy(this);
}

/**
 * @brief Marks the device as busy and sends corresponding notifications.
 *
 * When called, this method ensures thread-safe modification of the device's
 * busy state. If the device is not already marked as busy, it updates the
 * state and triggers both the `NotifyBusy` and `NotifyStateChange` methods
 * to propagate the changes.
 *
 * - Acquires the FPropertySection lock to ensure safe access to shared resources.
 * - Checks the `FBusy` flag to determine if the device is already in a busy state.
 * - If not busy, calls the `NotifyBusy` method to execute busy-specific logic.
 * - Notifies other components of the state change by calling `NotifyStateChange`.
 * - Releases the FPropertySection lock after completing the operations.
 */
void TDevice::Busy()
{
    FPropertySection.Enter();
    if (!FBusy)
    {
        NotifyBusy();
        NotifyStateChange();
    }
    FPropertySection.Leave();
}

/**
 * @brief Checks whether the device is currently busy performing an operation.
 *
 * This method returns the busy status of the device. A device is considered busy
 * when it is actively engaged in an operation and cannot process new requests
 * or tasks until its current operation is completed.
 *
 * @return true if the device is busy; false otherwise.
 */
bool TDevice::IsBusy()
{
    return FBusy;
}

/**
 * Installs a debug object for the device.
 *
 * This method sets the provided debug object to be used by the device for debugging purposes.
 *
 * @param Debug A pointer to a TDeviceDebug object that will handle debug operations for the device.
 */
void TDevice::Install(TDeviceDebug *Debug)
{
    FDebug = Debug;
}

/**
 * @brief Initiates debug mode for the device and sets up a debug file.
 *
 * The `StartDeviceDebug` method checks if the debug subsystem (`FDebug`) is available
 * for the current device. If available, it requests a debug file from the debug subsystem
 * and assigns it to the `FDebugFile` member. This debug file can then be used for logging
 * or diagnostic purposes specific to the device instance.
 *
 * This method is typically utilized during the setup or initialization phase
 * to enable detailed diagnostics for this device in a controlled environment.
 *
 * It assumes that the debug subsystem provides a mechanism for mapping a device instance
 * to a specific debug file through the `RequestFile` method.
 *
 * @note The method has no effect if `FDebug` is null.
 */
void TDevice::StartDeviceDebug()
{
    if (FDebug)
        FDebugFile = FDebug->RequestFile(this);
}

/**
 * @brief Terminates debugging operations for the device and releases associated resources.
 *
 * The `StopDeviceDebug` method is responsible for stopping any ongoing debugging
 * activities for the device. If the `FDebug` object is assigned, it releases the
 * debug file specifically associated with this device by invoking the `ReleaseFile`
 * method. Afterward, the debug file reference (`FDebugFile`) is set to `0`,
 * effectively clearing any active debug file association for the device.
 *
 * This method ensures proper cleanup of debugging resources to prevent resource
 * leaks or invalid operations related to debugging in subsequent device activities.
 */
void TDevice::StopDeviceDebug()
{
    if (FDebug)
        FDebug->ReleaseFile(this);

    FDebugFile = 0;
}
