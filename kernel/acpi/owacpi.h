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

