/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# direntry.cpp
# Directory entry class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include "direntry.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

TDirEntry EmptyDir;

/*##########################################################################
#
#   Name       : TDirEntryData::TDirEntryData
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntryData::TDirEntryData()
{
    FileSize = 0;
    Attribute = 0;
}

/*##########################################################################
#
#   Name       : TDirEntryData::~TDirEntryData
#
#   Purpose....: destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntryData::~TDirEntryData()
{
}

/*##########################################################################
#
#   Name       : TDirEntry::TDirEntry
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::TDirEntry(const TPathName &PathName, const TString &EntryName, const TDateTime &Time, long FileSize, int Attribute)
{
    AllocBuffer(sizeof(TDirEntryData));
    FEntry = (TDirEntryData *)FData;

    FEntry->PathName = PathName;
    FEntry->EntryName = EntryName;
    FEntry->FileSize = FileSize;
    FEntry->Attribute = Attribute;
    FEntry->Time = Time;
}

/*##########################################################################
#
#   Name       : TDirEntry::TDirEntry
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::TDirEntry()
{
}

/*##########################################################################
#
#   Name       : TDirEntry::TDirEntry
#
#   Purpose....: copy constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::TDirEntry(const TDirEntry &src)
 : TShareObject(src)
{
    FEntry = src.FEntry;
}

/*##########################################################################
#
#   Name       : TDirEntry::~TDirEntry
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::~TDirEntry()
{
}

/*##########################################################################
#
#   Name       : TDirEntry::Create
#
#   Purpose....: Create data object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShareObjectData *TDirEntry::Create(int size)
{
	return new TDirEntryData();
}

/*##########################################################################
#
#   Name       : TDirEntry::Destroy
#
#   Purpose....: Destroy data object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirEntry::Destroy(TShareObjectData *obj)
{
	TDirEntryData *dirent = (TDirEntryData *)obj;
	delete dirent;
}

/*##########################################################################
#
#   Name       : TDirEntry::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDirEntry &TDirEntry::operator=(const TDirEntry &src)
{
    Load(src);
    FEntry = src.FEntry;
	return *this;
}

/*##########################################################################
#
#   Name       : TDirEntry::Get
#
#   Purpose....: Get data object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDirEntryData &TDirEntry::Get() const
{
    return *FEntry;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetPathName
#
#   Purpose....: Get pathname
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TPathName &TDirEntry::GetPathName() const
{
    return FEntry->PathName;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetEntryName
#
#   Purpose....: Get entry name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TString &TDirEntry::GetEntryName() const
{
    return FEntry->EntryName;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetFileSize
#
#   Purpose....: Get file size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long TDirEntry::GetFileSize() const
{
    return FEntry->FileSize;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetAttribute
#
#   Purpose....: Get file attribute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirEntry::GetAttribute() const
{
    return FEntry->Attribute;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetTime
#
#   Purpose....: Get entry time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDateTime &TDirEntry::GetTime() const
{
    return FEntry->Time;
}

/*##########################################################################
#
#   Name       : TDirEntry::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirEntry::Compare(const TDirEntry &n2) const
{
    return TShareObject::Compare(n2);
}

/*##########################################################################
#
#   Name       : TDirListNode::TDirListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode::TDirListNode()
{
    FEntry = 0;
}

/*##########################################################################
#
#   Name       : TDirListNode::TDirListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode::TDirListNode(const TDirEntry &entry)
{
 	FEntry = new TDirEntry(entry);
	FData = FEntry;
	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TDirListNode::TDirListNode
#
#   Purpose....: Copy constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode::TDirListNode(const TDirListNode &src)
{
	FEntry = new TDirEntry(*src.FEntry);
	FData = FEntry;
	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TDirListNode::~TDirListNode
#
#   Purpose....: Destructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode::~TDirListNode()
{
}

/*##########################################################################
#
#   Name       : TDirListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::Compare(const TDirListNode &n2) const
{
	if (FEntry && n2.FEntry)
		return FEntry->Compare(*n2.FEntry);
	else
	{
		if (FEntry || n2.FEntry)
		{
			if (FEntry)
				return 1;
			else
				return -1;
		}
		else
			return 0;
	}
}

/*##########################################################################
#
#   Name       : TDirListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::Compare(const TListBaseNode &n2) const
{
    TDirListNode *p = (TDirListNode *)&n2;
    return Compare(*p);    
}

/*##########################################################################
#
#   Name       : TDirListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirListNode::Load(const TDirListNode &src)
{
	if (FEntry)
		*FEntry = *src.FEntry;
	else
	{
		if (src.FEntry)
			FEntry = new TDirEntry(*src.FEntry);
	}
	FData = FEntry;
	FValid = src.FValid;
}

/*##########################################################################
#
#   Name       : TDirListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirListNode::Load(const TListBaseNode &src)
{
	TDirListNode *p = (TDirListNode *)&src;
	Load(*p);
}

/*##########################################################################
#
#   Name       : TDirListNode::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDirListNode &TDirListNode::operator=(const TDirListNode &src)
{
	Load(src);
	return *this;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator==
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator==(const TDirListNode &ln) const
{
	if (Compare(ln) == 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator!=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator!=(const TDirListNode &ln) const
{
	if (Compare(ln) == 0)
		return FALSE;
	else
		return TRUE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator>
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator>(const TDirListNode &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator<
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator<(const TDirListNode &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator>=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator>=(const TDirListNode &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator<=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator<=(const TDirListNode &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::Get
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry &TDirListNode::Get() const
{
	return *FEntry;
}

/*##########################################################################
#
#   Name       : TDirListNode::Set
#
#   Purpose....: Set data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirListNode::Set(TDirEntry &entry)
{
	if (FEntry)
		*FEntry = entry;
	else
	{
		FEntry = new TDirEntry(entry);
		FData = FEntry;
	} 
	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList()
  : FPathName("")
{
	SetDefaultAttributes();
	DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList(const char *PathName)
  : FPathName(PathName)
{
	SetDefaultAttributes();
	DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList(const TString &PathName)
  : FPathName(PathName)
{
	SetDefaultAttributes();
	DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList(const TPathName &PathName)
  : FPathName(PathName.Get())
{
	SetDefaultAttributes();
	DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: Copy constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList(const TDirList &source)
  : TListBase(source),
    FPathName(source.FPathName)
{
    FAttribIgnored = source.FAttribIgnored;
    FAttribRequired = source.FAttribRequired;
}

/*##########################################################################
#
#   Name       : TDirList::~TDirList
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::~TDirList()
{
}

/*##########################################################################
#
#   Name       : TDirList::SetDefaultAttributes
#
#   Purpose....: Set default attribute to match against
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::SetDefaultAttributes()
{
    FAttribIgnored = FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM;
    FAttribRequired = 0;
}

/*##########################################################################
#
#   Name       : TDirList::SetRequiredAttributes
#
#   Purpose....: Set required match attributes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::SetRequiredAttributes(int attrib)
{
    FAttribRequired = attrib;
}

/*##########################################################################
#
#   Name       : TDirList::SetIgnoredAttributes
#
#   Purpose....: Set ignored match attributes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::SetIgnoredAttributes(int attrib)
{
    FAttribIgnored = attrib;
}

/*##########################################################################
#
#   Name       : TDirList::Add
#
#   Purpose....: Add entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::Add(const char *PathName)
{
	FPathName = TString(PathName);
    DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::Add
#
#   Purpose....: Add entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::Add(const TString &PathName)
{
    FPathName = PathName;
    DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::Add
#
#   Purpose....: Add entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::Add(const TPathName &PathName)
{
    FPathName = PathName.Get();
    DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::CheckAttrib
#
#   Purpose....: Check if attribute matches
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::CheckAttrib(int attrib)
{
    if (attrib & FAttribIgnored)
        return FALSE;

    if ((attrib & FAttribRequired) == FAttribRequired)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::IsMatch
#
#   Purpose....: Check if file matches search criteria
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::IsMatch(const char *FileName)
{
	TString FileStr(FileName);
	TString SearchStr(FSearchString);
	const char *FilePtr;
	const char *SearchPtr;
	char ch;
	const char *LastFilePtr = 0;
	const char *LastSearchPtr = 0;

	FileStr.Upper();
	SearchStr.Upper();

	if (SearchStr.GetSize() == 0)
		return TRUE;

	FilePtr = FileStr.GetData();
	SearchPtr = SearchStr.GetData();

	if (!strcmp(SearchPtr, "*.*"))
		return TRUE;

	if (!strcmp(SearchPtr, "*."))
	{
		if (strchr(FilePtr, '.'))
			return FALSE;
		else
			return TRUE;
	}

	for (;;)
	{
		while (*SearchPtr && *FilePtr)
		{
			switch (*SearchPtr)
			{
				case '*':
					ch = *(SearchPtr + 1);
					if (ch)
					{
						if (ch == *FilePtr)
						{
							LastSearchPtr = SearchPtr;
							SearchPtr += 2;
							FilePtr++;
							LastFilePtr = FilePtr;
						}
						else
							FilePtr++;
					}
					else
						FilePtr++;
					break;
	
				case '?':
					SearchPtr++;
					FilePtr++;
					break;

				default:
					if (*SearchPtr == *FilePtr)
					{
						SearchPtr++;
						FilePtr++;
					}
					else
					{
						if (LastFilePtr)
						{
							FilePtr = LastFilePtr;
							SearchPtr = LastSearchPtr;
							LastFilePtr = 0;
							LastSearchPtr = 0;
						}
						else
							return FALSE;
					}
					break;
			}
		}

		if (*SearchPtr == 0 && *FilePtr == 0)
			return TRUE;
		else
		{
			if (*SearchPtr == '*' && *(SearchPtr+1) == 0)
				return TRUE;

			if (LastFilePtr)
			{
				FilePtr = LastFilePtr;
				SearchPtr = LastSearchPtr;
				LastFilePtr = 0;
				LastSearchPtr = 0;
			}
			else
				return FALSE;
		}
	}
}

/*##########################################################################
#
#   Name       : TDirList::Add
#
#   Purpose....: Add entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::Add(const char *Name, unsigned long msb, unsigned long lsb, long FileSize, int Attrib)
{
    TString Entry(Name);
	TPathName Path(FBaseString);
	Path += Entry;
    TDateTime Time(msb, lsb);
    TDirEntry entry(Path, Entry, Time, FileSize, Attrib);
	TDirListNode *p = new TDirListNode(entry);
	TListBase::AddFirst(p);
}

/*##########################################################################
#
#   Name       : TDirList::DoSearch
#
#   Purpose....: Do a new search
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::DoSearch()
{
    char *Name;
    long FileSize;
    int Attrib;
	unsigned long msb;
	unsigned long lsb;
	int ok;
	int DirHandle;
	int Index;
	
	if (FPathName.IsDir())
	{
		FBaseString = FPathName.Get();
		FSearchString = "*";
	}
	else
	{
		FBaseString = FPathName.GetBaseName();
		FSearchString = FPathName.GetEntryName();

		if (FBaseString.GetSize() == 0)
			FBaseString = ".";

		if (FSearchString.GetSize() == 0)
			FSearchString = "*";
	}

	DirHandle = RdosOpenDir(FBaseString.GetData());
    Index = 0;

    if (DirHandle)
    {
        Name = new char[512];

		ok = TRUE;
		while (ok)
		{
	        ok = RdosReadDir(DirHandle, Index, 512, Name, &FileSize, &Attrib, &msb, &lsb);
			if (ok)
			{
        		Index++;
				if (CheckAttrib(Attrib) && IsMatch(Name))
				    Add(Name, msb, lsb, FileSize, Attrib);
			}
        }
        delete Name;

        RdosCloseDir(DirHandle);
    }
}

/*##########################################################################
#
#   Name       : TDirList::operator==
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator==(const TDirList &l) const
{
    if (Compare(l) == 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator!=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator!= (const TDirList &l) const
{
    if (Compare(l) != 0)
        return TRUE;
    else
        return FALSE;
}    

/*##########################################################################
#
#   Name       : TDirList::operator>
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator>(const TDirList &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator<
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator<(const TDirList &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator>=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator>=(const TDirList &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator<=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator<=(const TDirList &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator=(const TDirList &src)
{
	Load(src);
	FPathName = src.FPathName;
	FAttribIgnored = src.FAttribIgnored;
    FAttribRequired = src.FAttribRequired;
    
    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator+=
#
#   Purpose....: Concat operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator+=(const TDirList &l)
{
	TDirList list;
	list.Concat(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator&=
#
#   Purpose....: Intersec operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator&=(const TDirList &l)
{
	TDirList list;
	list.Intersect(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator|=
#
#   Purpose....: Union operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator|=(const TDirList &l)
{
	TDirList list;
	list.Union(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator^=
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator^=(const TDirList &l)
{
	TDirList list;
	list.Difference(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator[]
#
#   Purpose....: Vector operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry &TDirList::operator[](int pos)
{
	TDirListNode *p = (TDirListNode *)TListBase::Get(pos);

	if (p->IsValid())
		return p->Get();
	else
		return EmptyDir;
}

/*##########################################################################
#
#   Name       : TDirList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode *TDirList::Clone(const TDirListNode *ln) const
{
	return new TDirListNode(*ln);
}

/*##########################################################################
#
#   Name       : TDirList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode *TDirList::Clone(const TListBaseNode *ln) const
{
    TDirListNode *p = (TDirListNode *)ln;
	return new TDirListNode(*p);
}

/*##########################################################################
#
#   Name       : operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList operator+(const TDirList &list1, const TDirList& list2)
{
	TDirList list;
    list.Concat(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : operator&
#
#   Purpose....: Intersection operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList operator&(const TDirList &list1, const TDirList& list2)
{
	TDirList list;
    list.Intersect(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : operator|
#
#   Purpose....: Union operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList operator|(const TDirList &list1, const TDirList& list2)
{
	TDirList list;
    list.Union(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : operator^
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList operator^(const TDirList &list1, const TDirList& list2)
{
	TDirList list;
    list.Difference(list1, list2);
    return list;
}
