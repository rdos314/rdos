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
# thread.cpp
# Basic thread class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#ifdef __RDOS__
#include <rdos.h>
#else
#include <pthread.h>
#endif

#include "sigdev.h"
#include "thread.h"

/**
 * @brief Represents a thread that executes a user-defined startup routine.
 *
 * This class extends `TThread` and serves as a wrapper for a thread execution
 * mechanism, allowing the user to specify a custom startup function and
 * accompanying arguments. The thread is initialized with parameters such as
 * thread name, stack size, and function to invoke upon execution.
 */
class TStartThread : public TThread
{
public:
    /**
     * @brief Constructs a thread instance and initializes the thread startup routine.
     *
     * This constructor sets up a thread to execute the provided startup routine
     * with the specified properties, such as a thread name, a pointer to the thread
     * execution context, and the stack size.
     *
     * @param Startup A function pointer representing the startup routine that
     *        will be invoked when the thread is executed.
     * @param ThreadName A string representing the name of the thread.
     * @param ptr A pointer to the thread's execution context or associated data.
     * @param StackSize An integer specifying the stack size for the thread.
     */
    TStartThread(void (*Startup)(void *ptr), const char *ThreadName, void *ptr, int StackSize);

    /**
     * @brief Destructor for the TStartThread class.
     *
     * Cleans up resources associated with a `TStartThread` instance. This method
     * is called automatically when an object of the class goes out of scope
     * or is explicitly deleted. The destructor ensures any specific resource
     * management or cleanup logic defined for the `TStartThread` class is executed.
     */
    virtual ~TStartThread();

    /**
     * @brief Function pointer used as the entry routine for a thread.
     *
     * This pointer references a custom startup function that typically serves
     * as the entry point for thread execution. The function is invoked with a
     * single argument, which is a pointer to a user-defined data structure or
     * object required for the thread's execution.
     *
     * @param ptr A pointer to the user-defined data or object passed to the
     *            startup function for initialization or execution logic.
     */
    void (*FStartup)(void *ptr);

    /**
     * @brief Pointer to data for thread execution.
     *
     * This variable holds a generic pointer to data that is passed to the thread's
     * execution routine. The value of this pointer is typically set during the initialization
     * of a thread object and is subsequently used by the thread's execution function.
     *
     * It is commonly utilized as a mechanism to pass user-defined data or context information
     * to the thread logic defined in the `Execute` method or via the startup routine.
     */
    void *FPtr;
    /**
     * @brief Executes the startup routine for the thread.
     *
     * Calls the function pointer `FStartup` with the argument `FPtr`.
     * This method serves as the primary execution routine for the thread
     * encapsulated by the `TStartThread` class. Once execution is complete,
     * the current instance of `TStartThread` is deleted to free resources.
     */
    void Execute();
};

/**
 * @brief Constructs a TStartThread object and initializes a new thread.
 *
 * This constructor assigns the thread startup routine and associated data pointer,
 * and invokes the `Start` method with the specified thread name and stack size.
 *
 * @param Startup A function pointer representing the startup routine for the thread.
 * @param ThreadName A string denoting the name of the thread.
 * @param ptr A pointer to the data to be passed to the thread startup routine.
 * @param StackSize An integer specifying the stack size for the thread.
 */
TStartThread::TStartThread(void (*Startup)(void *ptr), const char *ThreadName, void *ptr, int StackSize)
{
    FStartup = Startup;
    FPtr = ptr;
    Start(ThreadName, StackSize);
}

/**
 * @brief Destructor for the `TStartThread` class.
 *
 * Cleans up resources associated with the `TStartThread` instance.
 * This destructor ensures that the thread object is properly
 * finalized when it goes out of scope or is explicitly deleted.
 */
TStartThread::~TStartThread()
{
}

/**
 * @brief Executes the thread's main function and self-destroys the thread object.
 *
 * Invokes the function pointer provided during the thread's initialization,
 * passing the associated pointer as an argument. Once the function execution
 * is complete, the thread object deletes itself to free associated resources.
 *
 * @note This method is responsible for calling the specified startup function
 * and managing the object's lifecycle. Ensure that the object is not accessed
 * after the `Execute` method is called.
 */
void TStartThread::Execute()
{
    (*(FStartup))(FPtr);
    delete this;
}

/**
 * @brief Creates and initializes a new thread.
 *
 * Allocates a new instance of `TStartThread` with the specified startup function,
 * thread name, context pointer, and stack size. This function serves as a helper
 * to set up and prepare a thread for execution.
 *
 * @param Startup A pointer to a function that will be executed as the thread's entry point.
 *                The function should accept a single `void*` argument for context.
 * @param ThreadName A string representing the name of the thread. Intended for debugging or logging purposes.
 * @param ptr A pointer to the context or data to be passed to the thread's startup routine.
 * @param StackSize An integer specifying the stack size for the thread.
 */
void CreateThread(void (*Startup)(void *ptr), const char *ThreadName, void *ptr, int StackSize)
{
    TStartThread *thread = new TStartThread(Startup, ThreadName, ptr, StackSize);
}

/**
 * @brief Entry point for starting a thread execution.
 *
 * This function serves as the initial entry function for a thread.
 * It casts the provided pointer to a TThread object and invokes
 * the associated Run method to execute the thread's task logic.
 *
 * @param ptr A pointer to a TThread object, passed to the thread upon creation.
 */
#ifdef __RDOS__
static void ThreadStartup(void *ptr)
{
    ((TThread *)ptr)->Run();
}
#else
/**
 * @brief Entry point for thread execution.
 *
 * Invokes the `Run` method of the `TThread` instance passed as an argument.
 * This function is commonly used as the thread startup routine when creating
 * threads using platform-specific thread creation mechanisms such as `pthread_create`.
 *
 * @param ptr A pointer to a `TThread` instance whose `Run` method will be executed.
 *
 * @return Always returns a null pointer (0) to indicate the end of thread execution.
 */
static void *ThreadStartup(void *ptr)
{
    ((TThread *)ptr)->Run();
    return 0;
}
#endif

/**
 * @brief Constructs a new instance of the TThread class.
 *
 * Initializes thread control variables including synchronization mechanisms
 * and thread state flags. Prepares the thread object for subsequent use.
 *
 * @return A new instance of the TThread class.
 */
TThread::TThread()
  : FStopSection("Thread.Stop")
{
    FInstalled = true;
    FThreadRunning = false;
    Owner = 0;
    FThreadName = 0;
    FStopSignal = 0;

#ifndef __RDOS__
    ThreadId = 0;
    FRet = 0;
#endif
}

/**
 * @brief Constructs a TThread object and initializes the internal thread state.
 *
 * This constructor initializes the thread object with the given thread name and stack size,
 * setting up the required properties and starting the thread.
 *
 * @param ThreadName The name of the thread to be created.
 * @param StackSize The size of the stack to be allocated for this thread.
 * @return Does not return a value; constructs the TThread object.
 */
TThread::TThread(const char *ThreadName, int StackSize)
: FStopSection("Thread.Stop")
{
    FInstalled = true;
    FThreadRunning = false;
    Owner = 0;
    FThreadName = 0;
    FStopSignal = 0;

#ifndef __RDOS__
    ThreadId = 0;
    FRet = 0;
#endif
    
    Start(ThreadName, StackSize);
}

/**
 * @brief Constructs a new thread object with the specified parameters.
 *
 * This constructor initializes the thread object with the given name, stack size,
 * and an option to start the thread immediately.
 *
 * @param ThreadName The name of the thread.
 * @param StackSize The size of the stack allocated to the thread.
 * @param Run A boolean flag indicating whether the thread should start running
 *            immediately after creation.
 *
 * @return None
 */
TThread::TThread(const char *ThreadName, int StackSize, bool Run)
  : FStopSection("Thread.Stop")
{
    FInstalled = true;
    FThreadRunning = false;
    Owner = 0;
    FThreadName = 0;
    FStopSignal = 0;

#ifndef __RDOS__
    ThreadId = 0;
    FRet = 0;
#endif

    if (Run)
        Start(ThreadName, StackSize);
}

/**
 * @brief Destructor for the TThread class.
 *
 * This destructor ensures that the thread's operation is stopped before
 * cleaning up thread-specific resources. If a thread name exists, it is
 * safely deallocated to prevent memory leaks.
 *
 * @note The Stop() method is called to perform any necessary cleanup
 *       related to the thread before the object is destroyed.
 */
TThread::~TThread()
{
    Stop();

    if (FThreadName)
        delete FThreadName;
}

/**
 * @brief Indicates that the thread has been terminated.
 *
 * This method is called to signal that the execution of the current
 * thread has ended. It does not perform any action by default, but
 * can be overridden in derived classes to implement custom behavior
 * upon thread termination.
 *
 * This function must be invoked by the thread that is ending, typically
 * as a part of its cleanup process.
 */
void TThread::Terminated()
{
}

/**
 * @brief Stops the execution of the thread and ensures the thread has terminated before returning.
 *
 * This method terminates the thread's operation in a controlled manner. It first validates if the
 * thread is currently running. If the thread is active, it acquires the necessary synchronization
 * mechanisms to safely manage the stop operation.
 *
 * On platforms that support the RDOS operating system, it utilizes a signal device to facilitate
 * the thread's controlled termination. The method ensures that the thread terminates completely
 * before releasing the synchronization locks and exiting. Additionally, platform-specific
 * operations are performed to properly manage resources associated with the thread.
 *
 * It is important to note that this method should only be called when the thread is guaranteed to
 * not execute critical or non-interruptible operations during the stop process.
 *
 * @warning Ensure that proper synchronization is maintained when invoking this method to avoid
 * potential deadlocks or undefined behaviors.
 */
void TThread::Stop()
{
    if (FThreadRunning)
    {
        TSignalDevice FSignal;

        FStopSection.Enter();

        FStopSignal = &FSignal;
        FInstalled = false;

        while (FThreadRunning)
        {
            FStopSection.Leave();
            FSignal.WaitForever();
            FStopSection.Enter();
        }

        FStopSignal = 0;

        FStopSection.Leave();
    }
}

/**
 * Checks whether the thread is in the process of stopping.
 *
 * This method determines if the thread is no longer installed and operational.
 *
 * @return true if the thread is stopping (not installed), false otherwise.
 */
bool TThread::IsStopping() const
{
    return !FInstalled;
}

/**
 * @brief Checks if the thread is currently running.
 *
 * This method returns the status of the thread execution by checking
 * the internal state. It provides a way to determine if the thread
 * is actively running.
 *
 * @return true if the thread is running, false otherwise.
 */
bool TThread::IsRunning() const
{
    return FThreadRunning;
}

/**
 * Starts a new thread with the specified name and stack size.
 *
 * This method initializes the thread by storing the provided thread name
 * and creating a new execution context with the given stack size.
 *
 * @param ThreadName Name of the thread to be started. This name is used
 *                   for identification and debugging purposes.
 * @param StackSize  Size of the stack for the new thread, typically specified
 *                   in bytes. The stack size affects the available memory for
 *                   the thread's execution.
 */
void TThread::Start(const char *ThreadName, int StackSize)
{
    int size = strlen(ThreadName) + 1;
    FThreadName = new char[size];
    strcpy(FThreadName, ThreadName);

#ifdef __RDOS__
    RdosCreateThread(ThreadStartup, ThreadName, this, StackSize);
#else
    FRet = pthread_create(&ThreadId, NULL, ThreadStartup, this);
#endif
}

/**
 * @brief Starts a new thread with the specified parameters.
 *
 * This method initializes and starts a new thread with the provided name,
 * priority, and stack size. The thread is created and executed on the platform-dependent
 * threading mechanism.
 *
 * @param ThreadName The name of the thread. It is copied internally, so the original string
 *                   does not need to persist after the call.
 * @param Prio The priority for the thread. The valid range and behavior depend on the underlying
 *             threading system.
 * @param StackSize The stack size for the thread in bytes. This value may be ignored or adjusted
 *                  based on the platform's threading implementation.
 *
 * @note On RDOS systems, the thread is created using the RdosCreatePrioThread function, which
 *       directly incorporates the priority and stack size arguments into the thread creation.
 *       On non-RDOS systems, the thread is created using the pthread_create function.
 *
 * @warning Ensure that the provided ThreadName is not null. Additionally, resources such as
 *          the allocated FThreadName must be properly managed to avoid memory leaks.
 */
void TThread::Start(const char *ThreadName, int Prio, int StackSize)
{
    int size = strlen(ThreadName) + 1;
    FThreadName = new char[size];
    strcpy(FThreadName, ThreadName);

#ifdef __RDOS__
    RdosCreatePrioThread(ThreadStartup, Prio, ThreadName, this, StackSize);
#else
    FRet = pthread_create(&ThreadId, NULL, ThreadStartup, this);
#endif
}

/**
 * @brief Initiates the thread's execution and manages its lifecycle.
 *
 * This method sets up the thread to begin execution by marking it as installed
 * and running. The implementation ensures thread safety and proper signaling
 * during the thread's termination.
 *
 * - The method checks if the thread is not already running before proceeding.
 * - It invokes the Execute function, which contains the thread's core logic.
 * - Ensures synchronization by entering and leaving the stop section while updating
 *   the thread's running state.
 * - On supported platforms, a stop signal is optionally sent to signal thread shutdown.
 * - After execution, the Terminated method is called for cleanup or additional processing.
 *
 * @note This method should not be called directly unless managing the
 *       thread's lifecycle explicitly.
 */
void TThread::Run()
{
    FInstalled = true;
    if (!FThreadRunning)
    {
        FThreadRunning = true;
        Execute();

        FStopSection.Enter();
        FThreadRunning = false;

        if (FStopSignal)
            FStopSignal->Signal();

        FStopSection.Leave();

        Terminated();
    }
}

/**
 * @brief Executes the thread's main task.
 *
 * This method contains the logic to be run when the thread is executed.
 * It is meant to be overridden or implemented with specific behavior
 * in derived classes or user-defined code.
 *
 * Ensure implementation is thread-safe as this may be invoked on
 * a separate thread context when operating within multithreaded
 * environments.
 */
void TThread::Execute()
{
}
