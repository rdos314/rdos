#pragma aux ServUacpiGetAcpi = \
    ServGate_uacpi_get_acpi  \
    __value [__edx __eax]

#pragma aux ServUacpiMap = \
    ServGate_uacpi_map  \
    __parm [__edx __eax] [__ecx] \
    __value [_eax]

#pragma aux ServUacpiUnmap = \
    ServGate_uacpi_unmap  \
    __parm [__edx] [__ecx]

#pragma aux ServUacpiEnableIo = \
    ServGate_uacpi_enable_io  \
    "jc fail " \
    "mov eax,1" \
    "jmp done " \
    "fail: " \
    "xor eax,eax" \
    "done: " \
    __parm [__edx] [__ecx] \
    __value [__eax]

#pragma aux ServUacpiDisableIo = \
    ServGate_uacpi_disable_io  \
    "jc fail " \
    "mov eax,1" \
    "jmp done " \
    "fail: " \
    "xor eax,eax" \
    "done: " \
    __parm [__edx] [__ecx] \
    __value [__eax]

#pragma aux ServUacpiStartPci = \
    ServGate_uacpi_start_pci

#pragma aux ServUacpiHasApic = \
    ServGate_uacpi_has_apic  \
    "jc fail " \
    "mov eax,1" \
    "jmp done " \
    "fail: " \
    "xor eax,eax" \
    "done: " \
    __value [__eax]

#pragma aux ServUacpiAllocateInts = \
    ServGate_uacpi_allocate_ints  \
    __parm [__ecx] [__al] \
    __value [__al]

#pragma aux ServUacpiFreeInt = \
    ServGate_uacpi_free_int  \
    __parm [__al]

#pragma aux ServUacpiGetMsiAddress = \
    ServGate_uacpi_get_msi_address  \
    __parm [__eax] \
    __value [__eax]

#pragma aux ServUacpiGetMsiData = \
    ServGate_uacpi_get_msi_data  \
    __parm [__eax] \
    __value [__eax]

#pragma aux ServUacpiGetTaskQueue = \
    ServGate_uacpi_get_task_queue \
    __value [__eax]

#pragma aux ServUacpiWaitTaskQueue = \
    ServGate_uacpi_wait_task_queue \
    __parm [__eax]

#pragma aux ServUacpiGetThreadState = \
    ServGate_uacpi_get_thread_state \
    "jc fail " \
    "mov eax,1" \
    "jmp done " \
    "fail: " \
    "xor eax,eax" \
    "done: " \
    __parm [__ebx] [__edi] __value [__eax]

#pragma aux ServUacpiGetThreadName = \
    ServGate_uacpi_get_thread_name \
    "jc fail " \
    "mov eax,1" \
    "jmp done " \
    "fail: " \
    "xor eax,eax" \
    "done: " \
    __parm [__ebx] [__edi] __value [__eax]

#pragma aux ServUacpiGetThreadIrqArr = \
    ServGate_uacpi_get_thread_irq_arr \
    __parm [__ebx] [__edi]

#pragma aux ServUacpiSetThreadIrq = \
    ServGate_uacpi_set_thread_irq \
    __parm [__ebx] [__al]

#pragma aux ServUacpiGetThreadProcess = \
    ServGate_uacpi_get_thread_process \
    "jnc done " \
    "xor eax,eax" \
    "done: " \
    __parm [__ebx] __value [__eax]

#pragma aux ServUacpiGetThread = \
    ServGate_uacpi_get_thread \
    __value [__eax]

#pragma aux ServUacpiGetCoreCount = \
    ServGate_uacpi_get_core_count \
    "jnc ok " \
    "mov eax,1" \
    "ok: " \
    __value [__eax]

#pragma aux ServUacpiStartCore = \
    ServGate_uacpi_start_core \
    __parm [__ebx]

#pragma aux ServUacpiStopCore = \
    ServGate_uacpi_stop_core \
    __parm [__ebx]

#pragma aux ServUacpiSetThreadCore = \
    ServGate_uacpi_set_thread_core \
    __parm [__ebx] [__eax]
