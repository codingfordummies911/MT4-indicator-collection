//
// "00-Sig-ABRatio_v103.mq4" -- Shinohara Ratio (a.k.a. KyouJaku Ratio)
//
//    Ver. 1.00  2009/01/04(Sun)  initial version
// 
#property  copyright "00 - 00mql4@gmail.com"
#property  link      "http://www.mql4.com/"

//---- indicator settings
#property  indicator_chart_window

#property  indicator_buffers  2

#property  indicator_color1  DodgerBlue
#property  indicator_color2  Crimson

#property  indicator_width1  1
#property  indicator_width2  1

//---- indicator parameters
/*extern*/ int nStopLossRange   = 3;   // draw S/L line in last N bars min/max
/*extern*/ int nBarAfterSignal  = 10;  // length of S/L line
//
/*extern*/ string sHelp0 = "--- params for \"00-ABRatio\"";
/*extern*/ string sIndABRatio  = "00-ABRatio_v100";  // indicator name
extern int    timeFrame     = 0;     // time frame
extern int    period        = 26;    // period
extern int    delay         = 2;     // prev bar for B ratio
extern double abMax         = 400;   // clip level
extern bool   bAlert        = true;  // alert
extern int    nMaxBars      = 2000;  // maximum number of bars to calculate, 0: no limit
/*extern*/ string sHelp1 = "--- end of params for \"00-ABRatio\"";
//
/*extern*/ double point     = 0.0;         // point value
/*extern*/ color  colLong   = DodgerBlue;  // color for long lines
/*extern*/ color  colShort  = Crimson;     // color for short lines

//---- indicator buffers
double BufferLong[];   // 0: long signal
double BufferShort[];  // 2: short signal

//---- vars
string   sIndicatorName = "";
string   sIndSelf       = "00-Sig-ABRatio_v100";
string   sPrefix        = "";
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
    
    sPrefix = sIndicatorName;
    
    IndicatorShortName(sIndicatorName);
    
    SetIndexBuffer(0, BufferLong);
    SetIndexBuffer(1, BufferShort);
    
    SetIndexLabel(0, "Long signal");
    SetIndexLabel(1, "Short signal");
    
    SetIndexStyle(0, DRAW_ARROW);
    SetIndexStyle(1, DRAW_ARROW);
    
    SetIndexArrow(0, markLong);
    SetIndexArrow(1, markShort);
    
    int n = 0;
    if (timeFrame == Period()) {
	n = period;
	if (nMaxBars > 0) {
	    n = MathMax(n, Bars - nMaxBars);
	}
    }
    SetIndexDrawBegin(0, n);
    SetIndexDrawBegin(1, n);
    
    if (point == 0.0) {
	point = Point;
    }
}

//----------------------------------------------------------------------
void deinit()
{
    int n = ObjectsTotal();
    for (int i = n - 1; i >= 0; i--) {
	string sName = ObjectName(i);
	if (StringFind(sName, sPrefix) == 0) {
	    ObjectDelete(sName);
	}
    }
}

//----------------------------------------------------------------------
void objLine(string sName, datetime ts, double ps, datetime te, double pe, color col,
	     int width = 1, int style = STYLE_SOLID, bool bBack = true, bool bRay = false)
{
    ObjectCreate(sName, OBJ_TREND, 0, 0, 0, 0);
    ObjectSet(sName, OBJPROP_TIME1,  ts);
    ObjectSet(sName, OBJPROP_PRICE1, ps);
    ObjectSet(sName, OBJPROP_TIME2,  te);
    ObjectSet(sName, OBJPROP_PRICE2, pe);
    ObjectSet(sName, OBJPROP_COLOR, col);
    ObjectSet(sName, OBJPROP_WIDTH, width);
    ObjectSet(sName, OBJPROP_STYLE, style);
    ObjectSet(sName, OBJPROP_BACK, bBack);
    ObjectSet(sName, OBJPROP_RAY, bRay);
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
    
    double ofst = 3 * point;
    
    // clear beyond limits
    for (int i = limit0 - 1; i >= limit; i--) {
	BufferLong[i]  = EMPTY_VALUE;
	BufferShort[i] = EMPTY_VALUE;
    }
    
    for (i = limit - 1; i >= 0; i--) {
	BufferLong[i]  = EMPTY_VALUE;
	BufferShort[i] = EMPTY_VALUE;
	
	double bufLong  = iCustom(NULL, 0, sIndABRatio, timeFrame, period, delay, abMax, false, nMaxBars, 4, i);
	double bufShort = iCustom(NULL, 0, sIndABRatio, timeFrame, period, delay, abMax, false, nMaxBars, 5, i);
	bool bLong = false;
	bool bShort = false;
	
	// long
	if (bufLong != EMPTY_VALUE) {
	    bLong = true;
	    BufferLong[i] = Low[i] - ofst;
	}
	
	// short
	if (bufShort != EMPTY_VALUE) {
	    bShort = true;
	    BufferShort[i] = High[i] + ofst;
	}
	
	bool bFire = (bLong || bShort);
	
	if (bFire) {
	    if (nStopLossRange > 0) {
		string sNameStopLossH = sPrefix + Time[i] + " SL H";
		string sNameStopLossV = sPrefix + Time[i] + " SL V";
		datetime t0 = Time[i];
		datetime ts = Time[i + nStopLossRange];
		datetime te = Time[i] + nBarAfterSignal * Period() * 60;
		if (bLong) {
		    double p = Low[iLowest(NULL, 0, MODE_LOW, nStopLossRange, i + 1)];
		    objLine(sNameStopLossH, ts, p, te, p, colLong);
		    objLine(sNameStopLossV, t0, p, t0, p + 3 * Point, colLong);
		} else {
		    p = High[iHighest(NULL, 0, MODE_HIGH, nStopLossRange, i + 1)];
		    objLine(sNameStopLossH, ts, p, te, p, colShort);
		    objLine(sNameStopLossV, t0, p, t0, p - 3 * Point, colShort);
		}
	    }
	    
	    if (bAlert) {
		if (i == 0 && bFire && tAlertLast != Time[0]) {
		    PlaySound("alert.wav");
		    tAlertLast = Time[0];
		}
	    }
	}
    }
    
    WindowRedraw();
}
