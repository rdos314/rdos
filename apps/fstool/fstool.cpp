#include <stdio.h>

#include "rdos.h"
#include "part.h"
#include "rdfspart.h"
#include "fatpart.h"

#define FALSE	0
#define TRUE	!FALSE

TDiscPartition *Part[2];

void ShowTreeTable(TPartitionTable *Part)
{
	int i;
	TPartition *Entry;
	const char *Name;
	int Typ;
	double Space;

	Space = Part->GetSpace();
	printf("%08lX-%08lX %15.3f MB\r\n",
			Part->Start,
			Part->Start + Part->Size - 1,
			Space);

	for (i = 0; i < 4; i++)
	{
		Entry = Part->PartArr[i];
		if (Entry)
		{
			Name = Entry->GetPartName();
			Typ = Entry->GetType();
			Space = Entry->GetSpace();

			if (Entry->IsFs() || Entry->IsTable())
				printf("%d: %02hX %08lX-%08lX %8s %15.3f MB\r\n",
						i,
						Typ,
						Entry->Start,
						Entry->Start + Entry->Size - 1,
						Name,
						Space);
			else
				printf("%d: No entry\r\n", i);

		}
	}

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
	{
		Entry = Part->PartArr[i];
		if (Entry)
		{
			if (Entry->IsFs())
				printf("%d: %02hX %08lX-%08lX %8s %15.3f MB\r\n",
						i,
						(unsigned int)Entry->GetType(),
						Entry->Start,
						Entry->Start + Entry->Size - 1,
						Entry->GetPartName(),
						Entry->GetSpace());
			else
				printf("%d: -- %08lX-%08lX %8s %15.3f MB\r\n",
						i,
						Entry->Start,
						Entry->Start + Entry->Size - 1,
						Entry->GetPartName(),
						Entry->GetSpace());
		}
	}
}

void cdecl main()
{
	int i;
	TFsPartitionFactory *factory;

	factory = new TRdfsPartitionFactory;
	factory = new TFat12PartitionFactory;
	factory = new TFat16PartitionFactory;
	factory = new TFat32PartitionFactory;

	for (i = 0; i < 2; i++)
		Part[i] = new TDiscPartition(i);

	 ShowTree(Part[0]);
	 ShowTree(Part[1]);
	 ShowTable(Part[0]);
	 ShowTable(Part[1]);

	 Part[0]->Delete(3);
	 Part[0]->Add("FAT16", 0x00100000);
}

