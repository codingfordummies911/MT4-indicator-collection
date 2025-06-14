// More information about this indicator can be found at:
// http://fxcodebase.com/

//+------------------------------------------------------------------+
//|                               Copyright © 2019, Gehtsoft USA LLC | 
//|                                            http://fxcodebase.com |
//+------------------------------------------------------------------+
//|                                      Developed by : Mario Jemic  |
//|                                          mario.jemic@gmail.com   |
//+------------------------------------------------------------------+
//|                                 Support our efforts by donating  |
//|                                  Paypal : https://goo.gl/9Rj74e  |
//+------------------------------------------------------------------+
//|                                Patreon :  https://goo.gl/GdXWeN  |
//|                    BitCoin : 15VCJTLaz12Amr7adHSBtL9v8XomURo9RF  |
//|               BitCoin Cash : 1BEtS465S3Su438Kc58h2sqvVvHK9Mijtg  |
//|           Ethereum : 0x8C110cD61538fb6d7A2B47858F0c0AaBd663068D  |
//|                   LiteCoin : LLU8PSY2vsq7B9kRELLZQcKf5nJQrdeqwD  |
//+------------------------------------------------------------------+

//#property copyright "Copyright © 2019, Gehtsoft USA LLC"
//#property link      "http://fxcodebase.com"
#property version   "1.0"
#property strict
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1  clrLimeGreen
#property indicator_color2  clrOrange
#property indicator_color3  clrOrange
#property strict



enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};
enum enMaTypes
{
   ma_sma,    // Simple moving average
   ma_ema,    // Exponential moving average
   ma_smma,   // Smoothed MA
   ma_lwma,   // Linear weighted MA
   ma_tema    // Triple exponential moving average - TEMA
};
enum enDisplay
{
   en_lin,  // Display line
   en_lid,  // Display lines with dots
   en_dot   // Display dots
};

extern ENUM_TIMEFRAMES    TimeFrame       = PERIOD_CURRENT; // Time frame to use
extern int                HMAPeriod       = 21;             // Hma Period to use
extern enPrices           HMAPrice        = pr_haweighted;  // Price to use
extern enMaTypes          HMAMethod       = ma_lwma;        // Hma average type
extern double             HMASpeed        = 1.8;            // Hma Speed
extern enDisplay          DisplayType     = en_lid;         // Display type
extern int                Shift           = 0;              // Hull shift
extern int                LinesWidth      = 3;              // Lines width (when lines are included in display)
extern bool               alertsOn        = false;           // Turn alerts on?
extern bool               alertsOnCurrent = true;          // Alerts on still open bar?
extern bool               alertsMessage   = true;           // Alerts should show popup message?
extern bool               alertsSound     = true;          // Alerts should play a sound?
extern bool               alertsEmail     = false;          // Alerts should send email?
extern bool               alertsPushNotif = false;          // Alerts should send notification?
extern bool               ArrowOnFirst    = true;           // Arrow on first bars
extern int                UpArrowSize     = 2;              // Up Arrow size
extern int                DnArrowSize     = 2;              // Down Arrow size
extern int                UpArrowCode     = 233;            // Up Arrow code
extern int                DnArrowCode     = 234;            // Down arrow code
extern double             UpArrowGap      = 0.5;            // Up Arrow gap        
extern double             DnArrowGap      = 0.5;            // Dn Arrow gap
extern color              UpArrowColor    = clrLimeGreen;   // Up Arrow Color
extern color              DnArrowColor    = clrOrange;      // Down Arrow Color
extern bool               Interpolate     = true;           // Interpolate in multi time frame mode?
extern int button_x = 20; // X position of the button
extern int button_y = 30; // Y position of the button

//
//
//
//

double hma[];
double hmaDa[];
double hmaDb[];
double arrowu[];
double arrowd[];
double tem[];
double trend[];
int    HalfPeriod;
int    HullPeriod;
string indicatorFileName;
bool   returnBars;

string IndicatorName;
string IndicatorObjPrefix;

string GenerateIndicatorName(const string target)
{
   string name = target;
   int try = 2;
   while (WindowFind(name) != -1)
   {
      name = target + " #" + IntegerToString(try++);
   }
   return name;
}

bool show_data = true;
string buttonId;

int init()
{
   IndicatorName = GenerateIndicatorName("HMA nrp alerts + arrows with buttons");
   IndicatorObjPrefix = "__" + IndicatorName + "__";
   IndicatorShortName(IndicatorName);

   double val;
   if (GlobalVariableGet(IndicatorName + "_visibility", val))
      show_data = val != 0;

   IndicatorBuffers(7);
   int lstyle = DRAW_LINE;     if (DisplayType==en_dot) lstyle = DRAW_NONE;
   int astyle = DRAW_ARROW;    if (DisplayType<en_lid)  astyle = DRAW_NONE;
   SetIndexBuffer(0, hma);     SetIndexStyle(0,lstyle,EMPTY,LinesWidth);
   SetIndexBuffer(1, hmaDa);   SetIndexStyle(1,lstyle,EMPTY,LinesWidth);
   SetIndexBuffer(2, hmaDb);   SetIndexStyle(2,lstyle,EMPTY,LinesWidth);
   SetIndexBuffer(3, arrowu);  SetIndexStyle(3,astyle,0,UpArrowSize,UpArrowColor); SetIndexArrow(3,UpArrowCode);
   SetIndexBuffer(4, arrowd);  SetIndexStyle(4,astyle,0,DnArrowSize,DnArrowColor); SetIndexArrow(4,DnArrowCode);
   SetIndexBuffer(5, tem);
   SetIndexBuffer(6, trend);
   
   HMAPeriod  = (int)fmax(2,HMAPeriod);
   HalfPeriod = (int)floor(HMAPeriod/HMASpeed);
   HullPeriod = (int)floor(MathSqrt(HMAPeriod));
   
   indicatorFileName = WindowExpertName();
   returnBars        = TimeFrame==-99;
   TimeFrame         = fmax(TimeFrame,_Period);

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1);
   buttonId = IndicatorObjPrefix + "CloseButton";
   createButton(buttonId, "HMA NRP", 65, 20, "Impact", 8, clrDarkRed, clrBlack, clrWhite);
   ObjectSetInteger(0, buttonId, OBJPROP_YDISTANCE, button_y);
   ObjectSetInteger(0, buttonId, OBJPROP_XDISTANCE, button_x);

   return(0);
}

void createButton(string buttonID,string buttonText,int width,int height,string font,int fontSize,color bgColor,color borderColor,color txtColor)
{
   ObjectDelete(0,buttonID);
   ObjectCreate(0,buttonID,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,buttonID,OBJPROP_COLOR,txtColor);
   ObjectSetInteger(0,buttonID,OBJPROP_BGCOLOR,bgColor);
   ObjectSetInteger(0,buttonID,OBJPROP_BORDER_COLOR,borderColor);
   ObjectSetInteger(0,buttonID,OBJPROP_BORDER_TYPE,BORDER_RAISED);
   ObjectSetInteger(0,buttonID,OBJPROP_XDISTANCE,9999);
   ObjectSetInteger(0,buttonID,OBJPROP_YDISTANCE,9999);
   ObjectSetInteger(0,buttonID,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,buttonID,OBJPROP_YSIZE,height);
   ObjectSetString(0,buttonID,OBJPROP_FONT,font);
   ObjectSetString(0,buttonID,OBJPROP_TEXT,buttonText);
   ObjectSetInteger(0,buttonID,OBJPROP_FONTSIZE,fontSize);
   ObjectSetInteger(0,buttonID,OBJPROP_SELECTABLE,0);
   ObjectSetInteger(0,buttonID,OBJPROP_CORNER,2);
   ObjectSetInteger(0,buttonID,OBJPROP_HIDDEN,1);
}

int deinit()
{
   ObjectsDeleteAll(ChartID(), IndicatorObjPrefix);
   return 0;
}

bool recalc = true;

void handleButtonClicks()
{
   if (ObjectGetInteger(0, buttonId, OBJPROP_STATE))
   {
      ObjectSetInteger(0, buttonId, OBJPROP_STATE, false);
      show_data = !show_data;
      GlobalVariableSet(IndicatorName + "_visibility", show_data ? 1.0 : 0.0);
      recalc = true;
      start();
   }
}
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   handleButtonClicks();
}

int start()
{
   handleButtonClicks();
   int i,counted_bars = IndicatorCounted();
   if(counted_bars<0) return(-1);
   int limit = Bars - 1;
   if (counted_bars > 2 && !recalc) 
      limit = fmin(Bars - counted_bars - 1, limit);
   recalc = false;

   if (returnBars)
   {
      if (show_data)
         hma[0] = fmin(limit+1,Bars-1);
      else
         hma[0] = EMPTY_VALUE;
      return(0);
   }
            
   if (TimeFrame == Period())
   {
      if (trend[limit]==-1)
         CleanPoint(limit,hmaDa,hmaDb);
      for(i=limit; i>=0; i--)
      {
         if (show_data)
         {
            double price = getPrice(HMAPrice,Open,Close,High,Low,i);
            tem[i] = iCustomMa(HMAMethod,price,HalfPeriod,i,0)*2-iCustomMa(HMAMethod,price,HMAPeriod,i,1);
            hma[i] = iCustomMa(HMAMethod,tem[i],HullPeriod,i,2);
            hmaDa[i] = EMPTY_VALUE;
            hmaDb[i] = EMPTY_VALUE;
            trend[i] = (i<Bars-1) ? (hma[i]>hma[i+1]) ? 1 : (hma[i]<hma[i+1]) ? -1 : trend[i+1] : 0;  
            if (trend[i]==-1 && show_data) 
               PlotPoint(i,hmaDa,hmaDb,hma);
            if (i<Bars-1 && trend[i]!=trend[i+1])
            {
               if (trend[i] ==  1) 
                  arrowu[i] = fmin(hma[i],Low[i] )-iATR(NULL,0,15,i)*UpArrowGap;
               if (trend[i] == -1) 
                  arrowd[i] = fmax(hma[i],High[i])+iATR(NULL,0,15,i)*DnArrowGap;
            } 
         }
         else
         {
            tem[i] = EMPTY_VALUE;
            hma[i] = EMPTY_VALUE;
            hmaDa[i] = EMPTY_VALUE;
            hmaDb[i] = EMPTY_VALUE;
            trend[i] = EMPTY_VALUE;
            arrowu[i] = EMPTY_VALUE;
            arrowd[i] = EMPTY_VALUE;
         }
      }
 
      if (alertsOn)
      {
         int whichBar = 1; if (alertsOnCurrent) whichBar = 0;
         if (trend[whichBar] != trend[whichBar+1])
         if (trend[whichBar] == 1)
               doAlert("sloping up");
         else  doAlert("sloping down");       
      }  
      return(0);
   }
   
   limit = (int)fmax(limit,fmin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/_Period));
   if (trend[limit]==-1)
      CleanPoint(limit,hmaDa,hmaDb);
   for (i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,TimeFrame,Time[i]);
      int x;
      if (ArrowOnFirst)
         x = i<Bars-1 ? iBarShift(NULL,TimeFrame,Time[i+1]) : y;
      else  
         x = i>0 ? iBarShift(NULL,TimeFrame,Time[i-1]) : -1; 
      if (show_data)
      {
         hma[i]    = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,HMAPeriod,HMAPrice,HMAMethod,HMASpeed,DisplayType,0,0,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsPushNotif,ArrowOnFirst,UpArrowSize,DnArrowSize,UpArrowCode,DnArrowCode,UpArrowGap,DnArrowGap,UpArrowColor,DnArrowColor,0,y);
         trend[i]  = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,HMAPeriod,HMAPrice,HMAMethod,HMASpeed,DisplayType,0,0,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsPushNotif,ArrowOnFirst,UpArrowSize,DnArrowSize,UpArrowCode,DnArrowCode,UpArrowGap,DnArrowGap,UpArrowColor,DnArrowColor,6,y);
         hmaDa[i]  = EMPTY_VALUE;
         hmaDb[i]  = EMPTY_VALUE;
         arrowu[i] = EMPTY_VALUE;
         arrowd[i] = EMPTY_VALUE;
         if (x!=y)
         {
            arrowu[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,HMAPeriod,HMAPrice,HMAMethod,HMASpeed,DisplayType,0,0,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsPushNotif,ArrowOnFirst,UpArrowSize,DnArrowSize,UpArrowCode,DnArrowCode,UpArrowGap,DnArrowGap,UpArrowColor,DnArrowColor,3,y);
            arrowd[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,HMAPeriod,HMAPrice,HMAMethod,HMASpeed,DisplayType,0,0,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsPushNotif,ArrowOnFirst,UpArrowSize,DnArrowSize,UpArrowCode,DnArrowCode,UpArrowGap,DnArrowGap,UpArrowColor,DnArrowColor,4,y);
         }
      }
      else
      {
         hma[i] = EMPTY_VALUE;
         trend[i]  = EMPTY_VALUE;
         hmaDa[i]  = EMPTY_VALUE;
         hmaDb[i]  = EMPTY_VALUE;
         arrowu[i] = EMPTY_VALUE;
         arrowd[i] = EMPTY_VALUE;
         if (x!=y)
         {
            arrowu[i] = EMPTY_VALUE;
            arrowd[i] = EMPTY_VALUE;
         }
      }
      if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1])))
         continue;
               
      int n,j;
      datetime time = iTime(NULL,TimeFrame,y);
      for(n = 1; (i+n)<Bars && Time[i+n] >= time; n++) 
         continue;	
      for(j = 1; j<n && (i+n)<Bars && (i+j)<Bars; j++)
      {
         if (show_data)
            hma[i+j] = hma[i] + (hma[i+n] - hma[i])*j/n;           
         else
            hma[i+j] = EMPTY_VALUE;
      }
   }
   for (i=limit;i>=0;i--)
      if (trend[i]==-1 && show_data) 
         PlotPoint(i,hmaDa,hmaDb,hma);
   return(0);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------


#define _maInstances 3
#define _maWorkBufferx1 1*_maInstances
#define _maWorkBufferx2 2*_maInstances
#define _maWorkBufferx3 3*_maInstances

double iCustomMa(int mode, double price, double length, int r, int instanceNo=0)
{
   int bars = Bars; r = bars-r-1;
   switch (mode)
   {
      case ma_sma   : return(iSma(price,(int)length,r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)length,r,bars,instanceNo));
      case ma_tema  : return(iTema(price,(int)length,r,bars,instanceNo));
      default       : return(price);
   }
}

//


double workSma[][_maWorkBufferx2];
double iSma(double price, int period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= _bars) ArrayResize(workSma,_bars); instanceNo *= 2; int k;

   workSma[r][instanceNo+0] = price;
   workSma[r][instanceNo+1] = price; for(k=1; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo+0];  
   workSma[r][instanceNo+1] /= 1.0*k;
   return(workSma[r][instanceNo+1]);
}

//


double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= _bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo] = price;
   if (r>0 && period>1)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//


double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= _bars) ArrayResize(workSmma,_bars);

   workSmma[r][instanceNo] = price;
   if (r>1 && period>1)
          workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//


double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= _bars) ArrayResize(workLwma,_bars);
   
   workLwma[r][instanceNo] = price; if (period<=1) return(price);
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//


double workTema[][_maWorkBufferx3];
#define _tema1 0
#define _tema2 1
#define _tema3 2

double iTema(double price, double period, int r, int bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workTema,0)!= bars) ArrayResize(workTema,bars); instanceNo*=3;

   //

      
   workTema[r][_tema1+instanceNo] = price;
   workTema[r][_tema2+instanceNo] = price;
   workTema[r][_tema3+instanceNo] = price;
   double alpha = 2.0 / (1.0+period);
   if (r>0)
   {
          workTema[r][_tema1+instanceNo] = workTema[r-1][_tema1+instanceNo]+alpha*(price                         -workTema[r-1][_tema1+instanceNo]);
          workTema[r][_tema2+instanceNo] = workTema[r-1][_tema2+instanceNo]+alpha*(workTema[r][_tema1+instanceNo]-workTema[r-1][_tema2+instanceNo]);
          workTema[r][_tema3+instanceNo] = workTema[r-1][_tema3+instanceNo]+alpha*(workTema[r][_tema2+instanceNo]-workTema[r-1][_tema3+instanceNo]); }
   return(workTema[r][_tema3+instanceNo]+3.0*(workTema[r][_tema1+instanceNo]-workTema[r][_tema2+instanceNo]));
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------


#define priceInstances 1
double workHa[][priceInstances*4];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= Bars) ArrayResize(workHa,Bars); instanceNo*=4;
         int r = Bars-i-1;
         
         //

         double haOpen;
         if (r>0)
                haOpen  = (workHa[r-1][instanceNo+2] + workHa[r-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = fmax(high[i],fmax(haOpen,haClose));
         double haLow   = fmin(low[i] ,fmin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[r][instanceNo+0] = haLow;  workHa[r][instanceNo+1] = haHigh; } 
         else                 { workHa[r][instanceNo+0] = haHigh; workHa[r][instanceNo+1] = haLow;  } 
                                workHa[r][instanceNo+2] = haOpen;
                                workHa[r][instanceNo+3] = haClose;
         //

         
         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   //

   
   switch (tprice)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
      case pr_tbiased2:   
               if (close[i]>open[i]) return(high[i]);
               if (close[i]<open[i]) return(low[i]);
                                     return(close[i]);        
   }
   return(0);
} 

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------


string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}
 
//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------


void CleanPoint(int i,double& first[],double& second[])
{
   if (i>=Bars-3) return;
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (i>=Bars-2) return;
   if (first[i+1] == EMPTY_VALUE)
      if (first[i+2] == EMPTY_VALUE) 
            { first[i]  = from[i]; first[i+1]  = from[i+1]; second[i] = EMPTY_VALUE; }
      else  { second[i] = from[i]; second[i+1] = from[i+1]; first[i]  = EMPTY_VALUE; }
   else     { first[i]  = from[i];                          second[i] = EMPTY_VALUE; }
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------


void doAlert(string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
      if (previousAlert != doWhat || previousTime != Time[0]) {
          previousAlert  = doWhat;
          previousTime   = Time[0];

          //


          message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+" Hull trend changed to "+doWhat;
             if (alertsMessage)   Alert(message);
             if (alertsPushNotif) SendNotification(message);
             if (alertsEmail)     SendMail(_Symbol+" Hull ",message);
             if (alertsSound)     PlaySound("alert2.wav");
      }
}


