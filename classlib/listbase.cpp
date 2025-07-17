/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# listbase.cpp
# List base class
#
########################################################################*/

#include <string.h>

#include "listbase.h"
#include "section.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TListBaseNode::TListBaseNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode::TListBaseNode()
{
    FData = 0;
    FNext = 0;
    FValid = FALSE;
}

/*##########################################################################
#
#   Name       : TListBaseNode::TListBaseNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode::TListBaseNode(const void *x, int size)
{
    FData = new TShareObject(x, size);
    FNext = 0;
    FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TListBaseNode::TListBaseNode
#
#   Purpose....: Copy constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode::TListBaseNode(const TListBaseNode &src)
{
    FData = new TShareObject(*src.FData);
    FNext = 0;
    FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TListBaseNode::~TListBaseNode
#
#   Purpose....: Destructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode::~TListBaseNode()
{
    if (FData)
        delete FData;
}

/*##########################################################################
#
#   Name       : TListBaseNode::IsValid
#
#   Purpose....: Check if valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBaseNode::IsValid() const
{
    return FValid;
}

/*##########################################################################
#
#   Name       : TListBaseNode::GetSize
#
#   Purpose....: Get size of data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBaseNode::GetSize() const
{
    if (FData)
        return FData->GetSize();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TListBaseNode::GetData
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const void *TListBaseNode::GetData() const
{
    if (FData)
        return FData->GetData();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TListBaseNode::SetData
#
#   Purpose....: Set data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBaseNode::SetData(const void *x, int size)
{
    if (FData)
        FData->SetData(x, size);
    else
        FData = new TShareObject(x, size);
    FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TListBase::TListBase
#
#   Purpose....: Constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBase::TListBase()
 : FSection("ListBase")
{
    Init();
}

/*##########################################################################
#
#   Name       : TListBase::TListBase
#
#   Purpose....: Copy constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBase::TListBase(const TListBase &src)
 : FSection("ListBase")
{
    TListBaseNode *p;

    Init();

    FSection.Enter();
    p = src.FList;

    while (p)
    {
        AddLast(src.Clone(p));
        p = p->FNext;
    }
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::~TListBase
#
#   Purpose....: Destructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBase::~TListBase()
{
    Clear();
}

/*##########################################################################
#
#   Name       : TListBase::Init
#
#   Purpose....: Init list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Init()
{
    FList = 0;
    FCurrPos = 0;
    FPrevPos = 0;
    FInvNext = 0;
}

/*##########################################################################
#
#   Name       : TListBase::Get
#
#   Purpose....: Get element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode *TListBase::Get(int pos)
{
    TListBaseNode *p;
    int n = 0;

    FSection.Enter();
    
    if (FList)
    {
        p = FList;

        while (p && n < pos)
        {
            p = p->FNext;
            n++;
        }
    }

    FSection.Leave();

    return p;
}

/*##########################################################################
#
#   Name       : TListBase::Compare
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::Compare(const TListBase &l) const
{
    TListBaseNode *p1;
    TListBaseNode *p2;
    int res;

    FSection.Enter();

    if (this == &l)
        res = 0;
    else
    {
        p1 = FList;
        p2 = l.FList;

        if (p1 && p2)
        {
            while (p1 && p2)
            {
                if (p1 == p2)
                {
                    res = 0;
                    break;
                }
                else
                {
                    res = p1->Compare(*p2);                 
                    if (res != 0)
                        break;
                }
                p1 = p1->FNext;
                p2 = p2->FNext;
            }
        }
        else
        {
            if (p1 == 0 && p2 == 0)
                res = 0;
            else
            {
                if (p1)
                    res = 1;
                else
                    res = -1;
            }
        }
    }
    FSection.Leave();

    return res;
}

/*##########################################################################
#
#   Name       : TListBase::Load
#
#   Purpose....: Load with other object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Load(const TListBase &src)
{
    TListBaseNode *p;
    
    Clear();    

    FSection.Enter();

    if (FList != src.FList)
    {
        p = src.FList;

        while (p)
        {
            AddLast(Clone(p));
            p = p->FNext;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::Clear
#
#   Purpose....: Clear list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Clear()
{
    TListBaseNode *p;

    FSection.Enter();

    while (FList)
    {
        p = FList;
        FList = FList->FNext;
        Remove(p);
        delete p;
    }
    Init();

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::Add
#
#   Purpose....: Add notify. Should be in critical section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Add(TListBaseNode *ln)
{
}

/*##########################################################################
#
#   Name       : TListBase::Remove
#
#   Purpose....: Remove notify. Should be in critical section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Remove(TListBaseNode *ln)
{
}

/*##########################################################################
#
#   Name       : TListBase::Update
#
#   Purpose....: Update notify. Should be in critical section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Update(TListBaseNode *ln)
{
}

/*##########################################################################
#
#   Name       : TListBase::RemoveOldest
#
#   Purpose....: Remove oldest entry. Should be in critical section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::RemoveOldest()
{
    TListBaseNode *p;
    TListBaseNode *prev;

    if (FList)
    {
        prev = 0;
        p = FList;
        while (p->FNext)
        {
            prev = p;
            p = p->FNext;
        }

        if (prev)
            prev->FNext = 0;    
        else
            FList = 0;

        Invalidate(p);
        Remove(p);
        delete p;
    }
}

/*##########################################################################
#
#   Name       : TListBase::IsEmpty
#
#   Purpose....: Check if list is empty
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::IsEmpty()
{
    if (FList)
        return FALSE;
    else
        return TRUE;
}

/*##########################################################################
#
#   Name       : TListBase::Invalidate
#
#   Purpose....: Invalidate pointers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Invalidate(TListBaseNode *ln)
{
    if (FCurrPos == ln)
    {
        if (FCurrPos)
            FInvNext = FCurrPos->FNext;
        FCurrPos = 0;
    }

    if (FPrevPos == ln)
        FPrevPos = 0;
}

/*##########################################################################
#
#   Name       : TListBase::AddFirst
#
#   Purpose....: Add entry as first entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::AddFirst(TListBaseNode *p)
{
    FSection.Enter();
    p->FNext = FList;
    FList = p;
    Add(p);
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::AddLast
#
#   Purpose....: Add entry as last entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::AddLast(TListBaseNode *p)
{
    TListBaseNode *tp;

    FSection.Enter();
    if (FList)
    {
        tp = FList;
        while (tp->FNext)
            tp = tp->FNext;

        tp->FNext = p;
    }
    else
        FList = p;
        
    p->FNext = 0;
    Add(p);
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::AddAt
#
#   Purpose....: Add entry at specified position, if possible.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::AddAt(int n, TListBaseNode *p)
{
    TListBaseNode *tp;
    int pos = 0;

    FSection.Enter();
    if (FList)
    {
        tp = FList;
        while (tp->FNext && pos < n)
        {
            pos++;
            tp = tp->FNext;
        }

        if (tp->FNext)
        {
            p->FNext = tp->FNext;
            tp->FNext = p;
        }
        else
        {
            tp->FNext = p;
            p->FNext = 0;
        }
    }
    else
    {
        FList = p;
        p->FNext = 0;
    }
    Add(p);
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::GetSize
#
#   Purpose....: Get # of elements in list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::GetSize()
{
    int n = 0;
    TListBaseNode *p;

    FSection.Enter();

    p = FList;

    while (p)
    {
        n++;
        p = p->FNext;
    }

    FSection.Leave();    

    return n;
}

/*##########################################################################
#
#   Name       : TListBase::GetPosition
#
#   Purpose....: Get current position in list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::GetPosition()
{
    int n = 0;
    TListBaseNode *p;

    FSection.Enter();

    p = FList;

    if (!FCurrPos && FInvNext)
    {
        FCurrPos = FInvNext;
        FInvNext = 0;
    }    

    if (FCurrPos)
    {
        while (p && p != FCurrPos)
        {
            n++;
            p = p->FNext;
        }
    }

    FSection.Leave();    

    return n;
}

/*##########################################################################
#
#   Name       : TListBase::GotoFirst
#
#   Purpose....: Goto first element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::GotoFirst()
{
    FSection.Enter();
    FCurrPos = FList;
    FPrevPos = 0;
    FInvNext = 0;
    FSection.Leave();
    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TListBase::GotoNext
#
#   Purpose....: Goto next element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::GotoNext()
{
    FSection.Enter();

    if (FCurrPos)
        FCurrPos = FCurrPos->FNext;
    else
        if (FInvNext)
        {
            FCurrPos = FInvNext;
            FInvNext = 0;
        }

    FSection.Leave();

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TListBase::GotoPrev
#
#   Purpose....: Goto previous element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::GotoPrev()
{
    TListBaseNode *p;
    
    FSection.Enter();

    if (FPrevPos && FPrevPos->FNext == FCurrPos)
    {
        FCurrPos = FPrevPos;
        FPrevPos = 0;
    }
    else
    {
        FPrevPos = 0;
        p = FList;

        while (p && p->FNext != FCurrPos) 
        {
            FPrevPos = p;
            p = p->FNext;
        }
        FCurrPos = p;
    }       

    FSection.Leave();    

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TListBase::GotoLast
#
#   Purpose....: Goto last element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::GotoLast()
{
    FSection.Enter();

    FInvNext = 0;
    FPrevPos = 0;
    FCurrPos = FList;

    while (FCurrPos && FCurrPos->FNext) 
    {
        FPrevPos = FCurrPos;
        FCurrPos = FCurrPos->FNext;
    }

    FSection.Leave();    

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TListBase::Goto
#
#   Purpose....: Goto n:th element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::Goto(int pos)
{
    int n = 0;

    FSection.Enter();

    FInvNext = 0;
    FCurrPos = FList;

    while (FCurrPos && n < pos)
    {
        n++;
        FCurrPos = FCurrPos->FNext;
    }

    FSection.Leave();    

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TListBase::Find
#
#   Purpose....: Find specific data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::Find(const TListBaseNode *ln)
{
    FSection.Enter();

    FInvNext = 0;
    FCurrPos = FList;

    while (FCurrPos && FCurrPos->Compare(*ln))                  
        FCurrPos = FCurrPos->FNext;

    FSection.Leave();    

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TListBase::RemoveFirst
#
#   Purpose....: Remove first entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::RemoveFirst()
{
    int success;
    TListBaseNode *p;

    FSection.Enter();

    if (FList)
    {
        p = FList;
        FList = FList->FNext;
        Invalidate(p);
        Remove(p);
        delete p;
        success = TRUE;

    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TListBase::RemoveLast
#
#   Purpose....: Remove last entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::RemoveLast()
{
    int success;
    TListBaseNode *p;
    TListBaseNode *prev;

    FSection.Enter();

    if (FList)
    {
        prev = 0;
        p = FList;
        while (p->FNext)
        {
            prev = p;
            p = p->FNext;
        }

        if (prev)
            prev->FNext = 0;    
        else
            FList = 0;

        Invalidate(p);
        Remove(p);
        delete p;
        
        success = TRUE;
    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TListBase::RemoveCurrent
#
#   Purpose....: Remove current entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::RemoveCurrent()
{
    int success;
    TListBaseNode *p;
    TListBaseNode *prev;

    FSection.Enter();

    if (FList && FCurrPos)
    {
        prev = 0;
        p = FList;
        while (p && p != FCurrPos)
        {
            prev = p;
            p = p->FNext;
        }

        if (p)
        {
            if (prev)
                prev->FNext = p->FNext;    
            else
                FList = p->FNext;

            Invalidate(p);
            Remove(p);
            delete p;
            
            success = TRUE;
        }
        else
            success = FALSE;
    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TListBase::Remove
#
#   Purpose....: Remove specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::Remove(int pos)
{
    int success;
    TListBaseNode *p;
    TListBaseNode *prev;
    int n = 0;

    FSection.Enter();

    if (FList)
    {
        prev = 0;
        p = FList;
        while (p && n < pos)
        {
            n++;
            prev = p;
            p = p->FNext;
        }

        if (p)
        {
            if (prev)
                prev->FNext = p->FNext;    
            else
                FList = p->FNext;

            Invalidate(p);
            Remove(p);
            delete p;
            
            success = TRUE;
        }
        else
            success = FALSE;
    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TListBase::ReplaceCurrent
#
#   Purpose....: Replace current entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::ReplaceCurrent(const TListBaseNode *newln)
{
    int success;
    TListBaseNode *p;
    TListBaseNode *prev;

    FSection.Enter();

    if (FList && FCurrPos)
    {
        prev = 0;
        p = FList;
        while (p && p != FCurrPos)
        {
            prev = p;
            p = p->FNext;
        }

        if (p)
        {
            p->Load(*newln);
            Update(p);
            success = TRUE;
        }
        else
            success = FALSE;
    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TListBase::Replace
#
#   Purpose....: Replace specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListBase::Replace(int pos, const TListBaseNode *newln)
{
    int success;
    TListBaseNode *p;
    int n = 0;

    FSection.Enter();

    if (FList)
    {
        p = FList;
        while (p && n < pos)
        {
            n++;
            p = p->FNext;
        }

        if (p)
        {
            p->Load(*newln);
            Update(p);
            success = TRUE;
        }
        else
            success = FALSE;
    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TListBase::Concat
#
#   Purpose....: Concat in this list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Concat(const TListBase &list1, const TListBase& list2)
{
    TListBaseNode *p;

    Clear();
    FSection.Enter();

    p = list1.FList;

    while (p)
    {
        AddLast(Clone(p));
        p = p->FNext;
    }

    p = list2.FList;

    while (p)
    {
        AddLast(Clone(p));
        p = p->FNext;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::Intersect
#
#   Purpose....: Intersection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Intersect(const TListBase &list1, const TListBase& list2)
{
    TListBaseNode *p1;
    TListBaseNode *p2;

    Clear();
    FSection.Enter();

    p1 = list1.FList;

    while (p1)
    {

        p2 = list2.FList;

        while (p2 && p1->Compare(*p2))
            p2 = p2->FNext;

        if (p2)
            AddLast(Clone(p1));
            
        p1 = p1->FNext;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::Union
#
#   Purpose....: Union
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Union(const TListBase &list1, const TListBase& list2)
{
    TListBaseNode *p1;
    TListBaseNode *p2;

    Clear();

    FSection.Enter();

    p1 = list1.FList;

    while (p1)
    {
        AddLast(Clone(p1));
        p1 = p1->FNext;
    }

    p2 = list2.FList;

    while (p2)
    {

        p1 = list1.FList;

        while (p1 && p1->Compare(*p2))
            p1 = p1->FNext;

        if (!p1)
            AddLast(Clone(p2));
            
        p2 = p2->FNext;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::Difference
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Difference(const TListBase &list1, const TListBase& list2)
{
    TListBaseNode *p1;
    TListBaseNode *p2;

    Clear();

    FSection.Enter();

    p1 = list1.FList;

    while (p1)
    {

        p2 = list2.FList;

        while (p2 && p1->Compare(*p2))
            p2 = p2->FNext;

        if (!p2)
            AddLast(Clone(p1));
            
        p1 = p1->FNext;
    }

    p2 = list2.FList;

    while (p2)
    {

        p1 = list1.FList;

        while (p1 && p1->Compare(*p2))
            p1 = p1->FNext;

        if (!p1)
            AddLast(Clone(p2));
            
        p2 = p2->FNext;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::Reverse
#
#   Purpose....: Reverse list in place
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::Reverse()
{
    TListBaseNode *p;
    TListBaseNode *tp;

    FSection.Enter();

    p = FList;
    Init();

    while (p)
    {
        tp = p->FNext;
        p->FNext = FList;
        FList = p;
        p = tp;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TListBase::RemoveDuplicates
#
#   Purpose....: Remove duplicates from list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListBase::RemoveDuplicates()
{
    TListBaseNode *p;
    TListBaseNode *tp;
    TListBaseNode *insp;
    TListBaseNode *np;

    FSection.Enter();

    p = FList;
    Init();
    insp = 0;

    while (p)
    {
        np = p->FNext;
        
        tp = FList;
        while (tp && tp->Compare(*p))
            tp = tp->FNext;

        if (tp)
        {
            Remove(p);
            delete p;
        }
        else
        {
            if (insp)
                insp->FNext = p;
            else
                FList = p;

            p->FNext = 0;                
            insp = p;
        }

        p = np;
    }

    FSection.Leave();
}
