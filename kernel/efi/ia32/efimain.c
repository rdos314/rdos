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
EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *Info;
EFI_STATUS Status;

char nbuf[32];


static void WriteChar(char ch)
{
    CHAR16 wstr[] = { 0, 0 };

    wstr[0] = (CHAR16)ch;            
    ST->ConOut->OutputString(ST->ConOut, wstr);
}


char const hex2ascii_data[] = "0123456789abcdefghijklmnopqrstuvwxyz";

#define hex2ascii(hex)  (hex2ascii_data[hex])
#define toupper(c)      ((c) - 0x20 * (((c) >= 'a') && ((c) <= 'z')))

static int strlen(const char *s)
{
    int l = 0;
    while (*s++)
        l++;
    return l;
}


static char *sprintn(char *nbuf, uintmax_t num, int base, int *lenp, int upper)
{
    char *p, c;

    p = nbuf;
    *p = '\0';
    do
    {
        c = hex2ascii(num % base);
        *++p = upper ? toupper(c) : c;
    }
    while (num /= base);

    if (lenp)
        *lenp = p - nbuf;
    return (p);
}

int printf(const char *fmt, ...)
{
    char *d;
    const char *p, *percent, *q;
    unsigned char *up;
    int radix = 10;
    int ch, n;
    uintmax_t num;
    int base, lflag, qflag, tmp, width, ladjust, sharpflag, neg, sign, dot;
    int cflag, hflag, jflag, tflag, zflag;
    int dwidth, upper;
    char padc;
    int stop = 0, retval = 0;
    va_list ap;

    va_start(ap, fmt);

    num = 0;

    if (fmt == NULL)
         fmt = "(fmt null)\n";

    for (;;)
    {
        padc = ' ';
        width = 0;
        while ((ch = (unsigned char)*fmt++) != '%' || stop)
        {
            if (ch == '\0')
                return (retval);
            WriteChar(ch);
        }
        percent = fmt - 1;
        qflag = 0; lflag = 0; ladjust = 0; sharpflag = 0; neg = 0;
        sign = 0; dot = 0; dwidth = 0; upper = 0;
        cflag = 0; hflag = 0; jflag = 0; tflag = 0; zflag = 0;
reswitch:
        switch (ch = (unsigned char)*fmt++)
        {
            case '.':
                dot = 1;
                goto reswitch;

            case '#':
                sharpflag = 1;
                goto reswitch;

            case '+':
                sign = 1;
                goto reswitch;

            case '-':
                ladjust = 1;
                goto reswitch;

            case '%':
                WriteChar(ch);
                break;

            case '*':
                if (!dot)
                {
                    width = va_arg(ap, int);
                    if (width < 0)
                    {
                        ladjust = !ladjust;
                        width = -width;
                    }
                }
                else
                    dwidth = va_arg(ap, int);
                goto reswitch;

            case '0':
                if (!dot)
                {
                    padc = '0';
                    goto reswitch;
                }

            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                for (n = 0;; ++fmt)
                {
                    n = n * 10 + ch - '0';
                    ch = *fmt;
                    if (ch < '0' || ch > '9')
                        break;
                }
                if (dot)
                    dwidth = n;
                else
                    width = n;
                goto reswitch;

            case 'b':
                num = (unsigned int)va_arg(ap, int);
                p = va_arg(ap, char *);
                for (q = sprintn(nbuf, num, *p++, NULL, 0); *q;)
                    WriteChar(*q--);

                if (num == 0)
                    break;

                for (tmp = 0; *p;)
                {
                    n = *p++;
                    if (num & (1 << (n - 1)))
                    {
                        WriteChar(tmp ? ',' : '<');
                        for (; (n = *p) > ' '; ++p)
                            WriteChar(n);
                        tmp = 1;
                    }
                    else
                        for (; *p > ' '; ++p)
                            continue;
                }
                if (tmp)
                    WriteChar('>');
                break;

            case 'c':
                WriteChar(va_arg(ap, int));
                break;

            case 'D':
                up = va_arg(ap, unsigned char *);
                p = va_arg(ap, char *);
                if (!width)
                    width = 16;
                while(width--)
                {
                    WriteChar(hex2ascii(*up >> 4));
                    WriteChar(hex2ascii(*up & 0x0f));
                    up++;
                    if (width)
                        for (q=p;*q;q++)
                            WriteChar(*q);
                }
                break;

            case 'd':
            case 'i':
                base = 10;
                sign = 1;
                goto handle_sign;

            case 'h':
                if (hflag)
                {
                    hflag = 0;
                    cflag = 1;
                }
                else
                    hflag = 1;
                goto reswitch;

            case 'j':
                jflag = 1;
                goto reswitch;

            case 'l':
                if (lflag)
                {
                    lflag = 0;
                    qflag = 1;
                }
                else
                    lflag = 1;
                goto reswitch;

            case 'n':
                if (jflag)
                    *(va_arg(ap, intmax_t *)) = retval;
                else if (qflag)
                    *(va_arg(ap, long long *)) = retval;
                else if (lflag)
                    *(va_arg(ap, long *)) = retval;
                else if (zflag)
                    *(va_arg(ap, int *)) = retval;
                else if (hflag)
                    *(va_arg(ap, short *)) = retval;
                else if (cflag)
                    *(va_arg(ap, char *)) = retval;
                else
                    *(va_arg(ap, int *)) = retval;
                break;

            case 'o':
                base = 8;
                goto handle_nosign;

            case 'p':
                base = 16;
                sharpflag = (width == 0);
                sign = 0;
                num = (uintptr_t)va_arg(ap, void *);
                goto number;

            case 'q':
                qflag = 1;
                goto reswitch;

            case 'r':
                base = radix;
                if (sign)
                    goto handle_sign;
                goto handle_nosign;

            case 's':
                p = va_arg(ap, char *);
                if (p == NULL)
                    p = "(null)";
                if (!dot)
                    n = strlen (p);
                else
                    for (n = 0; n < dwidth && p[n]; n++)
                        continue;

                width -= n;

                if (!ladjust && width > 0)
                    while (width--)
                        WriteChar(padc);
                    while (n--)
                        WriteChar(*p++);
                    if (ladjust && width > 0)
                        while (width--)
                            WriteChar(padc);
                break;

            case 't':
                tflag = 1;
                goto reswitch;

            case 'u':
                base = 10;
                goto handle_nosign;

            case 'X':
                upper = 1;

            case 'x':
                base = 16;
                goto handle_nosign;

            case 'y':
                base = 16;
                sign = 1;
                goto handle_sign;

            case 'z':
                zflag = 1;
                goto reswitch;

handle_nosign:
                sign = 0;
                if (jflag)
                    num = va_arg(ap, uintmax_t);
                else if (qflag)
                    num = va_arg(ap, unsigned long long);
                else if (tflag)
                    num = va_arg(ap, void *);
                else if (lflag)
                    num = va_arg(ap, unsigned long);
                else if (zflag)
                    num = va_arg(ap, int);
                else if (hflag)
                    num = (unsigned short int)va_arg(ap, int);
                else if (cflag)
                    num = (unsigned char)va_arg(ap, int);
                else
                    num = va_arg(ap, unsigned int);
                goto number;

handle_sign:
                if (jflag)
                    num = va_arg(ap, intmax_t);
                else if (qflag)
                    num = va_arg(ap, long long);
                else if (tflag)
                    num = va_arg(ap, void *);
                else if (lflag)
                    num = va_arg(ap, long);
                else if (hflag)
                    num = (short)va_arg(ap, int);
                else if (cflag)
                    num = (char)va_arg(ap, int);
                else
                    num = va_arg(ap, int);
number:
                if (sign && (intmax_t)num < 0)
                {
                    neg = 1;
                    num = -(intmax_t)num;
                }
                p = sprintn(nbuf, num, base, &tmp, upper);
                if (sharpflag && num != 0)
                {
                    if (base == 8)
                        tmp++;
                    else if (base == 16)
                        tmp += 2;
                }
                if (neg)
                    tmp++;

                if (!ladjust && padc != '0' && width && (width -= tmp) > 0)
                    while (width--)
                        WriteChar(padc);
                if (neg)
                        WriteChar('-');
                if (sharpflag && num != 0)
                {
                    if (base == 8)
                    {
                        WriteChar('0');
                    }
                    else if (base == 16)
                    {
                        WriteChar('0');
                        WriteChar('x');
                    }
                }
                if (!ladjust && width && (width -= tmp) > 0)
                    while (width--)
                        WriteChar(padc);

                while (*p)
                    WriteChar(*p--);

                if (ladjust && width && (width -= tmp) > 0)
                    while (width--)
                        WriteChar(padc);

                break;

            default:
                while (percent < fmt)
                    WriteChar(*percent++);
                stop = 1;
                break;
        }
    }
    va_end(ap);
    return 0;
}


static void ShowUsedMode()
{        
    printf("GOP: %dx%d, ", Width, Height);
        
    switch (PixelFormat)
    {
        case PixelRedGreenBlueReserved8BitPerColor:
            printf("8-bit RGB, ");
            break;

        case PixelBlueGreenRedReserved8BitPerColor:
            printf("8-bit BGR, ");
            break;

        case PixelBitMask:
            printf("Bit mask, ");
            break;

        case PixelBltOnly:
            printf("Blit only, ");
            break;
    }

    printf("Base: %08lX, Size: %08lX\n\r", LfbBase, LfbSize);
}


static void InitGop()
{
    Status = BS->LocateProtocol(&GopProtocol, 0, &Interface);

    if (EFI_ERROR(Status))
    {
        printf("GOP Not found\n\r");
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
        printf("Path: <");

        ST->ConOut->OutputString(ST->ConOut, FileInfo->FileName);

        printf(">\n\r");
    }
}

static void GetFileSystemInfo(EFI_FILE_HANDLE DirHandle)
{
    unsigned int Size = 1024;
    FsInfo = (EFI_FILE_SYSTEM_INFO *)FsInfoData;

    if (DirHandle->GetInfo(DirHandle, &FileSystemInfo, &Size, FsInfoData) == EFI_SUCCESS)
    {
        printf("Volume label: <");

        ST->ConOut->OutputString(ST->ConOut, FsInfo->VolumeLabel);

        printf(">\n\r");
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
                printf("Path: <");
                ST->ConOut->OutputString(ST->ConOut, FileInfo->FileName);
                printf(">\n\r");
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
    
    printf("FS count: %d\n\r", FsCount);

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

        printf("Loaded image :<");
        ST->ConOut->OutputString(ST->ConOut, LoadedPath->PathName);
        printf(">\n\r");

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
