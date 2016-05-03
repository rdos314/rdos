#include <efi.h>
#include <efilib.h>
#include <efiprot.h>
#include <stdio.h>

EFI_SYSTEM_TABLE         *ST;
EFI_BOOT_SERVICES        *BS;
EFI_RUNTIME_SERVICES     *RT;

EFI_GRAPHICS_OUTPUT_PROTOCOL *Gop;

void Write(const char *buf)
{
    int count = 0;
    CHAR16 str[] = { 0, 0 };

    while(buf[count])
    {
        str[0] = (CHAR16)buf[count];
                
        if(ST->ConOut->OutputString(ST->ConOut, str) == EFI_SUCCESS)
        {
            if(buf[count] == '\n')
            {
                str[0] = '\r';
                ST->ConOut->OutputString(ST->ConOut, str);
            }
            count++;
        }
        else
            break;
    }
}


EFI_STATUS InitGop()
{
    EFI_STATUS Status;
    void *Interface;
    char str[256];

    Status = BS->LocateProtocol(&GopProtocol, 0, &Interface);

    if (EFI_ERROR(Status))
    {
        ST->ConOut->OutputString(ST->ConOut, L"GOP Not found\n\r");
        return Status;
    }

    Gop = (EFI_GRAPHICS_OUTPUT_PROTOCOL *)Interface;

    sprintf(str, "GOP Mode: %d\n\r", Gop->Mode->Mode);
    Write(str);    

    sprintf(str, "LFB: %08hX (%08hX)\n\r", Gop->Mode->FrameBufferBase, Gop->Mode->FrameBufferSize);
    Write(str);    

    return Status;
}

 
EFI_STATUS efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    EFI_STATUS Status;
    EFI_INPUT_KEY Key;
 
    /* Store the system table for future use in other functions */
    ST = SystemTable;
    BS = SystemTable->BootServices;

    Status = InitGop();
    if (EFI_ERROR(Status))
        return Status;
 
    /* Say hi */
    Status = ST->ConOut->OutputString(ST->ConOut, L"Hello World\n\r");
    if (EFI_ERROR(Status))
        return Status;
 
    /* Now wait for a keystroke before continuing, otherwise your
       message will flash off the screen before you see it.
 
       First, we need to empty the console input buffer to flush
       out any keystrokes entered before this point */
    Status = ST->ConIn->Reset(ST->ConIn, FALSE);
    if (EFI_ERROR(Status))
        return Status;
 
    /* Now wait until a key becomes available.  This is a simple
       polling implementation.  You could try and use the WaitForKey
       event instead if you like */
    while ((Status = ST->ConIn->ReadKeyStroke(ST->ConIn, &Key)) == EFI_NOT_READY) ;
 
    return Status;
}
