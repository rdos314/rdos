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

#pragma aux ServUacpiReadPciByte = \
    ServGate_uacpi_read_pci_byte  \
    __parm [__ebx]  \
    __value [__al]

#pragma aux ServUacpiReadPciWord = \
    ServGate_uacpi_read_pci_word  \
    __parm [__ebx]  \
    __value [__ax]

#pragma aux ServUacpiReadPciDword = \
    ServGate_uacpi_read_pci_dword  \
    __parm [__ebx]  \
    __value [__eax]

#pragma aux ServUacpiWritePciByte = \
    ServGate_uacpi_write_pci_byte  \
    __parm [__ebx] [__al]

#pragma aux ServUacpiWritePciWord = \
    ServGate_uacpi_write_pci_word  \
    __parm [__ebx] [__ax]

#pragma aux ServUacpiWritePciDword = \
    ServGate_uacpi_write_pci_dword  \
    __parm [__ebx] [__eax]
