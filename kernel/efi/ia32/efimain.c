#include <efi.h>
#include <efilib.h>
#include <efiprot.h>
#include <stdio.h>

EFI_SYSTEM_TABLE         *ST;
EFI_BOOT_SERVICES        *BS;
EFI_RUNTIME_SERVICES     *RT;

EFI_LOADED_IMAGE *Image;
FILEPATH_DEVICE_PATH *LoadedPath;
EFI_GRAPHICS_OUTPUT_PROTOCOL *Gop;

unsigned int VideoMode;
unsigned int Width;
unsigned int Height;
unsigned int ScanLine;
EFI_GRAPHICS_PIXEL_FORMAT PixelFormat;
EFI_PHYSICAL_ADDRESS LfbBase;
unsigned int LfbSize;

unsigned int FsCount;
EFI_FILE_IO_INTERFACE *Fs;
EFI_FILE_HANDLE Root;
char FsInfoData[1024];
EFI_FILE_SYSTEM_INFO *FsInfo;
EFI_FILE_INFO *FileInfo;

void *Interface;
EFI_HANDLE *FsArr;
char tempstr[256];
CHAR16 wstr[] = { 0, 0 };
EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *Info;
EFI_STATUS Status;



static void Clear()
{
    for (int i = 0; i < 256; i++)
        tempstr[i] = 0;
}

static void Write()
{
    int count = 0;

    while(tempstr[count])
    {
        wstr[0] = (CHAR16)tempstr[count];
                
        ST->ConOut->OutputString(ST->ConOut, wstr);
        count++;
    }
}

static void ShowUsedMode()
{        
    Clear();
    sprintf(tempstr, "GOP: %dx%d, ", Width, Height);
    Write();

    Clear();
        
    switch (PixelFormat)
    {
        case PixelRedGreenBlueReserved8BitPerColor:
            sprintf(tempstr, "8-bit RGB, ");
            break;

        case PixelBlueGreenRedReserved8BitPerColor:
            sprintf(tempstr, "8-bit BGR, ");
            break;

        case PixelBitMask:
            sprintf(tempstr, "Bit mask, ");
            break;

        case PixelBltOnly:
            sprintf(tempstr, "Blit only, ");
            break;
    }
    Write();

    Clear();
    sprintf(tempstr, "Base: %08lX, Size: %08lX\n\r", LfbBase, LfbSize);
    Write();
}


static void InitGop()
{
    Status = BS->LocateProtocol(&GopProtocol, 0, &Interface);

    if (EFI_ERROR(Status))
    {
        Clear();
        sprintf(tempstr, "GOP Not found\n\r");
        Write();
        return Status;
    }

    Gop = (EFI_GRAPHICS_OUTPUT_PROTOCOL *)Interface;

    Info = Gop->Mode->Info;
    Width = Info->HorizontalResolution;
    Height = Info->VerticalResolution;
    ScanLine = Info->PixelsPerScanLine;
    PixelFormat = Info->PixelFormat;

    LfbBase = Gop->Mode->FrameBufferBase;
    LfbSize = Gop->Mode->FrameBufferSize;

    ShowUsedMode();
}

static void GetFileInfo(EFI_FILE_HANDLE DirHandle)
{
    unsigned int Size = 1024;
    FileInfo = (EFI_FILE_INFO *)FsInfoData;

    if (DirHandle->GetInfo(DirHandle, &GenericFileInfo, &Size, FsInfoData) == EFI_SUCCESS)
    {
        Clear();
        sprintf(tempstr, "Path: <");
        Write();

        ST->ConOut->OutputString(ST->ConOut, FileInfo->FileName);

        Clear();
        sprintf(tempstr, ">\n\r");
        Write();
    }
}

static void GetFileSystemInfo(EFI_FILE_HANDLE DirHandle)
{
    unsigned int Size = 1024;
    FsInfo = (EFI_FILE_SYSTEM_INFO *)FsInfoData;

    if (DirHandle->GetInfo(DirHandle, &FileSystemInfo, &Size, FsInfoData) == EFI_SUCCESS)
    {
        Clear();
        sprintf(tempstr, "Volume label: <");
        Write();

        ST->ConOut->OutputString(ST->ConOut, FsInfo->VolumeLabel);

        Clear();
        sprintf(tempstr, ">\n\r");
        Write();
    }
}

static void GetFiles(EFI_FILE_HANDLE DirHandle)
{
    unsigned int Size = 1024;
    FileInfo = (EFI_FILE_INFO *)FsInfoData;

    DirHandle->SetPosition(DirHandle, 0);

    while (Size)
    {
        Size = 1024;
        
        if (DirHandle->Read(DirHandle, &Size, FsInfoData) == EFI_SUCCESS)
        {
            if (Size)
            {
                Clear();
                sprintf(tempstr, "Path: <");
                Write();

                ST->ConOut->OutputString(ST->ConOut, FileInfo->FileName);

                Clear();
                sprintf(tempstr, ">\n\r");
                Write();
            }
        }
    }
}

static void CheckFs(EFI_HANDLE handle)
{
    if (BS->HandleProtocol(handle, &FileSystemProtocol, &Interface) == EFI_SUCCESS)
    {
        Fs = (EFI_FILE_IO_INTERFACE*)Interface;

        if (Fs->OpenVolume(Fs, &Root) == EFI_SUCCESS)
        {
            GetFileSystemInfo(Root);
            GetFiles(Root);

            Root->Close(Root);
        }
    } 
}

static void InitFs()
{
    FsCount = 0;
    BS->LocateHandleBuffer(ByProtocol, &FileSystemProtocol, 0, &FsCount, &FsArr);
    
    Clear();
    sprintf(tempstr, "FS count: %d\n\r", FsCount);
    Write();

    for (unsigned int i = 0; i < FsCount; i++)
        CheckFs(FsArr[i]);
}

 
EFI_STATUS efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    EFI_INPUT_KEY Key;
 
    /* Store the system table for future use in other functions */
    ST = SystemTable;
    BS = SystemTable->BootServices;

    InitGop();

    if (EFI_ERROR(Status))
        return Status;

    Status = BS->HandleProtocol(ImageHandle, &LoadedImageProtocol, &Interface);
    if (EFI_ERROR(Status))
        return Status;

    Image = (EFI_LOADED_IMAGE *)Interface;

    if (Image->FilePath->Type == MEDIA_DEVICE_PATH && Image->FilePath->SubType == MEDIA_FILEPATH_DP)
    {
        LoadedPath = (FILEPATH_DEVICE_PATH *)Image->FilePath;

        Clear();
        sprintf(tempstr, "Loaded image :<");
        Write();

        ST->ConOut->OutputString(ST->ConOut, LoadedPath->PathName);

        Clear();
        sprintf(tempstr, ">\n\r");
        Write();

        CheckFs(Image->DeviceHandle);
    }
    else
        return -1;

//    InitFs();
  
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
