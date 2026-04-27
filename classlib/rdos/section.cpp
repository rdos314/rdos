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
# section.cpp
# Critical section class
#
########################################################################*/

#include <string.h>
#include "section.h"

/**
 * Constructs a TSection object by initializing its name and the synchronization mechanism.
 *
 * The name is copied and truncated to a maximum of 32 characters. Depending on the platform,
 * the constructor initializes either a futex or a mutex to provide thread synchronization.
 *
 * @param Name A null-terminated string representing the name of the section. It will be truncated to 32 characters if it exceeds this length.
 * @return None
 */
TSection::TSection(const char *Name)
{
    strncpy(FName, Name, 32);
    FName[32] = 0;

#ifdef __RDOS__
    RdosInitFutex(&Futex, FName);
#else
    Mutex = PTHREAD_MUTEX_INITIALIZER;
#endif
}

/**
 * @brief Destructor for the TSection class.
 *
 * This destructor is responsible for cleaning up resources associated
 * with the TSection object. On platforms where the macro `__RDOS__` is
 * defined, it specifically calls `RdosResetFutex` to reset the futex
 * associated with the object. This ensures proper release of any system-specific
 * synchronization constructs used by the TSection instance.
 *
 * For non-RDOS platforms, no specific cleanup is performed by this destructor,
 * as resource management may rely on default behavior or other platform-specific
 * implementation details.
 */
TSection::~TSection()
{
#ifdef __RDOS__
    RdosResetFutex(&Futex);
#endif
}

/**
 * @brief Acquires the synchronization lock for the section.
 *
 * This method is used to enter a critical section by ensuring exclusive access to
 * the protected resource. If the lock is already held by another thread, the calling
 * thread will block until the lock becomes available.
 *
 * On systems where `__RDOS__` is defined, the method uses the `RdosEnterFutex` function
 * to acquire the synchronization lock. On other systems, it utilizes `pthread_mutex_lock`
 * for mutex-based synchronization.
 *
 * Proper usage of this method should always ensure that `Enter` is paired with a
 * corresponding `Leave` call to prevent deadlocks and resource contention.
 */
void TSection::Enter() const
{
#ifdef __RDOS__
    RdosEnterFutex(&Futex);
#else
    pthread_mutex_lock(&Mutex);
#endif
}

/**
 * @brief Releases the lock held by the current thread on the synchronization object.
 *
 * This method is used to release a previously acquired lock, allowing other threads
 * to access the shared resource protected by the synchronization mechanism.
 *
 * On systems where `__RDOS__` is defined, it uses `RdosLeaveFutex` to unlock the futex.
 * On other platforms, it utilizes `pthread_mutex_unlock` to release the mutex.
 *
 * Ensure that every call to `Enter` is followed by a corresponding call to `Leave`
 * to maintain proper synchronization and avoid deadlocks in a multi-threaded environment.
 */
void TSection::Leave() const
{
#ifdef __RDOS__
    RdosLeaveFutex(&Futex);
#else
    pthread_mutex_unlock(&Mutex);
#endif
}
