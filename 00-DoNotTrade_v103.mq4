//
// "00-DoNotTrade_v103.mq4" -- TRADE or NOT TRADE, based on Damiani_volatmeter.mq4
//
//    Ver. 1.00  2009/03/13(Fri)  initial version
//    Ver. 1.01  2009/03/13(Fri)  bugfixed: "TRADE"/"DO NOT TRADE" was not shown in MTF mode
//                                parameter "window" is added
//    Ver. 1.02  2009/03/15(Sun)  bugfixed: sIndSelf has wrong version number
//                                timeframe info is added
//    Ver. 1.03  2010/05/17(Mon)  draw "TRADE"/"NOT TRADE" on the chart (window 0)
//
//
#property copyright  "00mql4@gmail.com"
#property link       "http://00mql4.blogspot.com/"

//---- defines

//---- indicator settings
#property  indicator_separate_window

#property  indicator_buffers  3

#property  indicator_color1  Silver
#property  indicator_color2  FireBrick
#property  indicator_color3  Lime

#property  indicator_width1  1
#property  indicator_width2  1
#property  indicator_width3  1

#property  indicator_style1  STYLE_SOLID
#property  indicator_style2  STYLE_SOLID
#property  indicator_style3  STYLE_SOLID

//---- indicator parameters
extern int     timeFrame       = 0;               // time frame
extern int     viscosity       = 13;              // viscosity
extern int     sedimentation   = 50;              // sedimentation
extern double  threshold       = 1.3;             // threshold
extern bool    bLagSuppressor  = true;            // lag suppressor
extern double  lagK            = 0.5;             // coefficient
extern int     window          = -1;              // dropped window no, -1: auto
extern int     msgCorner       = 1;               // corner of message ("TRADE"/"DO NOT TRADE")
extern int     msgX            = 1;               // x pos of message
extern int     msgY            = 1;               // y pos of message
extern string  msgGo           = "TRADE";         // GO msg
extern string  msgStop         = "DO NOT TRADE";  // STOP msg
extern color   colorGo         = Aqua;            // color for "TRADE"
extern color   colorStop       = Magenta;         // color for "DO NOT TRADE"
extern string  fontName        = "MS UI Gothic";  // font name
extern int     fontSize        = 24;              // font size
extern bool    bAlert          = true;            // alert on trade go/stop
extern int     nMaxBars        = 20000;           // maximum number of bars to calculate, 0: no limit

//---- indicator buffers
double BufferThreshold[];  // 0: 
double BufferVolM[];       // 1: 
double BufferVolT[];       // 2: 
double BufferIndC[];       // 3: 
double BufferAtrVis[];     // 4: 

//---- vars
string sIndicatorName  = "";
string sIndSelf        = "00-DoNotTrade_v103";
string sPrefix;
string sTimeFrame;

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
    
    sTimeFrame = TimeFrameToStr(timeFrame);
    sIndicatorName = sIndSelf + "(" + sTimeFrame + "," + viscosity + "," + sedimentation + "," + threshold + ")";
    sPrefix = sIndicatorName;
    
    //IndicatorShortName(sIndicatorName);
    
    IndicatorBuffers(5);
    
    SetIndexBuffer(0, BufferThreshold);
    SetIndexBuffer(1, BufferVolM);
    SetIndexBuffer(2, BufferVolT);
    SetIndexBuffer(3, BufferIndC);
    SetIndexBuffer(4, BufferAtrVis);
    
    SetIndexStyle(0, DRAW_LINE);
    SetIndexStyle(1, DRAW_SECTION);
    SetIndexStyle(2, DRAW_LINE);
    
    int n = viscosity;
    SetIndexDrawBegin(0, n);
    SetIndexDrawBegin(1, n);
    SetIndexDrawBegin(2, n);
    
    if (window < 0) {
	window = WindowOnDropped();
	if (window < 0) {
	    window = 1;
	}
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
double self(int mode, int shift)
{
    double v = iCustom(NULL, timeFrame, sIndSelf,
		       0,
		       viscosity,
		       sedimentation,
		       threshold,
		       bLagSuppressor,
		       lagK,
		       window,
		       msgCorner,
		       msgX,
		       msgY,
		       msgGo,
		       msgStop,
		       colorGo,
		       colorStop,
		       fontName,
		       fontSize,
		       bAlert,
		       nMaxBars, mode, shift);
    
    return(v);
}

//----------------------------------------------------------------------
void objLabel(string sName, int corner, int x, int y, string text, color col, int size = 0, string font = "", int window = 0)
{
    sName = sPrefix + sName;

    if (size == 0) {
	size = fontSize;
    }
    if (font == "") {
	font = fontName;
    }

    ObjectCreate(sName, OBJ_LABEL, window, 0, 0);
    ObjectSetText(sName, text, size, font, col);
    ObjectSet(sName, OBJPROP_CORNER, corner);
    ObjectSet(sName, OBJPROP_XDISTANCE, x);
    ObjectSet(sName, OBJPROP_YDISTANCE, y);
}

//----------------------------------------------------------------------
void objLine(string sName, datetime ts, double ps, datetime te, double pe, color col, int w = 1, int style = STYLE_SOLID, bool ray = false)
{
    sName = sPrefix + sName;
    
    ObjectCreate(sName, OBJ_TREND, window, 0, 0);
    ObjectSet(sName, OBJPROP_TIME1, ts);
    ObjectSet(sName, OBJPROP_PRICE1, ps);
    ObjectSet(sName, OBJPROP_TIME2, te);
    ObjectSet(sName, OBJPROP_PRICE2, pe);
    ObjectSet(sName, OBJPROP_COLOR, col);
    ObjectSet(sName, OBJPROP_WIDTH, w);
    ObjectSet(sName, OBJPROP_STYLE, style);
    ObjectSet(sName, OBJPROP_RAY, ray);
}

//----------------------------------------------------------------------
void msg(string s)
{
    string tf = TimeFrameToStr(Period());
    string ss = "[" + sIndSelf + "][" + Symbol() + " " + tf + "] " + s;
    Alert(ss);
}

//----------------------------------------------------------------------
void ShowDoNotTrade(double vol, double th, double atrVis)
{
    static bool bTradeLast;
    string sAtr = DoubleToStr(atrVis, Digits);
    string sMsg;
    color col;
    bool bTrade = (vol > th);
    
    if (bTrade) {
	sMsg = msgGo;
	col = colorGo;
    } else {
	sMsg = msgStop;
	col = colorStop;
    }
    IndicatorShortName(sTimeFrame + " " + sMsg + "  /  ATR = " + sAtr + "    values:");
    
    if (msgCorner >= 0) {
	objLabel("msg", msgCorner, msgX, msgY, sMsg, col);
    }
    
    if (bAlert) {
	if (bTrade != bTradeLast) {
	    bTradeLast = bTrade;
	    msg(sMsg);
	}
    }
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
	BufferThreshold[i] = 0;
	BufferVolM[i]      = 0;
	BufferVolT[i]      = 0;
	BufferIndC[i]      = 0;
	BufferAtrVis[i]    = 0;
    }
    
    if (timeFrame != Period()) {
	// MTF
	limit = MathMax(limit, timeFrame / Period());
	for (i = limit - 1; i >= 0; i--) {
	    int x = iBarShift(NULL, timeFrame, Time[i]);
	    BufferThreshold[i] = self(0, x);
	    BufferVolM[i]      = self(1, x);
	    BufferVolT[i]      = self(2, x);
	    BufferIndC[i]      = self(3, x);
	    BufferAtrVis[i]    = self(4, x);
	}
	ShowDoNotTrade(BufferVolT[0], BufferThreshold[0], BufferAtrVis[0]);
	
	return;
    }
    
    // timeFrame == Period()
    for (i = limit - 1; i >= 0; i--) {
	double atrVis = iATR(NULL, 0, viscosity, i);
	double atrSed = iATR(NULL, 0, sedimentation, i);
	double s1 = BufferIndC[i + 1];
	double s3 = BufferIndC[i + 3];
	double vol = 0;
	if (bLagSuppressor) {
	    if (atrSed != 0.0) {
		vol = atrVis / atrSed + lagK * (s1 - s3);
	    }
	} else {
	    if (atrSed != 0.0) {
		vol = atrVis / atrSed;
	    }
	}
	BufferIndC[i] = vol;
	BufferAtrVis[i] = atrVis;
	
	double sdV = iStdDev(NULL, 0, viscosity, 0, MODE_LWMA, PRICE_TYPICAL, i);
	double sdS = iStdDev(NULL, 0, sedimentation, 0, MODE_LWMA, PRICE_TYPICAL, i);
	double antiThres = 0;
	if (sdS != 0.0) {
	    antiThres = sdV / sdS;
	}
	
	double th = threshold - antiThres;
	BufferThreshold[i] = th;
	
	if (vol > th) {
	    BufferVolT[i] = vol;
	    BufferVolM[i] = vol;
	} else {
	    BufferVolT[i] = vol;
	    BufferVolM[i] = EMPTY_VALUE;
	}
    }
    
    ShowDoNotTrade(vol, th, atrVis);
    
    // last "DO NOT TRADE" line
    datetime ts = 0;
    datetime te = Time[0];
    double p = EMPTY_VALUE;
    if (vol <= th) {
	for (int j = 0; j < nMaxBars; j++) {
	    if (BufferIndC[j] > BufferThreshold[j]) {
		ts = Time[j];
		p = BufferIndC[j];
		break;
	    }
	}
    }
    objLine("DoNotTrade", ts, p, te, p, FireBrick, 1);
    WindowRedraw();
}
