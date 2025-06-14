//
// "00-NR7_v100.mq4" -- ID/NR7, Intra Day/Narrow Range 7
//
//    Ver. 1.00  2009/12/24(Thu)  initial version
//
//
#property  copyright "00mql4@gmail.com"
#property  link      "http://www.mql4.com/"

//---- defines

//---- indicator settings
#property  indicator_chart_window

#property  indicator_buffers  4

#property  indicator_color1  Aqua
#property  indicator_color2  Magenta
#property  indicator_color3  Aqua
#property  indicator_color4  Magenta

#property  indicator_width1  1
#property  indicator_width2  1
#property  indicator_width3  1
#property  indicator_width4  1

#property  indicator_style1  STYLE_SOLID
#property  indicator_style2  STYLE_SOLID
#property  indicator_style3  STYLE_SOLID
#property  indicator_style4  STYLE_SOLID

//---- indicator parameters
extern int  timeFrame  = PERIOD_D1;  // time frame
extern int  period     = 7;          // period
extern bool bIntra     = true;       // intra bar
extern int  nMaxBars   = 20000;      // maximum number of bars to calculate, 0: no limit

//---- indicator buffers
double BufferHi[];     // 0: NR7 high
double BufferLow[];    // 1: NR7 low
double BufferUpper[];  // 2: NR7 upper line
double BufferLower[];  // 3: NR7 lower line

//---- vars
string   sIndicatorName   = "";
string   sIndSelf         = "00-NR7_v100";

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
    sIndicatorName = sIndSelf + "(" + tf + "," + period + "," + bIntra + ")";
    
    IndicatorShortName(sIndicatorName);
    
    SetIndexBuffer(0, BufferHi);
    SetIndexBuffer(1, BufferLow);
    SetIndexBuffer(2, BufferUpper);
    SetIndexBuffer(3, BufferLower);
    
    SetIndexLabel(0, "NR7 Hi");
    SetIndexLabel(1, "NR7 Low");
    SetIndexLabel(2, "NR7 Upper");
    SetIndexLabel(3, "NR7 Lower");
    
    SetIndexStyle(0, DRAW_ARROW);
    SetIndexStyle(1, DRAW_ARROW);
    SetIndexStyle(2, DRAW_LINE);
    SetIndexStyle(3, DRAW_LINE);
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
	BufferHi[i]    = EMPTY_VALUE;
	BufferLow[i]   = EMPTY_VALUE;
	BufferUpper[i] = EMPTY_VALUE;
	BufferLower[i] = EMPTY_VALUE;
    }
    
    if (timeFrame != Period()) {
	// MTF
	limit = MathMax(limit, timeFrame / Period());
	for (i = limit - 1; i >= 0; i--) {
	    int x = iBarShift(NULL, timeFrame, Time[i]);
	    BufferHi[i]    = iCustom(NULL, timeFrame, sIndSelf, 0, period, bIntra, nMaxBars, 0, x);
	    BufferLow[i]   = iCustom(NULL, timeFrame, sIndSelf, 0, period, bIntra, nMaxBars, 1, x);
	    BufferUpper[i] = iCustom(NULL, timeFrame, sIndSelf, 0, period, bIntra, nMaxBars, 2, x);
	    BufferLower[i] = iCustom(NULL, timeFrame, sIndSelf, 0, period, bIntra, nMaxBars, 3, x);
	}
	for (i = limit - 1; i >= 0; i--) {
	    if (BufferUpper[i] == EMPTY_VALUE && (BufferUpper[i - 1] == EMPTY_VALUE || i == 0)) {
		BufferUpper[i] = BufferUpper[i + 1];
		BufferLower[i] = BufferLower[i + 1];
	    }
	}
	
	return;
    }
    
    // timeFrame == Period()
    for (i = limit - 1; i >= 0; i--) {
	int dow = TimeDayOfWeek(Time[i]);
	if (Period() == PERIOD_D1 && (dow == 0 || dow == 6)) {
	    continue;
	}
	double h = High[i] - Low[i];
	bool bNR7 = true;
	int k = 1;
	for (int j = 1; j < period * 2; j++) {
	    x = i + j;
	    dow = TimeDayOfWeek(Time[x]);
	    if (Period() == PERIOD_D1 && (dow == 0 || dow == 6)) {
		continue;
	    }
	    if (High[x] - Low[x] < h) {
		bNR7 = false;
		break;
	    }
	    k++;
	    if (k >= period) {
		break;
	    }
	}
	if (bNR7) {
	    x = i + 1;
	    if (Period() == PERIOD_D1) {
		dow = TimeDayOfWeek(Time[x]);
		if (dow == 0) {
		    x -= 2;
		} else if (dow == 6) {
		    x--;
		}
	    }
	    if (!bIntra || High[i] <= High[x] && Low[i] >= Low[x]) {
		BufferHi[i] = High[i];
		BufferLow[i] = Low[i];
		BufferUpper[i] = High[i];
		BufferLower[i] = Low[i];
	    }
	}
    }
    for (i = limit - 1; i >= 0; i--) {
	if (BufferUpper[i] == EMPTY_VALUE && (BufferUpper[i - 1] == EMPTY_VALUE || i == 0)) {
	    BufferUpper[i] = BufferUpper[i + 1];
	    BufferLower[i] = BufferLower[i + 1];
	}
    }
}
