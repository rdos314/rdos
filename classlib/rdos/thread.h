/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2026, Leif Ekblad
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
# thread.h
# Thread class
#
########################################################################*/

#ifndef _TTHREAD_H
#define _TTHREAD_H

#include "section.h"

#ifndef __RDOS__
#include <pthread.h>
#endif

void CreateThread(void (*Startup)(void *ptr), const char *ThreadName, void *ptr, int StackSize);

class TSignalDevice;

/**
 * @class TThread
 * @brief Represents a threading utility class for creating and managing threads.
 *
 * The TThread class encapsulates functionality for thread creation, execution,
 * and management. It provides an interface for starting, stopping, and checking
 * the status of a thread. It also supports thread-safe operations and allows for
 * platform-specific implementations where necessary.
 */
class TThread
{
 /**
  * @brief Constructs a TThread object and initializes its internal state.
  *
  * The constructor initializes the thread's stop section, sets the thread's
  * initial state to not running, and marks it as installed. It also initializes
  * various platform-dependent attributes used for thread management.
  *
  * @return None
  */
public:
    TThread();
    TThread(const char *ThreadName, int StackSize);
    TThread(const char *ThreadName, int StackSize, bool RunIt);
    virtual ~TThread();
    virtual void Run();
    virtual void Terminated();
    virtual void Stop();
    bool IsRunning() const;
    void *Owner;

protected:
 /**
  * @brief Checks whether the thread is in the process of stopping.
  *
  * This method determines if the thread is in a "stopping" state, which occurs
  * when the thread has been uninstalled or marked as no longer active. It is
  * typically used to assess the thread's lifecycle status and decide if further
  * operations can proceed safely.
  *
  * @return True if the thread is stopping, otherwise false.
  */
 bool IsStopping() const;

 /**
  * @brief Starts a new thread with the specified name and stack size.
  *
  * The `Start` method initializes a thread with a given name for identification
  * and the desired stack size. It creates a new thread using platform-specific
  * threading mechanisms. The thread begins execution at the `Run` method of
  * the `TThread` class.
  *
  * @param ThreadName A null-terminated string representing the name of the thread.
  *                   The name is used for identification purposes and is copied
  *                   internally to ensure life-span during thread operation.
  * @param StackSize The stack size (in bytes) to allocate for the thread. This value
  *                  depends on the requirements of the specific thread operation.
  */
 void Start(const char *ThreadName, int StackSize);

 /**
  * @brief Starts a thread with the specified name, priority, and stack size.
  *
  * This method initializes the thread's name and creates a new thread for execution.
  * Depending on the platform, it utilizes either RDOS-specific or POSIX-specific
  * thread creation mechanisms. The thread will begin executing the `Run` method.
  *
  * @param ThreadName A null-terminated string representing the name of the thread.
  *                   The name is allocated dynamically and stored internally.
  * @param Prio       An integer specifying the priority of the thread. This parameter
  *                   is platform-dependent and may vary in interpretation across systems.
  * @param StackSize  An integer representing the size of the stack to be allocated
  *                   for the thread in bytes.
  */
 void Start(const char *ThreadName, int Prio, int StackSize);

 /**
  * @brief Executes the main logic of the thread.
  *
  * The Execute method contains the core functionality of the thread and is
  * intended to be overridden in derived classes to implement custom behavior.
  * It is called internally by the Run method once the thread is initialized
  * and marked as running.
  *
  * This method should include the specific operations that the thread is
  * expected to perform during its lifecycle. Subclasses can define the task by
  * overriding this method, ensuring proper thread processing within the class's
  * context.
  *
  * @note Execute is invoked only when the thread is successfully started by
  *       the Run method.
  */
 virtual void Execute();

 /**
  * @var FInstalled
  * @brief Indicates whether the thread object is currently installed and operational.
  *
  * This variable is used to track the installation state of the thread. It is initialized
  * to `true` during the construction of the thread object and set to `false` when the thread
  * is stopped. This flag is critical for managing the lifecycle and ensuring proper cleanup
  * of the thread.
  */
 bool FInstalled;

 /**
  * @var TSignalDevice* FStopSignal
  * @brief Pointer to a signal device used to manage thread termination in RDOS environments.
  *
  * This member variable holds a reference to a TSignalDevice instance, which facilitates
  * signaling mechanisms for thread stop operations. It is primarily used in conjunction
  * with the thread's stop section to ensure proper synchronization and controlled termination.
  *
  * This is only initialized and used in RDOS-specific implementations, enabling platform-specific
  * handling of thread stop signals. On non-RDOS platforms, this variable remains unused.
  */
 TSignalDevice *FStopSignal;

 /**
  * @var FThreadName
  * @brief Stores the name associated with a thread.
  *
  * This variable holds the name of the thread for identification purposes.
  * It facilitates debugging and logging by providing a human-readable identifier
  * for each thread. The memory for this variable is dynamically allocated and
  * released as required.
  */
 char *FThreadName;
 /**
  * @class FStopSection
  * @brief A synchronization section for managing thread stop operations.
  *
  * The FStopSection is an instance of the TSection class used to ensure thread-safe
  * operations during the stopping process of a thread. It provides a critical section
  * mechanism that prevents race conditions when multiple threads attempt to interact
  * with shared resources related to stopping a thread.
  *
  * This synchronization section is particularly utilized by methods such as `Stop`
  * in the TThread class to manage thread state transitions and to safely interact
  * with other platform-specific resources like signals or futexes during the shutdown
  * sequence.
  */
 TSection FStopSection;

#ifndef __RDOS__
 /**
  * @typedef pthread_t ThreadId
  * @brief Represents the unique identifier for a thread in POSIX systems.
  *
  * ThreadId is used to store and manage the thread identifier created by the
  * pthread_create function in the POSIX threading library. It serves as a handle
  * for performing thread management tasks such as joining or detaching threads.
  * The variable is platform-dependent and is typically used in non-RDOS implementations
  * within the TThread class.
  */
 pthread_t ThreadId;
 /**
  * @var FRet
  * @brief Represents the return value from thread creation.
  *
  * FRet is an integer that stores the result of a thread creation attempt
  * when using the `pthread_create` function on non-RDOS platforms. It holds
  * `0` if the thread is successfully created, or a non-zero error code in
  * the event of a failure. This value can be used for debugging and error
  * handling related to thread initialization.
  */
 int FRet;
#endif

 /**
  * @var FThreadRunning
  * @brief Indicates whether the thread is currently running.
  *
  * This variable is used to keep track of the runtime state of a thread. It is set
  * to `true` when the thread starts running and is set to `false` when the thread
  * has stopped or is no longer active. This flag is critical for managing thread
  * lifecycle and ensuring proper synchronization during thread operations such as
  * starting or stopping.
  */
private:
    bool FThreadRunning;
};

#endif

