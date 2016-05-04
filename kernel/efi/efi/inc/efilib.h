#ifndef _EFILIB_INCLUDE_
#define _EFILIB_INCLUDE_

/*++

Copyright (c) 2000  Intel Corporation

Module Name:

    efilib.h

Abstract:

    EFI library functions



Revision History

--*/

#include "efidebug.h"
#include "efipart.h"
#include "efilibplat.h"
#include "efilink.h"
#include "efirtlib.h"
#include "pci22.h"
#include "libsmbios.h"

//
// Public read-only data in the EFI library
//

extern EFI_SYSTEM_TABLE         *ST;
extern EFI_BOOT_SERVICES        *BS;
extern EFI_RUNTIME_SERVICES     *RT;

extern EFI_GUID DevicePathProtocol;
extern EFI_GUID LoadedImageProtocol;
extern EFI_GUID TextInProtocol;
extern EFI_GUID TextOutProtocol;
extern EFI_GUID BlockIoProtocol;
extern EFI_GUID DiskIoProtocol;
extern EFI_GUID FileSystemProtocol;
extern EFI_GUID LoadFileProtocol;
extern EFI_GUID DeviceIoProtocol;
extern EFI_GUID VariableStoreProtocol;
extern EFI_GUID LegacyBootProtocol;
extern EFI_GUID UnicodeCollationProtocol;
extern EFI_GUID SerialIoProtocol;
extern EFI_GUID VgaClassProtocol;
extern EFI_GUID TextOutSpliterProtocol;
extern EFI_GUID ErrorOutSpliterProtocol;
extern EFI_GUID TextInSpliterProtocol;
extern EFI_GUID SimpleNetworkProtocol;
extern EFI_GUID PxeBaseCodeProtocol;
extern EFI_GUID PxeCallbackProtocol;
extern EFI_GUID NetworkInterfaceIdentifierProtocol;
extern EFI_GUID UiProtocol;
extern EFI_GUID InternalShellProtocol;
extern EFI_GUID PciIoProtocol;
extern EFI_GUID GopProtocol;

extern EFI_GUID EfiGlobalVariable;
extern EFI_GUID GenericFileInfo;
extern EFI_GUID FileSystemInfo;
extern EFI_GUID FileSystemVolumeLabelInfo;
extern EFI_GUID PcAnsiProtocol;
extern EFI_GUID Vt100Protocol;
extern EFI_GUID NullGuid;
extern EFI_GUID UnknownDevice;

extern EFI_GUID EfiPartTypeSystemPartitionGuid;
extern EFI_GUID EfiPartTypeLegacyMbrGuid;

extern EFI_GUID MpsTableGuid;
extern EFI_GUID AcpiTableGuid;
extern EFI_GUID SMBIOSTableGuid;
extern EFI_GUID SalSystemTableGuid;

//
// EFI Variable strings
//
#define LOAD_OPTION_ACTIVE      0x00000001

#define VarLanguageCodes       L"LangCodes"
#define VarLanguage            L"Lang"
#define VarTimeout             L"Timeout"
#define VarConsoleInp          L"ConIn"
#define VarConsoleOut          L"ConOut"
#define VarErrorOut            L"ErrOut"
#define VarBootOption          L"Boot%04x"
#define VarBootOrder           L"BootOrder"
#define VarBootNext            L"BootNext"
#define VarBootCurrent         L"BootCurrent"
#define VarDriverOption        L"Driver%04x"
#define VarDriverOrder         L"DriverOrder"
#define VarConsoleInpDev       L"ConInDev"
#define VarConsoleOutDev       L"ConOutDev"
#define VarErrorOutDev         L"ErrOutDev"

#define LanguageCodeEnglish    "eng"

extern EFI_DEVICE_PATH RootDevicePath[];
extern EFI_DEVICE_PATH EndDevicePath[];
extern EFI_DEVICE_PATH EndInstanceDevicePath[];

//
// Other public data in the EFI library
//

extern EFI_MEMORY_TYPE PoolAllocationType;


//
// BugBug: I need my own include files
//
typedef struct {
    UINT8   Register;
    UINT8   Function;
    UINT8   Device;
    UINT8   Bus;
    UINT32  Reserved;
} EFI_ADDRESS;
typedef union {
    UINT64          Address;
    EFI_ADDRESS     EfiAddress;
} EFI_PCI_ADDRESS_UNION;

#endif
