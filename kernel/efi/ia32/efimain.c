#include <efi.h>
#include <efilib.h>
#include <efiprot.h>
#include <stdio.h>

EFI_SYSTEM_TABLE         *ST;
EFI_BOOT_SERVICES        *BS;
EFI_RUNTIME_SERVICES     *RT;

EFI_GRAPHICS_OUTPUT_PROTOCOL *Gop;

unsigned int VideoMode;
unsigned int Width;
unsigned int Height;
unsigned int ScanLine;


void Clear(char *buf, int size)
{
    int i;

    for (i = 0; i < size; i++)
        buf[i] = 0;
}

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

void ShowMode(int Mode)
{
    unsigned int Size;
    EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *Info;
    char str[256];

    if (Gop->QueryMode(Gop, Mode, &Size, &Info) == EFI_SUCCESS)
    {
        if (Info->HorizontalResolution > Width)
        {
            VideoMode = Mode;
            Width = Info->HorizontalResolution;
            Height = Info->VerticalResolution;
            ScanLine = Info->PixelsPerScanLine;
        }
        
        Clear(str, 256);
        sprintf(str, "Mode %d: %dx%d, ", Mode, Info->HorizontalResolution, Info->VerticalResolution);
        Write(str);
        
        switch (Info->PixelFormat)
        {
            case PixelRedGreenBlueReserved8BitPerColor:
                ST->ConOut->OutputString(ST->ConOut, L"8-bit RGB\n\r");
                break;

            case PixelBlueGreenRedReserved8BitPerColor:
                ST->ConOut->OutputString(ST->ConOut, L"8-bit BGR\n\r");
                break;

            case PixelBitMask:
                ST->ConOut->OutputString(ST->ConOut, L"Bit mask\n\r");
                break;

            case PixelBltOnly:
                ST->ConOut->OutputString(ST->ConOut, L"Blit only\n\r");
                break;
        }
    }
}


EFI_STATUS InitGop()
{
    EFI_STATUS Status;
    void *Interface;
    char str[256];
    int i;

    Status = BS->LocateProtocol(&GopProtocol, 0, &Interface);

    if (EFI_ERROR(Status))
    {
        ST->ConOut->OutputString(ST->ConOut, L"GOP Not found\n\r");
        return Status;
    }

    Gop = (EFI_GRAPHICS_OUTPUT_PROTOCOL *)Interface;

    Clear(str, 256);
    sprintf(str, "GOP Mode: %d\n\r", Gop->Mode->Mode);
    Write(str);

    VideoMode = 0;
    Width = 0;
    Height = 0;

    for (i = 0; i <= Gop->Mode->MaxMode; i++)
        ShowMode(i);

    if (VideoMode)
    {
        Status = Gop->SetMode(Gop, VideoMode);

        if (EFI_ERROR(Status))
        {
            ST->ConOut->OutputString(ST->ConOut, L"GOP Mode Set Failed\n\r");
            return Status;
        }
    }

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
