
#ifndef _SECTION_H
#define _SECTION_H

class TSection
{
public:
	TSection();
    ~TSection();
	void Enter();
	void Leave();
protected:
private:
	int FData[8];
	int FTask;
};

#endif


