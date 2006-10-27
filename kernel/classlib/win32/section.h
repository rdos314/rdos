
#ifndef _SECTION_H
#define _SECTION_H

class TSection
{
public:
	TSection();
    ~TSection();
	void Enter() const;
	void Leave() const;
protected:
private:
	int FData[8];
	int FTask;
};

#endif


