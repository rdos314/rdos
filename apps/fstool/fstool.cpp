#include <stdio.h>

#include "rdos.h"
#include "part.h"
#include "rdfspart.h"
#include "fatpart.h"
#include "ffspart.h"

#define FALSE	0
#define TRUE	!FALSE

TDiscPartition *Part[2];

void ShowEntry(int Nr, TPartition *Entry)
{
	const char *Name;
	int Typ;
	double TotalSpace;
	double FreeSpace;
	int Drive;
	char DriveStr[4];
	
	if (Entry)
	{
		Name = Entry->GetPartName();
		Typ = Entry->GetType();
		TotalSpace = Entry->GetTotalSpace();

		if (Entry->Size)
		{
		    if (Entry->IsFs())
		        Drive = Entry->GetDrive();
		    else
		        Drive = 0;

			if (Drive)
			{
			    DriveStr[0] = 'A' + (char)Drive;
			    DriveStr[1] = ':';
			    DriveStr[2] = 0;
			      
			    FreeSpace = Entry->GetFreeSpace();
			        
    		    printf("%d: %s %02hX %08lX-%08lX %8s %15.3f MB %15.3f MB\r\n",
	    				Nr,
							DriveStr,
    					Typ,
	    				Entry->Start,
		    			Entry->Start + Entry->Size - 1,
			    		Name,
				    	TotalSpace,
				    	FreeSpace);
			}
			else
				printf("%d: -- %02hX %08lX-%08lX %8s %15.3f MB\r\n",
					    Nr,
						Typ,
						Entry->Start,
    					Entry->Start + Entry->Size - 1,
	    				Name,
		    			TotalSpace);
		}
		else
			printf("%d: -- No entry\r\n", Nr);

	}
}

void ShowTreeTable(TPartitionTable *Part)
{
	int i;
	TPartition *Entry;
   double TotalSpace;

	TotalSpace = Part->GetTotalSpace();
	printf("%08lX-%08lX %15.3f MB\r\n",
			Part->Start,
			Part->Start + Part->Size - 1,
			TotalSpace);

	for (i = 0; i < 4; i++)
	    ShowEntry(i, Part->PartArr[i]);

	for (i = 0; i < 4; i++)
	{
		Entry = Part->PartArr[i];
		if (Entry)
			if (Entry->IsTable())
				ShowTreeTable((TPartitionTable *)Entry);
	}
}

void ShowTree(TDiscPartition *Part)
{
	printf("\r\nDisc %d\r\n", Part->GetDisc());
	if (Part->PartRoot)
		ShowTreeTable(Part->PartRoot);
}

void ShowTable(TDiscPartition *Part)
{
	int i;
	TPartition *Entry;
	int BytesPerSector;
	long Sectors;
	int SectorsPerCyl;
	int Heads;

	RdosGetDiscInfo(Part->GetDisc(), &BytesPerSector, &Sectors, &SectorsPerCyl, &Heads);

	printf("\r\nDisc %d %08lX BIOS sectors / cyl %04X, heads %04X\r\n", Part->GetDisc(), Sectors, SectorsPerCyl, Heads);
	for (i = 0; i < Part->PartCount; i++)
	    ShowEntry(i, Part->PartArr[i]);
}

void cdecl main()
{
	int i;
	TFsPartitionFactory *factory;

	factory = new TRdfsPartitionFactory;
	factory = new TFat12PartitionFactory;
	factory = new TFat16PartitionFactory;
	factory = new TFat32PartitionFactory;
   factory = new TFlashFsPartitionFactory;

	for (i = 0; i < 2; i++)
		Part[i] = new TDiscPartition(i);

	 ShowTree(Part[0]);
	 ShowTree(Part[1]);
	 ShowTable(Part[0]);
	 ShowTable(Part[1]);
}
