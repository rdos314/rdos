;*********************************************************************
;*                                                                   *
;*          UEFI library for fasm by bzt, Public Domain              *
;*                                                                   *
;*********************************************************************

;first part original credits:
;http://x86asm.net/articles/uefi-programming-first-steps/efi.inc

;for 32/64 portability and automatic natural align in structure definitions

struc int8 {
  . db ?
}
struc int16 {
  align 2
  . dw ?
}
struc int32 {
  align 4
  . dd ?
}
struc int64 {
  align 8
  . dq ?
}
struc intn {
  align 8
  . dq ?
}
struc dptr {
  align 8
  . dq ?
}

;symbols

EFIERR = 0x8000000000000000
EFI_SUCCESS			= 0
EFI_LOAD_ERROR			= EFIERR or 1
EFI_INVALID_PARAMETER		= EFIERR or 2
EFI_UNSUPPORTED 		= EFIERR or 3
EFI_BAD_BUFFER_SIZE		= EFIERR or 4
EFI_BUFFER_TOO_SMALL		= EFIERR or 5
EFI_NOT_READY			= EFIERR or 6
EFI_DEVICE_ERROR		= EFIERR or 7
EFI_WRITE_PROTECTED		= EFIERR or 8
EFI_OUT_OF_RESOURCES		= EFIERR or 9
EFI_VOLUME_CORRUPTED		= EFIERR or 10
EFI_VOLUME_FULL 		= EFIERR or 11
EFI_NO_MEDIA			= EFIERR or 12
EFI_MEDIA_CHANGED		= EFIERR or 13
EFI_NOT_FOUND			= EFIERR or 14
EFI_ACCESS_DENIED		= EFIERR or 15
EFI_NO_RESPONSE 		= EFIERR or 16
EFI_NO_MAPPING			= EFIERR or 17
EFI_TIMEOUT			= EFIERR or 18
EFI_NOT_STARTED 		= EFIERR or 19
EFI_ALREADY_STARTED		= EFIERR or 20
EFI_ABORTED			= EFIERR or 21
EFI_ICMP_ERROR			= EFIERR or 22
EFI_TFTP_ERROR			= EFIERR or 23
EFI_PROTOCOL_ERROR		= EFIERR or 24

;helper macro for definition of relative structure member offsets

macro struct name
{
  virtual at 0
    name name
  end virtual
}

;structures
EFI_SYSTEM_TABLE_SIGNATURE	equ	49h,42h,49h,20h,53h,59h,53h,54h
struc EFI_TABLE_HEADER {
 .Signature    		int64
 .Revision     		int32
 .HeaderSize   		int32
 .CRC32        		int32
 .Reserved     		int32
}
struct EFI_TABLE_HEADER

struc EFI_SYSTEM_TABLE {
 .Hdr		        EFI_TABLE_HEADER
 .FirmwareVendor        dptr
 .FirmwareRevision      int32
 .ConsoleInHandle       dptr
 .ConIn 	        dptr
 .ConsoleOutHandle      dptr
 .ConOut	        dptr
 .StandardErrorHandle   dptr
 .StdErr	        dptr
 .RuntimeServices       dptr
 .BootServices	        dptr
 .NumberOfTableEntries  intn
 .ConfigurationTable    dptr
}
struct EFI_SYSTEM_TABLE

struc SIMPLE_TEXT_OUTPUT_INTERFACE {
 .Reset 	    	dptr
 .OutputString	    	dptr
 .TestString	    	dptr
 .QueryMode	    	dptr
 .SetMode	    	dptr
 .SetAttribute	    	dptr
 .ClearScreen	    	dptr
 .SetCursorPosition 	dptr
 .EnableCursor	    	dptr
 .Mode		    	dptr
}
struct SIMPLE_TEXT_OUTPUT_INTERFACE

;---added new structures, bzt---

struc SIMPLE_INPUT_INTERFACE {
 .Reset			dptr
 .ReadKeyStroke		dptr
 .WaitForKey		dptr
}
struct SIMPLE_INPUT_INTERFACE

struc EFI_BOOT_SERVICES_TABLE {
 .Hdr		       	EFI_TABLE_HEADER
 .RaisePriority		dptr
 .RestorePriority	dptr
 .AllocatePages		dptr
 .FreePages		dptr
 .GetMemoryMap		dptr
 .AllocatePool		dptr
 .FreePool		dptr
 .CreateEvent		dptr
 .SetTimer		dptr
 .WaitForEvent		dptr
 .SignalEvent		dptr
 .CloseEvent		dptr
 .CheckEvent		dptr
 .InstallProtocolInterface dptr
 .ReInstallProtocolInterface dptr
 .UnInstallProtocolInterface dptr
 .HandleProtocol	dptr
 .Void			dptr
 .RegisterProtocolNotify dptr
 .LocateHandle		dptr
 .LocateDevicePath	dptr
 .InstallConfigurationTable dptr
 .ImageLoad		dptr
 .ImageStart		dptr
 .Exit			dptr
 .ImageUnLoad		dptr
 .ExitBootServices	dptr
 .GetNextMonotonicCount	dptr
 .Stall			dptr
 .SetWatchdogTimer	dptr
 .ConnectController	dptr
 .DisConnectController	dptr
 .OpenProtocol		dptr
 .CloseProtocol		dptr
 .OpenProtocolInformation dptr
 .ProtocolsPerHandle	dptr
 .LocateHandleBuffer	dptr
 .LocateProtocol	dptr
 .InstallMultipleProtocolInterfaces dptr
 .UnInstallMultipleProtocolInterfaces dptr
 .CalculateCrc32	dptr
 .CopyMem		dptr
 .SetMem		dptr
}
struct EFI_BOOT_SERVICES_TABLE

struc EFI_RUNTIME_SERVICES_TABLE {
 .Hdr		       	EFI_TABLE_HEADER
 .GetTime		dptr
 .SetTime		dptr
 .GetWakeUpTime		dptr
 .SetWakeUpTime		dptr
 .SetVirtualAddressMap	dptr
 .ConvertPointer	dptr
 .GetVariable		dptr
 .GetNextVariableName	dptr
 .SetVariable		dptr
 .GetNextHighMonoCount	dptr
 .ResetSystem		dptr
}
struct EFI_RUNTIME_SERVICES_TABLE

struc EFI_TIME {
 .Year			int16
 .Month			int8
 .Day			int8
 .Hour			int8
 .Minute		int8
 .Second		int8
 .Pad1			int8
 .Nanosecond		int32
 .TimeZone		int16
 .Daylight		int8
 .Pad2			int8
 .sizeof		rb 1
}
struct EFI_TIME

EFI_LOADED_IMAGE_PROTOCOL_UUID equ 0A1h,31h,1bh,5bh,62h,95h,0d2h,11h,8Eh,3Fh,0h,0A0h,0C9h,69h,72h,3Bh
struc EFI_LOADED_IMAGE_PROTOCOL {
 .Revision		int32
 .ParentHandle		int64
 .SystemTable		dptr
 .DeviceHandle		int64
 .FilePath		dptr
 .Reserved		int64
 .LoadOptionsSize	int32
 .ImageBase		dptr
 .ImageSize		int64
 .ImageCodeType		int32
 .ImageDataType		int32
 .UnLoad		dptr
}
struct EFI_LOADED_IMAGE_PROTOCOL

EFI_BLOCK_IO_PROTOCOL_UUID equ 21h,5bh,4eh,96h,59h,64h,0d2h,11h,8eh,39h,00h,0a0h,0c9h,69h,72h,3bh
struc EFI_BLOCK_IO_PROTOCOL {
 .Revision		int64
 .Media			dptr
 .Reset			dptr
 .ReadBlocks		dptr
 .WriteBlocks		dptr
 .FlushBlocks		dptr
}
struct EFI_BLOCK_IO_PROTOCOL

struc EFI_BLOCK_IO_MEDIA {
 .MediaId		int32
 .RemovableMedia	int8
 .MediaPresent		int8
 .LogicalPartition	int8
 .ReadOnly		int8
 .WriteCaching		int8
 .BlockSize		int32
 .IoAlign		int32
 .LastBlock		int64
}
struct EFI_BLOCK_IO_MEDIA

EFI_GRAPHICS_OUTPUT_PROTOCOL_UUID equ 0deh, 0a9h, 42h,90h,0dch,023h,38h,04ah,96h,0fbh,7ah,0deh,0d0h,80h,51h,6ah
struc EFI_GRAPHICS_OUTPUT_PROTOCOL {
 .QueryMode		dptr
 .SetMode		dptr
 .Blt			dptr
 .Mode			dptr
}
struct EFI_GRAPHICS_OUTPUT_PROTOCOL

struc EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE {
 .MaxMode		int32
 .CurrentMode		int32
 .ModeInfo		dptr
 .SizeOfModeInfo	intn
 .FrameBufferBase	dptr
 .FrameBufferSize	intn
}
struct EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE

struc EFI_GRAPHICS_OUTPUT_MODE_INFORMATION {
 .Version		int32
 .HorizontalResolution	int32
 .VerticalResolution	int32
 .PixelFormat		int32
 .RedMask		int32
 .GreenMask		int32
 .BlueMask		int32
 .Reserved		int32
 .PixelsPerScanline	int32
}
struct EFI_GRAPHICS_OUTPUT_MODE_INFORMATION

EFI_UGA_DRAW_PROTOCOL_UUID equ 8bh,29h,2ch,98h,0fah,0f4h,0cbh,41h,0b8h,38h,77h,0aah,68h,8fh,0b8h,39h
struc EFI_UGA_DRAW_PROTOCOL {
 .GetMode		dptr
 .SetMode		dptr
 .Blt			dptr
}
struct EFI_UGA_DRAW_PROTOCOL

struc EFI_UGA_DRAW_PROTOCOL_GET_MODE {
 .This			dptr
 .HorizontalResolution	int32
 .VerticalResolution	int32
 .ColorDepth		int32
 .RefreshRate		int32
}
struct EFI_UGA_DRAW_PROTOCOL_GET_MODE
EFI_UGA_DRAW_PROTOCOL_SET_MODE equ EFI_UGA_DRAW_PROTOCOL_GET_MODE

struc EFI_UGA_PIXEL {
 .Blue			int8
 .Green			int8
 .Red			int8
 .Reserved		int8
}
struct EFI_UGA_PIXEL

struc EFI_UGA_DRAW_PROTOCOL_BLT {
 .This			dptr
 .BltBuffer		dptr
 .BltOperation		intn
 .SourceX		intn
 .SourceY		intn
 .DestinationX		intn
 .DestinationY		intn
 .Width			intn
 .Height		intn
 .Delta			intn
}
struct EFI_UGA_DRAW_PROTOCOL_BLT
EfiUgaVideoFill		equ 0
EfiUgaVideoToBltBuffer	equ 1
EfiUgaBltBufferToVideo	equ 2
EfiUgaVideoToVideo	equ 3
EfiUgaBltMax		equ 4

EFI_SERIAL_IO_PROTOCOL_UUID equ 6fh,0cfh,25h,0bbh,0d4h,0f1h,0d2h,11h,0ch,9ah,0,90h,27h,3fh,0c1h,0fdh
struc EFI_SERIAL_IO_PROTOCOL {
 .Revision		int32
 .Reset			dptr
 .SetAttributes		dptr
 .SetControl		dptr
 .GetControl		dptr
 .Write			dptr
 .Read			dptr
 .Mode			dptr
}
struct EFI_SERIAL_IO_PROTOCOL
