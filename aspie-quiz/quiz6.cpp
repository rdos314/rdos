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
# quiz6.cpp
# Quiz 6 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quiz6.h"
#include "file.h"
#include "quizdb6.h"

#define MAX_IN_ROW		1024

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuiz6::TQuiz6
#
#   Purpose....: Constructor for TQuiz6
#
#   In params..: Filename to load quiz 6 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz6::TQuiz6(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5)
  : TQuiz(150),
	FDataFile(FileName)
{             
    DefineCross(0, QuizI);
    DefineCross(1, QuizII);
    DefineCross(2, QuizIII);
    DefineCross(3, QuizNd);
    DefineCross(4, Quiz5);

    SetupTexts();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	LoadPopulations();
    SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5);
    Calculate();
}

/*##########################################################################
#
#   Name       : TQuiz6::~TQuiz6
#
#   Purpose....: Destructor for TQuiz6
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz6::~TQuiz6()
{
}

/*##########################################################################
#
#   Name       : TQuiz6::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz6::WriteName(TFile &File)
{
    File.Write("6");
}

/*##########################################################################
#
#   Name       : TQuiz6::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz6::SetupTexts()
{
	Quiz[20].Reverse = TRUE;
	Quiz[21].Reverse = TRUE;
	Quiz[27].Reverse = TRUE;
	Quiz[29].Reverse = TRUE;
	Quiz[30].Reverse = TRUE;
	Quiz[35].Reverse = TRUE;
	Quiz[71].Reverse = TRUE;
	Quiz[72].Reverse = TRUE;
	Quiz[75].Reverse = TRUE;
	Quiz[77].Reverse = TRUE;
	Quiz[79].Reverse = TRUE;
	Quiz[83].Reverse = TRUE;
	Quiz[88].Reverse = TRUE;
	Quiz[89].Reverse = TRUE;
	Quiz[90].Reverse = TRUE;
	Quiz[91].Reverse = TRUE;
	Quiz[92].Reverse = TRUE;
	Quiz[93].Reverse = TRUE;
	Quiz[94].Reverse = TRUE;
	Quiz[95].Reverse = TRUE;
	Quiz[96].Reverse = TRUE;
	Quiz[97].Reverse = TRUE;
	Quiz[110].Reverse = TRUE;
	Quiz[112].Reverse = TRUE;
	Quiz[115].Reverse = TRUE;
	Quiz[116].Reverse = TRUE;
	Quiz[117].Reverse = TRUE;
	Quiz[119].Reverse = TRUE;
	Quiz[120].Reverse = TRUE;
	Quiz[129].Reverse = TRUE;
	Quiz[132].Reverse = TRUE;
	Quiz[134].Reverse = TRUE;
	Quiz[135].Reverse = TRUE;
	Quiz[138].Reverse = TRUE;
	Quiz[140].Reverse = TRUE;
	Quiz[141].Reverse = TRUE;

	Quiz[0].MyGroup = GROUP_SENSORY;
	Quiz[1].MyGroup = GROUP_SENSORY;
	Quiz[2].MyGroup = GROUP_SENSORY;
	Quiz[3].MyGroup = GROUP_SENSORY;
	Quiz[4].MyGroup = GROUP_SENSORY;
	Quiz[5].MyGroup = GROUP_SENSORY;
	Quiz[6].MyGroup = GROUP_SENSORY;
	Quiz[7].MyGroup = GROUP_SENSORY;
	Quiz[8].MyGroup = GROUP_SENSORY;
	Quiz[9].MyGroup = GROUP_SENSORY;
	Quiz[10].MyGroup = GROUP_SENSORY;
	Quiz[11].MyGroup = GROUP_SENSORY;
	Quiz[12].MyGroup = GROUP_MOTOR;
	Quiz[13].MyGroup = GROUP_MOTOR;
	Quiz[14].MyGroup = GROUP_MOTOR;
	Quiz[15].MyGroup = GROUP_MOTOR;
	Quiz[16].MyGroup = GROUP_MOTOR;
	Quiz[17].MyGroup = GROUP_MOTOR;
	Quiz[18].MyGroup = GROUP_NONVERBAL;
	Quiz[19].MyGroup = GROUP_NONVERBAL;
	Quiz[20].MyGroup = GROUP_NONVERBAL;
	Quiz[21].MyGroup = GROUP_NONVERBAL;
	Quiz[22].MyGroup = GROUP_NONVERBAL;
	Quiz[23].MyGroup = GROUP_NONVERBAL;
	Quiz[24].MyGroup = GROUP_NONVERBAL;
	Quiz[25].MyGroup = GROUP_NONVERBAL;
	Quiz[26].MyGroup = GROUP_NONVERBAL;
	Quiz[27].MyGroup = GROUP_NONVERBAL;
	Quiz[28].MyGroup = GROUP_NONVERBAL;
	Quiz[29].MyGroup = GROUP_NONVERBAL;
	Quiz[30].MyGroup = GROUP_NONVERBAL;
	Quiz[31].MyGroup = GROUP_NONVERBAL;
	Quiz[32].MyGroup = GROUP_NONVERBAL;
	Quiz[33].MyGroup = GROUP_NONVERBAL;
	Quiz[34].MyGroup = GROUP_NONVERBAL;
	Quiz[35].MyGroup = GROUP_NONVERBAL;
	Quiz[36].MyGroup = GROUP_NONVERBAL;
	Quiz[37].MyGroup = GROUP_NONVERBAL;
	Quiz[38].MyGroup = GROUP_NONVERBAL;
	Quiz[39].MyGroup = GROUP_NONVERBAL;
	Quiz[40].MyGroup = GROUP_FOCUS;
	Quiz[41].MyGroup = GROUP_FOCUS;
	Quiz[42].MyGroup = GROUP_FOCUS;
	Quiz[43].MyGroup = GROUP_FOCUS;
	Quiz[44].MyGroup = GROUP_FOCUS;
	Quiz[45].MyGroup = GROUP_FOCUS;
	Quiz[46].MyGroup = GROUP_FOCUS;
	Quiz[47].MyGroup = GROUP_FOCUS;
	Quiz[48].MyGroup = GROUP_FOCUS;
	Quiz[49].MyGroup = GROUP_FOCUS;
	Quiz[50].MyGroup = GROUP_FOCUS;
	Quiz[51].MyGroup = GROUP_FOCUS;
	Quiz[52].MyGroup = GROUP_FOCUS;
	Quiz[53].MyGroup = GROUP_REPETITION;
	Quiz[54].MyGroup = GROUP_REPETITION;
	Quiz[55].MyGroup = GROUP_REPETITION;
	Quiz[56].MyGroup = GROUP_REPETITION;
	Quiz[57].MyGroup = GROUP_REPETITION;
	Quiz[58].MyGroup = GROUP_REPETITION;
	Quiz[59].MyGroup = GROUP_REPETITION;
	Quiz[60].MyGroup = GROUP_REPETITION;
	Quiz[61].MyGroup = GROUP_REPETITION;
	Quiz[62].MyGroup = GROUP_REPETITION;
	Quiz[63].MyGroup = GROUP_REPETITION;
	Quiz[64].MyGroup = GROUP_SOCIAL;
	Quiz[65].MyGroup = GROUP_SOCIAL;
	Quiz[66].MyGroup = GROUP_SOCIAL;
	Quiz[67].MyGroup = GROUP_SOCIAL;
	Quiz[68].MyGroup = GROUP_SOCIAL;
	Quiz[69].MyGroup = GROUP_SOCIAL;
	Quiz[70].MyGroup = GROUP_SOCIAL;
	Quiz[71].MyGroup = GROUP_SOCIAL;
	Quiz[72].MyGroup = GROUP_SOCIAL;
	Quiz[73].MyGroup = GROUP_SOCIAL;
	Quiz[74].MyGroup = GROUP_SOCIAL;
	Quiz[75].MyGroup = GROUP_SOCIAL;
	Quiz[76].MyGroup = GROUP_SOCIAL;
	Quiz[77].MyGroup = GROUP_SOCIAL;
	Quiz[78].MyGroup = GROUP_SOCIAL;
	Quiz[79].MyGroup = GROUP_SOCIAL;
	Quiz[80].MyGroup = GROUP_SOCIAL;
	Quiz[81].MyGroup = GROUP_SOCIAL;
	Quiz[82].MyGroup = GROUP_SOCIAL;
	Quiz[83].MyGroup = GROUP_SOCIAL;
	Quiz[84].MyGroup = GROUP_SOCIAL;
	Quiz[85].MyGroup = GROUP_SOCIAL;
	Quiz[86].MyGroup = GROUP_SOCIAL;
	Quiz[87].MyGroup = GROUP_SOCIAL;
	Quiz[88].MyGroup = GROUP_NT_RELATION;
	Quiz[89].MyGroup = GROUP_NT_RELATION;
	Quiz[90].MyGroup = GROUP_NT_RELATION;
	Quiz[91].MyGroup = GROUP_NT_RELATION;
	Quiz[92].MyGroup = GROUP_NT_RELATION;
	Quiz[93].MyGroup = GROUP_NT_RELATION;
	Quiz[94].MyGroup = GROUP_NT_RELATION;
	Quiz[95].MyGroup = GROUP_NT_RELATION;
	Quiz[96].MyGroup = GROUP_NT_RELATION;
	Quiz[97].MyGroup = GROUP_NT_RELATION;
	Quiz[98].MyGroup = GROUP_MATH;
	Quiz[99].MyGroup = GROUP_MATH;
	Quiz[100].MyGroup = GROUP_MATH;
	Quiz[101].MyGroup = GROUP_MATH;
	Quiz[102].MyGroup = GROUP_MATH;
	Quiz[103].MyGroup = GROUP_MATH;
	Quiz[104].MyGroup = GROUP_MATH;
	Quiz[105].MyGroup = GROUP_MATH;
	Quiz[106].MyGroup = GROUP_MATH;
	Quiz[107].MyGroup = GROUP_MATH;
	Quiz[108].MyGroup = GROUP_MATH;
	Quiz[109].MyGroup = GROUP_INTROVERT;
	Quiz[110].MyGroup = GROUP_INTROVERT;
	Quiz[111].MyGroup = GROUP_INTROVERT;
	Quiz[112].MyGroup = GROUP_INTROVERT;
	Quiz[113].MyGroup = GROUP_INTROVERT;
	Quiz[114].MyGroup = GROUP_INTROVERT;
	Quiz[115].MyGroup = GROUP_INTROVERT;
	Quiz[116].MyGroup = GROUP_INTROVERT;
	Quiz[117].MyGroup = GROUP_INTROVERT;
	Quiz[118].MyGroup = GROUP_INTROVERT;
	Quiz[119].MyGroup = GROUP_INTROVERT;
	Quiz[120].MyGroup = GROUP_INTROVERT;
	Quiz[121].MyGroup = GROUP_SEX;
	Quiz[122].MyGroup = GROUP_SEX;
	Quiz[123].MyGroup = GROUP_MIXED;
	Quiz[124].MyGroup = GROUP_MIXED;
	Quiz[125].MyGroup = GROUP_MIXED;
	Quiz[126].MyGroup = GROUP_MIXED;
	Quiz[127].MyGroup = GROUP_MIXED;
	Quiz[128].MyGroup = GROUP_MIXED;
	Quiz[129].MyGroup = GROUP_MIXED;
	Quiz[130].MyGroup = GROUP_MIXED;
	Quiz[131].MyGroup = GROUP_MIXED;
	Quiz[132].MyGroup = GROUP_MIXED;
	Quiz[133].MyGroup = GROUP_MIXED;
	Quiz[134].MyGroup = GROUP_MIXED;
	Quiz[135].MyGroup = GROUP_MIXED;
	Quiz[136].MyGroup = GROUP_MIXED;
	Quiz[137].MyGroup = GROUP_MIXED;
	Quiz[138].MyGroup = GROUP_MIXED;
	Quiz[139].MyGroup = GROUP_MIXED;
	Quiz[140].MyGroup = GROUP_MIXED;
	Quiz[141].MyGroup = GROUP_MIXED;
	Quiz[142].MyGroup = GROUP_MIXED;
	Quiz[143].MyGroup = GROUP_MIXED;
	Quiz[144].MyGroup = GROUP_MIXED;
	Quiz[145].MyGroup = GROUP_MIXED;
	Quiz[146].MyGroup = GROUP_MIXED;
	Quiz[147].MyGroup = GROUP_MIXED;
	Quiz[148].MyGroup = GROUP_MIXED;
	Quiz[149].MyGroup = GROUP_MIXED;

#ifdef ENGLISH

	Quiz[0].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
	Quiz[1].Text = "Do you squint, or have done so in the past?";
	Quiz[2].Text = "Do certain phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
	Quiz[3].Text = "Do you have a very acute sense of smell and/or taste?";
	Quiz[4].Text = "Are you hyper- or hypo-sensitive to heat, cold, wind, humidity etc?";
	Quiz[5].Text = "Do you blink or roll your eyes?";
	Quiz[6].Text = "Are you irritated by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' textures/material?";
	Quiz[7].Text = "Do you stutter when stressed?";
	Quiz[8].Text = "Are you bothered by fluorescent light?";
	Quiz[9].Text = "Are you sensitive to electromagnetic fields?";
	Quiz[10].Text= "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
	Quiz[11].Text = "Do you sniff involuntary?";
	Quiz[12].Text = "Do you have difficulty throwing or catching a ball?";
	Quiz[13].Text = "Do you have a tendency to drop things?";
	Quiz[14].Text = "Are you the last one to finish manual tasks?";
	Quiz[15].Text = "Do you have difficulties judging distances, height, depth or speed?";
	Quiz[16].Text = "Do you have difficulty hopping, skipping or riding a bike?";
	Quiz[17].Text = "Are you accident prone?";
	Quiz[18].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
	Quiz[19].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
	Quiz[20].Text = "Do you have an intuitive sense for what is the right thing to do socially?";
	Quiz[21].Text = "Can you read between the lines?";
	Quiz[22].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
	Quiz[23].Text = "Do others often misunderstand you?";
	Quiz[24].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
	Quiz[25].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
	Quiz[26].Text = "Are you often surprised what people's motives are?";
	Quiz[27].Text = "Do you read people well?";
	Quiz[28].Text = "Do you forget you are in a social situation when something gets your attention?";
	Quiz[29].Text = "Can you spot hidden agendas with ease?";
	Quiz[30].Text = "Is it easy for you to interpret body language?";
	Quiz[31].Text = "Do you have an odd posture or gait?";
	Quiz[32].Text = "Have you taken initiative only to find out it was not wanted?";
	Quiz[33].Text = "Do you have difficulty summarizing and reporting conversations or describing events?";
	Quiz[34].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly informed?";
	Quiz[35].Text = "Are you intuitive about what people need from you?";
	Quiz[36].Text = "Do you have problems recognizing faces?";
	Quiz[37].Text = "Do people sometimes think you are smiling at the wrong occasion?";
	Quiz[38].Text = "Do you find it hard to tell the age of people?";
	Quiz[39].Text = "Do you self-stimulate (\"stim\") when bored, restless, nervous or upset, e.g. by bouncing a leg, tapping your fingers, biting your nails, waving your hands, rocking your body etc?";
	Quiz[40].Text = "Do you tend to get so absorbed in your projects that you forget everything else?";
	Quiz[41].Text = "Do you have unconventional, often unique ways of solving problems?";
	Quiz[42].Text = "Do you focus on one interest at a time and become an expert on that subject?";
	Quiz[43].Text = "Are you fascinated by dates and/or numbers?";
	Quiz[44].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
	Quiz[45].Text = "Do you have unusual imagination and unique ideas that others don't seem to have?";
	Quiz[46].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
	Quiz[47].Text = "Are you very gifted in one or more areas?";
	Quiz[48].Text = "Do you have one special talent which you have emphasised and worked on?";
	Quiz[49].Text = "Does it feel vitally important to be left undisturbed to persue your special interests?";
	Quiz[50].Text = "Do you consider yourself a very logical person?";
	Quiz[51].Text = "Do you like to figure out how things work?";
	Quiz[52].Text = "Do you have excellent vocabulary and/or a fascination with words?";
	Quiz[53].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed?";
	Quiz[54].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
	Quiz[55].Text = "Do you feel stress, panic or have a brain malfunction in unfamiliar or demanding situations?";
	Quiz[56].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
	Quiz[57].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
	Quiz[58].Text = "Do you have certain simple & logical routines which you need to follow?";
	Quiz[59].Text = "Do you have a need for comfort items like blankets, stuffed animals etc?";
	Quiz[60].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
	Quiz[61].Text = "Do you have obsessions or compulsions (repeated irresistible impulses to do certain things)?";
	Quiz[62].Text = "Do you have very strong attachments to certain objects?";
	Quiz[63].Text = "Have you experienced stronger than normal attachments to certain people?";
	Quiz[64].Text = "Do you find yourself at ease in romantic situations?";
	Quiz[65].Text = "Do you prefer animals to people?";
	Quiz[66].Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
	Quiz[67].Text = "Do you find it easier to communicate online than in real life?";
	Quiz[68].Text = "Do you feel awkward in romantic situations?";
	Quiz[69].Text = "Do you have difficulty compared to others your age in developing relationships and friendships?";
	Quiz[70].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
	Quiz[71].Text = "Are you good at party games?";
	Quiz[72].Text = "Do you find the usual courting behavior natural?";
	Quiz[73].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
	Quiz[74].Text = "Have you felt different from others for most of your life?";
	Quiz[75].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
	Quiz[76].Text = "Do you dislike being hugged when you haven't asked for it?";
	Quiz[77].Text = "Are you energised by being in the company of others?";
	Quiz[78].Text = "Do you tend to feel nervous, shy, confused and/or like you don't fit in, in various social situations?";
	Quiz[79].Text = "Do you enjoy team sports and group endeavours?";
	Quiz[80].Text = "Do you find social chitchat difficult, tiresome or a waste of time?";
	Quiz[81].Text = "Have you been bullied, abused or taken advantage of in various situations?";
	Quiz[82].Text = "Do you prefer to do things on your own?";
	Quiz[83].Text = "Do your friends mean more to you than hobbies and interests?";
	Quiz[84].Text = "Do you prefer to talk only when you have something relevant to say?";
	Quiz[85].Text = "Do you have an alternative view of what is attractive in the opposite sex compared to most others?";
	Quiz[86].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
	Quiz[87].Text = "Do you feel uncomfortable with strangers?";
	Quiz[88].Text = "Do you have an interest for fashions?";
	Quiz[89].Text = "Is your style and image important to you?";
	Quiz[90].Text = "Is creating a social identity important for you?";
	Quiz[91].Text = "Do you enjoy listening to gossip?";
	Quiz[92].Text = "Do you talk to put others at ease even when you really have nothing to say?";
	Quiz[93].Text = "Do you enjoy the status of a new car/new stereo/new TV?";
	Quiz[94].Text = "Is other people's image of you important to you?";
	Quiz[95].Text = "Is making a career important to you?";
	Quiz[96].Text = "Is a large social network important for you?";
	Quiz[97].Text = "Do you find it easy to maintain your social network?";
	Quiz[98].Text = "Do you have a poor concept of time?";
	Quiz[99].Text = "Do you find it difficult to read written material unless it is very interesting or very easy?";
	Quiz[100].Text= "Do you find it difficult to take notes in lectures?";
	Quiz[101].Text= "Do you have trouble reading clocks?";
	Quiz[102].Text= "Do you forget where you put things?";
	Quiz[103].Text= "Do you fail to carry a number through to the next part of the calculation?";
	Quiz[104].Text= "Do you often make spelling errors?";
	Quiz[105].Text= "Do you find it hard to recognise phone numbers when said in a different way?";
	Quiz[106].Text= "Do you have difficulty remembering scores during games?";
	Quiz[107].Text= "Are you a slow reader?";
	Quiz[108].Text= "Do you find it difficult to calculate change received from a purchase?";
	Quiz[109].Text= "Are you a better listener than talker?";
	Quiz[110].Text= "Are you the life of a party?";
	Quiz[111].Text= "Are you difficult to get to know?";
	Quiz[112].Text = "Are you a leader?";
	Quiz[113].Text = "Do you think before you act?";
	Quiz[114].Text = "Do you rather read a book than watch a movie?";
	Quiz[115].Text = "Are you easily embarrased?";
	Quiz[116].Text = "Do you cheer loudly at a sporting event or concert?";
	Quiz[117].Text = "Do you get bored by quitness?";
	Quiz[118].Text = "Do you get annoyed when people drop by to visit you?";
	Quiz[119].Text = "Are you prepared to do a lot of things for attention?";
	Quiz[120].Text = "Do you like to speak in public?";
	Quiz[121].Text = "Do you feel like you were born with the wrong gender?";
	Quiz[122].Text = "Do you have unusual sexual preferences?";
	Quiz[123].Text = "Do you have odd teeth; e.g. teeth that are crooked or bigger than usual; gaps; overlaps; underbite etc.?";
	Quiz[124].Text = "Are you flat-footed?";
	Quiz[125].Text = "Do you find instructions confusing - - especially several at the same time?";
	Quiz[126].Text = "Are you easily distracted or overwhelmed?";
	Quiz[127].Text = "Do you need to see, touch or do things yourself in order to remember them?";
	Quiz[128].Text = "Do you look, feel or act younger than your biological age?";
	Quiz[129].Text = "Do you know when you are expected to offer an apology?";
	Quiz[130].Text = "Do you find it very hard to learn things that you are not interested in?";
	Quiz[131].Text = "Do you get surprised and disappointed when people are unfriendly and don't seem to understand or accept you as you are?";
	Quiz[132].Text = "Do you get a firm feel for the big picture, before noticing details?";
	Quiz[133].Text = "Do you feel an urge to peel skin-flakes off yourself and /or others?";
	Quiz[134].Text = "Do you easily remember names?";
	Quiz[135].Text = "Are you gracious about criticism, correction and direction?";
	Quiz[136].Text = "Do you mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
	Quiz[137].Text = "Do you prefer romance/drama films to science fiction/documentary films?";
	Quiz[138].Text = "Do you enjoy having a variety of choices to make each day?";
	Quiz[139].Text = "Do you find the norms of hygiene too strict?";
	Quiz[140].Text = "Do you find it natural that males take initiatives to start a romantic relationship?";
	Quiz[141].Text = "Do you find it easy to describe your feelings and emotions to others?";
	Quiz[142].Text = "Do you often get depressed during winter-time?";
	Quiz[143].Text = "Do you find visualizing easy?";
	Quiz[144].Text = "Do you tend to shut one or both of your eyes in strong sun-light?";
	Quiz[145].Text = "Do you have a fascination for caves?";
	Quiz[146].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
	Quiz[147].Text = "Are you afraid of thunderstorms?";
	Quiz[148].Text = "Are you afraid of closed places?";
	Quiz[149].Text = "Are you afraid of the dark?";

#endif

#ifdef SWEDISH
	Quiz[0].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
	Quiz[1].Text = "Skelar du eller har gjort det?";
	Quiz[2].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
	Quiz[3].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
	Quiz[4].Text = "Är du över- eller underkänslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
	Quiz[5].Text = "Blinkar eller rullar du med ögonen?";
	Quiz[6].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt på vissa ställen eller som är gjorda av 'fel' material?";
	Quiz[7].Text = "Stammar du när du blir stressad?";
	Quiz[8].Text = "Är du känslig för vissa typer av ljus, t.ex lysrörsljus?";
	Quiz[9].Text = "Är du känslig för elektromagnetiska fält?";
	Quiz[10].Text= "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
	Quiz[11].Text = "Sniffar du ofrivilligt?";
	Quiz[12].Text = "Har du svårt för att kasta eller fånga en boll?";
	Quiz[13].Text = "Har du en tendens att tappa saker?";
	Quiz[14].Text = "Är du sist med att avsluta manuella uppgifter?";
	Quiz[15].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och hastighet?";
	Quiz[16].Text = "Har du svårt för att hoppa eller cykla?";
	Quiz[17].Text = "Skadar du dig ofta?";
	Quiz[18].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
	Quiz[19].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
	Quiz[20].Text = "Känner du intuitivt av vad som är rätt socialt?";
	Quiz[21].Text = "Kan du läsa mellan raderna?";
	Quiz[22].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
	Quiz[23].Text = "Missförstår andra ofta dig?";
	Quiz[24].Text = "Är du oftast omedveten om outtalade sociala regler?";
	Quiz[25].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
	Quiz[26].Text = "Blir du ofta överraskad av vad folks motiv är?";
	Quiz[27].Text = "Är du bra på att läsa av folk?";
	Quiz[28].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
	Quiz[29].Text = "Kan du lätt avslöja dolda motiv?";
	Quiz[30].Text = "Har du lätt för att tolka kroppsspråk?";
	Quiz[31].Text = "Har du ovanlig kroppshållning eller gångstil?";
	Quiz[32].Text = "Tar du initiativ som inte visar sig önskade?";
	Quiz[33].Text = "Har du problem med att redogöra för konversationer eller händelser och att sammanfatta?";
	Quiz[34].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
	Quiz[35].Text = "Känner du intuitivt av vad folk behöver från dig?";
	Quiz[36].Text = "Har du svårt att känna igen ansikten?";
	Quiz[37].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
	Quiz[38].Text = "Har du svårt för att bedöma andra människors ålder?";
	Quiz[39].Text = "Brukar du \"stimma\" när du känner dig uttråkad, rastlös, nervös eller upprörd, t ex genom att vippa på benet, trumma med fingrarna, bita på naglarna, vifta med händerna, gunga med kroppen el dyl?";
	Quiz[40].Text = "Brukar du bli så absorberad av dina projekt att du glömmer/struntar i allting annat?";
	Quiz[41].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
	Quiz[42].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert på det?";
	Quiz[43].Text = "Är du fascinerad av datum och/eller siffror?";
	Quiz[44].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
	Quiz[45].Text = "Har du ovanlig fantasi och unika idéer som andra inte verka ha?";
	Quiz[46].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
	Quiz[47].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
	Quiz[48].Text = "Har du en speciell talang som du har jobbat med?";
	Quiz[49].Text = "Känns det livsviktigt att få vara ifred och ägna dig åt dina specialintressen i lugn och ro?";
	Quiz[50].Text = "Anser du dig själv vara en väldigt logisk person?";
	Quiz[51].Text = "Tycker du om att lista ut hur saker fungerar?";
	Quiz[52].Text = "Har du utmärkt vokabulär och intresse för språk?";
	Quiz[53].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?";
	Quiz[54].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
	Quiz[55].Text = "Har du en tendens att lätt bli stressad och få panik eller kortslutning i hjärnan i nya och kravfyllda situationer?";
	Quiz[56].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
	Quiz[57].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
	Quiz[58].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
	Quiz[59].Text = "Har du behov av gosefilt, kramdjur eller liknande?";
	Quiz[60].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
	Quiz[61].Text = "Har du tvångssyndrom (= tvångstankar eller oemotståndliga, upprepade, irrationella impulser att göra vissa saker)?";
	Quiz[62].Text = "Är du exceptionellt fäst vid vissa saker?";
	Quiz[63].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
	Quiz[64].Text = "Trivs du med romantiska situationer?";
	Quiz[65].Text = "Umgås du hellre med djur än med människor?";
	Quiz[66].Text = "Tycker du det är lättare att förstå och kommunicera med udda & ovanliga människor än med vanliga människor?";
	Quiz[67].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
	Quiz[68].Text = "Känner du dig obekväm i romantiska situationer?";
	Quiz[69].Text = "Har du svårare än dina jämnåriga att få vänner och partners?";
	Quiz[70].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
	Quiz[71].Text = "Är du bra på sällskapsspel?";
	Quiz[72].Text = "Tycker du det normala sättet att uppvakta varandra är naturligt?";
	Quiz[73].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
	Quiz[74].Text = "Har du känt dig annorlunda största delen av ditt liv?";
	Quiz[75].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
	Quiz[76].Text = "Tycker du illa om att bli kramad när du inte bett om det?";
	Quiz[77].Text = "Får du energi av att vara i sällskap med andra?";
	Quiz[78].Text = "Brukar du bli nervös, blyg, förvirrad och/eller känna dig annorlunda och utanför i olika sociala situationer?";
	Quiz[79].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
	Quiz[80].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
	Quiz[81].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad i olika situationer?";
	Quiz[82].Text = "Föredrar du att göra saker på egen hand?";
	Quiz[83].Text = "Betyder vänner mer för dig än hobbies och intressen?";
	Quiz[84].Text = "Brukar du föredra att tala enbart när du har nåt relevant att säga?";
	Quiz[85].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet än vad många andra anser?";
	Quiz[86].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
	Quiz[87].Text = "Känner du dig obekväm bland främmande människor?";
	Quiz[88].Text = "Är du intressad av mode?";
	Quiz[89].Text = "Är din stil och image viktig för dig?";
	Quiz[90].Text = "Är det viktigt för dig att skapa en social identitet?";
	Quiz[91].Text = "Tycker du om att lyssna på skvaller?";
	Quiz[92].Text = "Pratar du för att andra ska känna sig väl till mods även om du inte har något att säga?";
	Quiz[93].Text = "Njuter du av den status som en ny bil/stereo/TV ger?";
	Quiz[94].Text = "Är andra människors syn på dig viktigt för dig?";
	Quiz[95].Text = "Är det viktigt för dig att göra karriär?";
	Quiz[96].Text = "Är ett stort socialt nätverk viktigt för dig?";
	Quiz[97].Text = "Tycker du det är lätt att underhålla ditt sociala nätverk?";
	Quiz[98].Text = "Har du dålig tidsuppfattning?";
	Quiz[99].Text = "Tycker du det är svårt att läsa skrivet material om det inte antingen är väldigt intressant eller lättläst?";
	Quiz[100].Text= "Har du svårt att göra anteckningar under lektioner?";
	Quiz[101].Text= "Har du svårigheter att läsa av klockor?";
	Quiz[102].Text= "Glömmer du var du lagt saker?";
	Quiz[103].Text= "För du över tal fel till nästa del i en beräkning?";
	Quiz[104].Text= "Gör du ofta stavfel?";
	Quiz[105].Text= "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
	Quiz[106].Text= "Har du svårt för att komma ihåg poängställningar under spel?";
	Quiz[107].Text= "Läser du sakta?";
	Quiz[108].Text= "Tycker du det är svårt att beräkna växel på ett köp?";
	Quiz[109].Text= "Är du en bättre lyssnare än talare?";
	Quiz[110].Text= "Är du aktiv på fester?";
	Quiz[111].Text= "Är du svår att lära känna?";
	Quiz[112].Text = "Är du en ledare?";
	Quiz[113].Text = "Tänker du innan du agerar?";
	Quiz[114].Text = "Läser du hellre en bok än tittar på en film?";
	Quiz[115].Text = "Blir du lätt generad?";
	Quiz[116].Text = "Är du högljudd på sportevenemang eller konserter?";
	Quiz[117].Text = "Blir du uttråkad när det är lugnt och tyst?";
	Quiz[118].Text = "Blir du irriterad när folk kommer på besök oanmälda?";
	Quiz[119].Text = "Gör du lite allt möjligt för uppmärksamhet?";
	Quiz[120].Text = "Tycker du om att tala offentligt?";
	Quiz[121].Text = "Känns det som du föddes med fel kön?";
	Quiz[122].Text = "Har du ovanliga sexuella preferenser?";
	Quiz[123].Text = "Har du udda tänder; t ex tänder som sitter snett, är större än vanligt; mellanrum mellan tänderna; tänder som klättrar på varandra; underbett etc.?";
	Quiz[124].Text = "Är du plattfot?";
	Quiz[125].Text = "Blir du förvirrad av instruktioner - särskilt flera på en gång?";
	Quiz[126].Text = "Blir du lätt distraherad eller överväldigad?";
	Quiz[127].Text = "Har du behov av att SE, ta i, eller själv bearbeta saker för att riktigt minnas dem?";
	Quiz[128].Text = "Ser du ut, uppträder eller agerar som om du vore yngre än din biologiska ålder?";
	Quiz[129].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
	Quiz[130].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
	Quiz[131].Text = "Blir du förvånad och besviken när folk är ovänliga och inte tycks förstå eller acceptera dig som du är?";
	Quiz[132].Text = "Tar du först in helheten innan du upptäcker detaljer?";
	Quiz[133].Text = "Känner du behov av att rycka loss hudflisor från dig själv (eller andra)?";
	Quiz[134].Text = "Kommer du lätt ihåg namn?";
	Quiz[135].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
	Quiz[136].Text = "Blandar du ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
	Quiz[137].Text = "Föredrar du filmer om romantik / drama före filmer om vetenskap/dokumentärer?";
	Quiz[138].Text = "Gillar du att ha många olika saker du kan göra varje dag?";
	Quiz[139].Text = "Tycker du att normerna för hygien är för strikta?";
	Quiz[140].Text = "Tycker du det är naturligt att män tar initiativ till att starta ett förhållande?";
	Quiz[141].Text = "Tycker du det är lätt att beskriva dina känslor för andra?";
	Quiz[142].Text = "Brukar du drabbas av depressioner under vintern?";
	Quiz[143].Text = "Har du lätt att visualisera och skapa bilder i huvudet?";
	Quiz[144].Text = "Blundar du gärna med ena eller bägge ögana i starkt solljus?";
	Quiz[145].Text = "Är du fascinerad av grottor?";
	Quiz[146].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
	Quiz[147].Text = "Är du rädd för åska?";
	Quiz[148].Text = "Är du rädd för att bli instängd?";
	Quiz[149].Text = "Är du mörkrädd?";

#endif
}

/*##########################################################################
#
#   Name       : TQuiz6::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz6::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("rdos.net/sv", "rdos.net/sv");
	AddReferer("kolozzeum.com", "kolozzeum.com/kolozzeum/showthread.php?t=65633");
	AddReferer("aspalsta.net", "aspalsta.net/viewtopic.php?t=1951");
	AddReferer("wikipedia.org/wiki/As", "en.wikipedia.org/wiki/Aspergers");
	AddReferer("whoa.nu", "whoa.nu");
	AddReferer("forum.rpg.net", "forum.rpg.net/showthread.php?t=268587");
	AddReferer("99musik.se", "99musik.se/forum/showthread.php?t=12719");
	AddReferer("ufs.fi", "forum.ufs.fi/showthread.php?t=1873");
 }

/*##################  TQuiz6::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz6::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
		{
			ref->Count++;
			ref->AsResult += Row.AsResult;
			ref->NtResult += Row.NtResult;

			if (Row.AsResult >= Row.NtResult)
			{
				if (Row.AsResult - Row.NtResult >= 50)
					ref->ResultHighAs++;
				else
					ref->ResultLowAs++;
			}
			else
				ref->ResultNt++;
		}

		ref = 0;

		if (Row.Autism == 1 || Row.Aspie == 1)
			ref = &SelfAsRef;

		if (Row.ADHD == 1)
			ref = &SelfAddRef;

		if (Row.Aspie == 2 || Row.Autism == 2)
			ref = &DxAsRef;

		if (Row.ADHD == 2)
			ref = &DxAddRef;

		if (ref)
		{
			ref->Count++;
			ref->AsResult += Row.AsResult;
			ref->NtResult += Row.NtResult;

			if (Row.AsResult >= Row.NtResult)
			{
				if (Row.AsResult - Row.NtResult >= 50)
					ref->ResultHighAs++;
				else
					ref->ResultLowAs++;
			}
			else
				ref->ResultNt++;
		}

		if (Row.Autism || Row.Aspie)
		{
			if (Row.Gender == 1)
				ref = &MaleAsRef;
			else
				ref = &FemaleAsRef;
		}

		if (ref)
		{
			ref->Count++;
			ref->AsResult += Row.AsResult;
			ref->NtResult += Row.NtResult;

			if (Row.AsResult >= Row.NtResult)
			{
				if (Row.AsResult - Row.NtResult >= 50)
					ref->ResultHighAs++;
				else
					ref->ResultLowAs++;
			}
			else
				ref->ResultNt++;
		}

	}
}

/*##########################################################################
#
#   Name       : TQuiz6::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz6::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	int aspie;

	for (i = 0; i < N; i++)
		Quiz[i].NoAnswer = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < N - 1; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;

		}

		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(aspie, Row.Quiz);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(aspie, Row.Quiz);

			if (Row.Gender == 1)
				AsMale.Add(aspie, Row.Quiz);
			else
				AsFemale.Add(aspie, Row.Quiz);

			if (Row.Autism == 2 || Row.Aspie == 2)
				As.Add(aspie, Row.Quiz);
		}

		if (!aspie && Row.ADHD)
		{
			Add.Add(aspie, Row.Quiz);
			if (Row.Gender == 1)
				AddMale.Add(aspie, Row.Quiz);
			else
				AddFemale.Add(aspie, Row.Quiz);
		}

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(aspie, Row.Quiz);
			if (Row.Gender == 1)
				MixMale.Add(aspie, Row.Quiz);
			else
				MixFemale.Add(aspie, Row.Quiz);
		}
		else
		{
			ref = FindReferer(Row.Referer);

			if (ref)
			{
				if (ref->NT && Row.Autism == 0 && Row.Aspie == 0)
				{
					Nt.Add(aspie, Row.Quiz);
					if (Row.Gender == 1)
						NtMale.Add(aspie, Row.Quiz);
					else
						NtFemale.Add(aspie, Row.Quiz);
				}

//                if (!aspie)
					aspie = ref->Aspie;
			}
		}


		if (aspie)
		{

			Aspie.Add(aspie, Row.Quiz);
			if (Row.Gender == 1)
				AspieMale.Add(aspie, Row.Quiz);
			else
				AspieFemale.Add(aspie, Row.Quiz);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuiz6::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz6::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("kolozzeum.com");
	DefineNt("rdos.net/sv");
	DefineNt("whoa.nu");
	DefineNt("99musik.se");
	DefineNt("ufs.fi");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("xmission.com/~winter");
	DefineAspie("delphiforums.com");
	DefineAspie("assupportgrouponline.co.uk");
}

/*##########################################################################
#
#   Name       : TQuiz6::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz6::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5)
{
	DefineCross(QuizIII, 0, 0);
	DefineCross(QuizIII, 1, 1);
	DefineCross(QuizNd, 2, 5);
	DefineCross(QuizNd, 3, 2);
	DefineCross(QuizNd, 4, 7);
	DefineCross(QuizNd, 5, 4);
	DefineCross(QuizNd, 6, 3);
	DefineCross(QuizNd, 7, 53);
	DefineCross(QuizNd, 8, 9);
	DefineCross(QuizNd, 9, 57);
	DefineCross(QuizNd, 10, 16);
	DefineCross(QuizNd, 11, 8);
	DefineCross(QuizNd, 12, 55);
	DefineCross(QuizNd, 13, 12);
	DefineCross(QuizNd, 14, 13);
	DefineCross(QuizNd, 15, 6);
	DefineCross(QuizNd, 16, 18);
	DefineCross(QuizNd, 17, 20);
	DefineCross(QuizNd, 18, 27);
	DefineCross(QuizNd, 19, 177);
	DefineCross(QuizNd, 20, 17);
	DefineCross(QuizNd, 21, 26);
	DefineCross(QuizNd, 22, 28);
	DefineCross(QuizNd, 23, 131);
	DefineCross(QuizNd, 24, 103);
	DefineCross(QuizNd, 25, 47);
	DefineCross(QuizNd, 26, 31);
	DefineCross(QuizNd, 27, 32);
	DefineCross(QuizNd, 28, 123);
	DefineCross(QuizNd, 29, 29);
	DefineCross(QuizNd, 30, 132);
	DefineCross(QuizNd, 31, 49);
	DefineCross(QuizNd, 32, 33);
	DefineCross(QuizNd, 33, 30);
	DefineCross(QuizNd, 34, 1);
	DefineCross(QuizNd, 35, 50);
	DefineCross(QuizNd, 36, 38);
	DefineCross(QuizNd, 37, 48);
	DefineCross(QuizNd, 38, 40);
	DefineCross(QuizNd, 39, 41);
	DefineCross(QuizNd, 40, 39);
	DefineCross(QuizNd, 41, 58);
	DefineCross(QuizNd, 42, 61);
	DefineCross(QuizNd, 43, 66);
	DefineCross(QuizNd, 44, 59);
	DefineCross(QuizNd, 45, 65);
	DefineCross(QuizNd, 46, 68);
	DefineCross(QuizNd, 47, 64);
	DefineCross(QuizNd, 48, 67);
	DefineCross(QuizNd, 49, 71);
	DefineCross(QuizIII, 50, 80);
	DefineCross(QuizIII, 51, 79);
	DefineCross(QuizI, 52, 27);
	DefineCross(QuizNd, 53, 87);
	DefineCross(QuizNd, 54, 82);
	DefineCross(QuizNd, 55, 78);
	DefineCross(QuizNd, 56, 83);
	DefineCross(QuizNd, 57, 77);
	DefineCross(QuizNd, 58, 91);
	DefineCross(QuizNd, 59, 195);
	DefineCross(QuizNd, 60, 126);
	DefineCross(QuizNd, 61, 127);
	DefineCross(QuizNd, 62, 93);
	DefineCross(QuizNd, 63, 124);
	DefineCross(QuizNd, 64, 112);
	DefineCross(QuizNd, 65, 92);
	DefineCross(QuizNd, 66, 113);
	DefineCross(QuizNd, 67, 129);
	DefineCross(QuizNd, 68, 137);
	DefineCross(QuizNd, 69, 97);
	DefineCross(QuizNd, 70, 98);
	DefineCross(QuizNd, 71, 99);
	DefineCross(QuizNd, 72, 101);
	DefineCross(QuizNd, 73, 120);
	DefineCross(QuizNd, 74, 108);
	DefineCross(QuizII, 75, 73);
	DefineCross(QuizIII, 76, 54);
	DefineCross(QuizIII, 77, 57);
	DefineCross(QuizNd, 78, 197);
	DefineCross(QuizNd, 79, 94);
	DefineCross(QuizIII, 80, 62);
	DefineCross(QuizIII, 81, 59);
	DefineCross(QuizNd, 82, 173);
	DefineCross(QuizNd, 83, 176);
	DefineCross(QuizNd, 84, 165);
	DefineCross(QuizNd, 85, 156);
	DefineCross(QuizNd, 86, 144);
	DefineCross(QuizNd, 87, 159);
	DefineCross(QuizNd, 88, 164);
	DefineCross(QuizNd, 89, 140);
	DefineCross(QuizNd, 90, 193);
	DefineCross(QuizNd, 91, 167);
	DefineCross(QuizNd, 92, 161);
	DefineCross(QuizNd, 93, 162);
	DefineCross(QuizNd, 94, 160);
	DefineCross(QuizNd, 95, 158);
	DefineCross(QuizNd, 96, 163);
	DefineCross(QuizNd, 97, 194);
	DefineCross(QuizNd, 98, 180);
	DefineCross(QuizNd, 99, 11);
	DefineCross(QuizNd, 100, 149);
	DefineCross(QuizNd, 101, 104);
	DefineCross(QuizNd, 102, 182);
	DefineCross(QuizNd, 103, 106);
	DefineCross(QuizNd, 104, 175);
	DefineCross(QuizNd, 105, 70);
	DefineCross(QuizNd, 106, 46);
	DefineCross(QuizNd, 107, 135);
	DefineCross(QuizNd, 108, 147);
	DefineCross(QuizNd, 109, 72);
	DefineCross(QuizNd, 110, 179);
	DefineCross(QuizNd, 111, 85);
}

/*##########################################################################
#
#   Name       : TQuiz6::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz6::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
		    pop->Add(FALSE, Row.Quiz);
}

/*##################  IsPca ##########################
*   Purpose....: Check quiz row against pca-type                 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int IsPca(TQuizRow *row, int PcaType)
{
    switch (PcaType)
	{
		case PCA_TYPE_ALL:
		case PCA_TYPE_MIXED:
            return TRUE;

        case PCA_TYPE_MALE:
			if (row->Gender == 1)
                return TRUE;
			else
                return FALSE;

        case PCA_TYPE_FEMALE:
			if (row->Gender == 2)
				return TRUE;
			else
                return FALSE;

        case PCA_TYPE_YOUNG:
			if (row->BirthYear >= 1980)
                return TRUE;
			else
				return FALSE;

		case PCA_TYPE_OLD:
			if (row->BirthYear <= 1965)
                return TRUE;
			else
				return FALSE;

        case PCA_TYPE_AS:
				if (row->Autism == 2 || row->Aspie == 2)
                return TRUE;
			else
                return FALSE;

    }
	return FALSE;
}

/*##################  TQuiz6::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz6::ExportExcelCase(const char *filename, int PcaType)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < N; i++)
	{
		if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
		{
			file.Write("\"");

//  	      strncpy(str, Quiz[i].Text, 35);
//      	  str[35] = 0;
			sprintf(str, "#%d", i + 1);
			file.Write(str);

			file.Write("\"");
			if (i != N - 1)
				file.Write(", ");
		}
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (IsPca(&Row, PcaType))
		{
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < N; i++)
			{
				if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
				{
					if (i == 112)
					{
						ival = 100 * (Row.Quiz[i] - 3) / 9;
						sprintf(str, "\"%d.%02d\"", ival / 100, ival % 100);
						file.Write(str);
					}
					else
					{
						ival = Row.Quiz[i];
						if (ival)
							ival--;

						if (ival > 2)
							ival = 0;

						sprintf(str, "\"%d\"", ival);
						file.Write(str);
						if (i != N - 1)
							file.Write(", ");
					}
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuiz6::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz6::ExportExcelGroups(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	int group;
	int ok;
	char str[80];
	TFile file(filename, 0);
	int GroupSum[GROUP_COUNT];
	int GroupCount[GROUP_COUNT];

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < GROUP_COUNT; i++)
	{
		file.Write("\"");

		strncpy(str, Group[i].Name, 35);
		str[35] = 0;
//        sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != GROUP_COUNT - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < GROUP_COUNT; i++)
		{
			GroupSum[i] = 0;
			GroupCount[i] = 0;
		}

		for (i = 0; i < N; i++)
		{
			ival = Row.Quiz[i];
			if (ival > 2 && i < 112)
				ival = 0;

			if (ival)
			{
				if (Quiz[i].Reverse)
					ival = 3 - ival;
				else
					ival--;
				group = Quiz[i].MyGroup;
				GroupSum[group] += ival;
				GroupCount[group]++;
			}
		}

		ok = TRUE;
		for (i = 0; i < GROUP_COUNT; i++)
			if (GroupCount[i] == 0)
				ok = FALSE;

		if (ok)
		{
			sprintf(str, "\%d\", ", Row.AsResult);
			file.Write(str);

				sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < GROUP_COUNT; i++)
			{
				ival = round(100.0 * (long double)GroupSum[i] / (long double)GroupCount[i]);
				sprintf(str, "\"%d\"", ival);
				file.Write(str);
				if (i != GROUP_COUNT - 1)
					file.Write(", ");
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuiz6::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz6::ImportMvsp(const char *filename, int PcaType)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int i;
	long double d1, d2;
	int q;
	int count;
	TFile infile(filename);

	while (size = infile.Read(buf, MAX_IN_ROW))
	{
		buf[size] = 0;
		rowstr = strstr(buf, "#");
		if (rowstr)
		{
			rowstr++;
			ptr = strstr(rowstr, "\r");
			if (ptr)
				 *ptr = 0;
			else
				 rowstr = 0;
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);

		if (rowstr)
		{
			for (i = 0; i < strlen(rowstr); i++)
			{
				switch (rowstr[i])
				{
					case ',':
						rowstr[i] = '.';
						break;

					case 0x9:
					case 0xd:
						rowstr[i] = ' ';
						break;
				}
			}

			if (sscanf(rowstr, "%d %Lf %Lf", &q, &d1, &d2) == 3)
			{
				if (PcaType != PCA_TYPE_MIXED)
				{
					if (PcaType == PCA_TYPE_FEMALE || PcaType == PCA_TYPE_ALL)
						d2 = -d2;

//					if (d1 > 0 && d2 > 0)
//					{
//						if (d1 > d2)
//						{
//							d1 = d1 - d2;
//							d2 = 0;
//						}
//						else
//						{
//							d2 = d2 - d1;
//							d1 = 0;
//						}
//					}
				}

				switch (PcaType)
				{
					case PCA_TYPE_ALL:
						Quiz[q - 1].Pca[0] = d1;
						Quiz[q - 1].Pca[1] = d2;
						break;

					case PCA_TYPE_MALE:
						Quiz[q - 1].MalePca[0] = d1;
						Quiz[q - 1].MalePca[1] = d2;
						break;

					case PCA_TYPE_FEMALE:
						Quiz[q - 1].FemalePca[0] = d1;
						Quiz[q - 1].FemalePca[1] = d2;
						break;

					case PCA_TYPE_YOUNG:
						Quiz[q - 1].YoungPca[0] = d1;
						Quiz[q - 1].YoungPca[1] = d2;
						break;

					case PCA_TYPE_OLD:
						Quiz[q - 1].OldPca[0] = d1;
						Quiz[q - 1].OldPca[1] = d2;
						break;

					case PCA_TYPE_AS:
						Quiz[q - 1].AsPca[0] = d1;
						Quiz[q - 1].AsPca[1] = d2;
						break;

					case PCA_TYPE_MIXED:
						Quiz[q - 1].MixedPca[0] = d1;
						Quiz[q - 1].MixedPca[1] = d2;
						break;
				}
			}
		}
	}
}
