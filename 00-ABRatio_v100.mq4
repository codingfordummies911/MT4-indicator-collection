//
// "00-ABRatio_v100.mq4" -- Shinohara Ratio (a.k.a. KyouJaku Ratio)
//
//    Ver. 1.00  2009/01/04(Sun)  initial version
//
//
#property  copyright "00"
#property  link      "http://www.mql4.com/"

//---- defines

//---- indicator settings
#property  indicator_separate_window

#property indicator_minimum  0

#property indicator_level1  100

#property  indicator_buffers  6

#property  indicator_color1  Gray
#property  indicator_color2  Red
#property  indicator_color3  Gray
#property  indicator_color4  Red
#property  indicator_color5  DodgerBlue
#property  indicator_color6  Crimson

#property  indicator_width1  1
#property  indicator_width2  1
#property  indicator_width3  1
#property  indicator_width4  1
#property  indicator_width5  1
#property  indicator_width6  1

#property  indicator_style1  STYLE_SOLID
#property  indicator_style2  STYLE_SOLID
#property  indicator_style3  STYLE_DOT
#property  indicator_style4  STYLE_DOT
#property  indicator_style5  STYLE_SOLID
#property  indicator_style6  STYLE_SOLID

//---- indicator parameters
extern int    timeFrame     = 0;     // time frame
extern int    period        = 26;    // period
extern int    delay         = 2;     // prev bar for B ratio
extern double abMax         = 400;   // clip level
extern bool   bAlert        = true;  // alert
extern int    nMaxBars      = 2000;  // maximum number of bars to calculate, 0: no limit

//---- indicator buffers
double BufferALong[];   // 0: Macd, main
double BufferBLong[];   // 1: Macd, main
double BufferAShort[];        // 2: Macd, main
double BufferBShort[];        // 3: Macd, main
double BufferSignalLong[];    // 4: Macd, main
double BufferSignalShort[];   // 5: Macd, main

//---- vars
string   sIndicatorName = "";
string   sIndSelf       = "00-ABRatio_v100";
int      markLong       = 233;  
int      markShort      = 234;
datetime tAlertLast     = 0;

//----------------------------------------------------------------------
string TimeFrameToStr(int timeFrame)
{
    switch (timeFrame) {
    case 1:     return("M1");
    case 5:     return("M5");
    case 15:    return("M15");
    case 30:    return("M30");
    case 60:    return("H1");
    case 240:   return("H4");
    case 1440:  return("D1");
    case 10080: return("W1");
    case 43200: return("MN");
    }
    
    return("??");
}

//----------------------------------------------------------------------
void init()
{
    if (timeFrame == 0) {
	timeFrame = Period();
    }
    
    string tf = TimeFrameToStr(timeFrame);
    sIndicatorName = sIndSelf + "(" + tf + "," + period + ")";
    
    IndicatorShortName(sIndicatorName);
    
    SetIndexBuffer(0, BufferALong);
    SetIndexBuffer(1, BufferBLong);
    SetIndexBuffer(2, BufferAShort);
    SetIndexBuffer(3, BufferBShort);
    SetIndexBuffer(4, BufferSignalLong);
    SetIndexBuffer(5, BufferSignalShort);
    
    SetIndexLabel(0, "A Ratio, Long");
    SetIndexLabel(1, "B Ratio, Long");
    SetIndexLabel(2, "A Ratio, Short");
    SetIndexLabel(3, "B Ratio, Short");
    SetIndexLabel(4, "Long signal");
    SetIndexLabel(5, "Short signal");
	
    SetIndexStyle(0, DRAW_LINE);
    SetIndexStyle(1, DRAW_LINE);
    SetIndexStyle(2, DRAW_LINE);
    SetIndexStyle(3, DRAW_LINE);
    SetIndexStyle(4, DRAW_ARROW);
    SetIndexStyle(5, DRAW_ARROW);
    
    SetIndexArrow(4, markLong);
    SetIndexArrow(5, markShort);
    
    int n = 0;
    if (timeFrame == Period()) {
	n = period;
	if (nMaxBars > 0) {
	    n = MathMax(n, Bars - nMaxBars);
	}
    }
    SetIndexDrawBegin(0, n);
    SetIndexDrawBegin(1, n);
    SetIndexDrawBegin(2, n);
    SetIndexDrawBegin(3, n);
    SetIndexDrawBegin(4, n);
    SetIndexDrawBegin(5, n);
}

//----------------------------------------------------------------------
void start()
{
    int limit;
    int counted_bars = IndicatorCounted();
    
    if (counted_bars > 0) {
	counted_bars--;
    }
    
    limit = Bars - counted_bars;
    int limit0 = limit;
    if (nMaxBars > 0) {
	limit = MathMin(limit, nMaxBars);
    }
    
    // clear beyond limits
    for (int i = limit0 - 1; i >= limit; i--) {
	BufferALong[i]       = EMPTY_VALUE;
	BufferBLong[i]       = EMPTY_VALUE;
	BufferAShort[i]      = EMPTY_VALUE;
	BufferBShort[i]      = EMPTY_VALUE;
	BufferSignalLong[i]  = EMPTY_VALUE;
	BufferSignalShort[i] = EMPTY_VALUE;
    }
    
    if (timeFrame != Period()) {
	// MTF
	limit = MathMax(limit, timeFrame / Period());
	for (i = limit - 1; i >= 0; i--) {
	    int x = iBarShift(NULL, timeFrame, Time[i]);
	    BufferALong[i]       = iCustom(NULL, timeFrame, sIndSelf, 0, period, delay, abMax, bAlert, nMaxBars, 0, x);
	    BufferBLong[i]       = iCustom(NULL, timeFrame, sIndSelf, 0, period, delay, abMax, bAlert, nMaxBars, 1, x);
	    BufferAShort[i]      = iCustom(NULL, timeFrame, sIndSelf, 0, period, delay, abMax, bAlert, nMaxBars, 2, x);
	    BufferBShort[i]      = iCustom(NULL, timeFrame, sIndSelf, 0, period, delay, abMax, bAlert, nMaxBars, 3, x);
	    BufferSignalLong[i]  = iCustom(NULL, timeFrame, sIndSelf, 0, period, delay, abMax, bAlert, nMaxBars, 4, x);
	    BufferSignalShort[i] = iCustom(NULL, timeFrame, sIndSelf, 0, period, delay, abMax, bAlert, nMaxBars, 5, x);
	}
	
	// check alert
	if (bAlert) {
	    bool bFire = (BufferSignalLong[0] != EMPTY_VALUE || BufferSignalShort[0] != EMPTY_VALUE);
	    if (bFire && tAlertLast != Time[0]) {
		PlaySound("alert.wav");
		tAlertLast = Time[0];
	    }
	}
	
	return;
    }
    
    // timeFrame == Period()
    for (i = limit - 1; i >= 0; i--) {
	double aStrong = 0;
	double aWeak = 0;
	double bStrong = 0;
	double bWeak = 0;
	for (int j = 0; j < period; j++) {
	    x = i + j;
	    double close1 = Close[x + delay];
	    double open0  = Open[x];
	    double hi0    = High[x];
	    double lo0    = Low[x];
	    
	    aStrong += (hi0 - open0);
	    aWeak  += (open0 - lo0);
	    
	    bStrong += (hi0 - close1);
	    bWeak += (close1 - lo0);
	}
	
	double along = abMax;
	double blong = abMax;
	double ashort = abMax;
	double bshort = abMax;
	
	if (aWeak != 0) {
	    along = MathMin(MathAbs(aStrong / aWeak * 100.0), abMax);
	}
	if (bWeak != 0) {
	    blong = MathMin(MathAbs(bStrong / bWeak * 100.0), abMax);
	}
	
	if (aStrong != 0) {
	    ashort = MathMin(MathAbs(aWeak / aStrong * 100.0), abMax);
	}
	if (bStrong != 0) {
	    bshort = MathMin(MathAbs(bWeak / bStrong * 100.0), abMax);
	}
	
	BufferALong[i] = along;
	BufferBLong[i] = blong;
	BufferAShort[i] = ashort;
	BufferBShort[i] = bshort;
	
	double along4 = BufferALong[i + 4];
	double along3 = BufferALong[i + 3];
	double along2 = BufferALong[i + 2];
	double along1 = BufferALong[i + 1];
	
	double blong2 = BufferBLong[i + 2];
	double blong1 = BufferBLong[i + 1];
	
	if (along1 >= along4 || along1 >= along3 || along1 >= along2) {
	    if (blong2 < along2 && blong1 >= along1) {
		BufferSignalLong[i] = along1;
	    }
	}
	
	double ashort4 = BufferAShort[i + 4];
	double ashort3 = BufferAShort[i + 3];
	double ashort2 = BufferAShort[i + 2];
	double ashort1 = BufferAShort[i + 1];
	
	double bshort2 = BufferBShort[i + 2];
	double bshort1 = BufferBShort[i + 1];
	
	if (ashort1 >= ashort4 || ashort1 >= ashort3 || ashort1 >= ashort2) {
	    if (bshort2 < ashort2 && bshort1 >= ashort1) {
		BufferSignalShort[i] = ashort1;
	    }
	}
    }
    
    // check alert
    if (bAlert) {
	bFire = (BufferSignalLong[0] != EMPTY_VALUE || BufferSignalShort[0] != EMPTY_VALUE);
	if (bFire && tAlertLast != Time[0]) {
	    PlaySound("alert.wav");
	    tAlertLast = Time[0];
	}
    }
}
