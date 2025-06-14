//+------------------------------------------------------------------+
//|                                                HMA color nrp.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
//------------------------------------------------------------------
//
//   divisor modification idea by SwingMan
//
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1  clrLimeGreen
#property indicator_color2  clrOrange
#property indicator_color3  clrOrange

//
//
//
//
//

//
//
//
//
//

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
//AHTF Timeframe template copy and paste start11
enum enTimeFrames
{
   tf_cu  = PERIOD_CURRENT, // Current time frame
   tf_m1  = PERIOD_M1,      // 1 minute
   tf_m5  = PERIOD_M5,      // 5 minutes
   tf_m15 = PERIOD_M15,     // 15 minutes
   tf_m30 = PERIOD_M30,     // 30 minutes
   tf_h1  = PERIOD_H1,      // 1 hour
   tf_h4  = PERIOD_H4,      // 4 hours
   tf_d1  = PERIOD_D1,      // Daily
   tf_w1  = PERIOD_W1,      // Weekly
   tf_mn1 = PERIOD_MN1,     // Monthly
   tf_n1  = -1,             // First higher time frame
   tf_n2  = -2,             // Second higher time frame
   tf_n3  = -3              // Third higher time frame
};
//AHTF Timeframe template copy and paste end11

//AHTF Timeframe template copy and paste start12
extern enTimeFrames       TimeFrame       = tf_cu;            // Time frame
//AHTF Timeframe template copy and paste end12

extern int                HMAPeriod       = 34;               // HMA Period to use
extern enPrices           HMAPrice        = pr_haweighted;    // Price to use
extern enMaTypes          HMAMethod       = ma_lwma;          // HMA average type
extern double             HMASpeed        = 1.8;              // HMA Speed
extern enDisplay          DisplayType     = en_lid;           // Display type
extern int                Shift           = 0;                // Hull shift
extern int                LinesWidth      = 3;                // Lines width (when lines are included in display)

//Forex-Station Zone template copy and paste start 1
extern bool               ShowZones       = false;             // Display the background zones
extern color              ColorUp         = clrHoneydew;      // Uptrend Zone color
extern color              ColorDown       = clrLavenderBlush; // Downtrend Zone color
extern string             UniqueZoneID    = "HMAZones2";      // Unique ID for the zones
//Forex-Station Zone template copy and paste end 1

extern bool               alertsOn        = false;            // Turn alerts on?
extern bool               alertsOnCurrent = false;            // Alerts on still open bar?
extern bool               alertsMessage   = false;            // Alerts should show popup message?
extern bool               alertsSound     = false;            // Alerts should play a sound?
extern bool               alertsEmail     = false;            // Alerts should send email?
extern bool               alertsPushNotif = false;            // Alerts should send notification?
extern bool               ArrowOnFirst    = true;             // Arrow on first bars
extern int                UpArrowSize     = 2;                // Up Arrow size
extern int                DnArrowSize     = 2;                // Down Arrow size
extern int                UpArrowCode     = 159;              // Up Arrow code
extern int                DnArrowCode     = 159;              // Down arrow code
extern double             UpArrowGap      = 0.5;              // Up Arrow gap        
extern double             DnArrowGap      = 0.5;              // Dn Arrow gap
extern color              UpArrowColor    = clrLimeGreen;     // Up Arrow Color
extern color              DnArrowColor    = clrOrange;        // Down Arrow Color
extern bool               Interpolate     = true;             // Interpolate in multi time frame mode?

//Forex-Station Zone template copy and paste start 2
double Dummy = -1;
//Forex-Station Zone template copy and paste end 2

//
//
//
//

double hma[], hmaDa[], hmaDb[], arrowu[], arrowd[], tem[], trend[];
int    HalfPeriod,    HullPeriod;
string indicatorFileName;
bool   returnBars;

//+------------------------------------------------------------------
//|                                                                 |
//+------------------------------------------------------------------
//
//

int init()
{
   IndicatorBuffers(7);
   int lstyle = DRAW_LINE;     if (DisplayType==en_dot) lstyle = DRAW_NONE;
   int astyle = DRAW_ARROW;    if (DisplayType<en_lid)  astyle = DRAW_NONE;
   SetIndexBuffer(0, hma);     
   SetIndexBuffer(1, hmaDa);   SetIndexStyle(1,lstyle,EMPTY,LinesWidth); 
   SetIndexBuffer(2, hmaDb);   SetIndexStyle(2,lstyle,EMPTY,LinesWidth);
   SetIndexBuffer(3, arrowu);  SetIndexStyle(3,astyle,0,UpArrowSize,UpArrowColor); SetIndexArrow(3,UpArrowCode); SetIndexLabel (3, "uptrend; go LONG");
   SetIndexBuffer(4, arrowd);  SetIndexStyle(4,astyle,0,DnArrowSize,DnArrowColor); SetIndexArrow(4,DnArrowCode); SetIndexLabel (4, "downtrend; SHORT");
   SetIndexBuffer(5, tem);
   SetIndexBuffer(6, trend);
   
   HMAPeriod  = (int)fmax(2,HMAPeriod);
   HalfPeriod = (int)floor(HMAPeriod/HMASpeed);
   HullPeriod = (int)floor(MathSqrt(HMAPeriod));
   
   indicatorFileName = WindowExpertName();
   returnBars        = TimeFrame==-99;

//AHTF Timeframe Timeframe template copy and paste start13
   TimeFrame         = (enTimeFrames)timeFrameValue(TimeFrame);
//AHTF Timeframe Timeframe template copy and paste end13

   SetIndexStyle(0,lstyle,EMPTY,LinesWidth);    SetIndexLabel (0, "(" + timeFrameToString(TimeFrame) + ") HMA (" + HMAPeriod +")");
   IndicatorShortName(timeFrameToString(TimeFrame)+" HMA("+(string)HMAPeriod+")");
return(0);
}
//+------------------------------------------------------------------------------------------------------------------+
//AHTF Timeframe template copy and paste start14
int timeFrameValue(int _tf)
{
   int add  = (_tf>=0) ? 0 : MathAbs(_tf);
   if (add != 0) _tf = _Period;
   int size = ArraySize(iTfTable); 
      int i =0; for (;i<size; i++) if (iTfTable[i]==_tf) break;
                                   if (i==size) return(_Period);
                                                return(iTfTable[(int)MathMin(i+add,size-1)]);
}
//AHTF Timeframe template copy and paste end14
//+------------------------------------------------------------------------------------------------------------------+

//Forex-Station Zone template copy and paste start 3
int deinit()
{
   string lookFor2       = UniqueZoneID+":";
   int    lookForLength2 = StringLen(lookFor2);
   for (int ForexStation=ObjectsTotal()-1; ForexStation>=0; ForexStation--)
   {
      string objectName2 = ObjectName(ForexStation);
      if (StringSubstr(objectName2,0,lookForLength2) == lookFor2) ObjectDelete(objectName2);
   }
   GlobalVariableDel(ChartID()+":"+UniqueZoneID);
   return(0);
}
//+------------------------------------------------------------------------------------------------------------------+
//Forex-Station Zone template copy and paste end 3

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int start()
{
   int i,counted_bars = IndicatorCounted();
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         int limit = fmin(Bars-counted_bars,Bars-1);
         if (returnBars) { hma[0] = fmin(limit+1,Bars-1); return(0); }
            
//Forex-Station Zone template copy and paste start 4
         datetime tDummy = GlobalVariableGet(ChartID()+":"+UniqueZoneID); if (tDummy==0) tDummy = Time[0];
//Forex-Station Zone template copy and paste end 4
   //
   //
   //
   //
   //
   
   if (TimeFrame == Period())
   {
     if (trend[limit]==-1) CleanPoint(limit,hmaDa,hmaDb);
     for(i=limit; i>=0; i--)
     {
        double price = getPrice(HMAPrice,Open,Close,High,Low,i);
        tem[i] = iCustomMa(HMAMethod,price,HalfPeriod,i,0)*2-iCustomMa(HMAMethod,price,HMAPeriod,i,1);
        hma[i] = iCustomMa(HMAMethod,tem[i],HullPeriod,i,2);
        hmaDa[i] = EMPTY_VALUE;
        hmaDb[i] = EMPTY_VALUE;
        trend[i] = (i<Bars-1) ? (hma[i]>hma[i+1]) ? 1 : (hma[i]<hma[i+1]) ? -1 : trend[i+1] : 0;  
        if (trend[i]==-1) PlotPoint(i,hmaDa,hmaDb,hma);
        if (i<Bars-1 && trend[i]!=trend[i+1])
        {
           if (trend[i] ==  1) arrowu[i] = fmin(hma[i],Low[i] )-iATR(NULL,0,15,i)*UpArrowGap;
           if (trend[i] == -1) arrowd[i] = fmax(hma[i],High[i])+iATR(NULL,0,15,i)*DnArrowGap;
        } 
        
            
//Forex-Station Zone template copy and paste start 5
        if (trend[i]==0 || !ShowZones) continue;

               for (int index=i; index<Bars; index++) if (trend[index]!= trend[index+1]) break;
               string name = UniqueZoneID+":"+Time[index+1]; 
               ObjectDelete(name); 
               ObjectDelete(UniqueZoneID+":"+Time[1]);
               
               datetime lastTime = Time[i-1]; if (i==0) { lastTime = tDummy; if (Time[index]==lastTime) lastTime = Time[0]+Period()*60;}
               ObjectCreate(name,OBJ_RECTANGLE,0,Time[index],0,lastTime,WindowPriceMax()*3.0);
                  ObjectSet(name,OBJPROP_BACK,true);
                  if (trend[i]==-1)
                        ObjectSet(name,OBJPROP_COLOR,ColorDown);
                  else  ObjectSet(name,OBJPROP_COLOR,ColorUp);
//Forex-Station Zone template copy and paste end 5

     } //for(i=limit; i>=0; i--)
 
   //
   //
   //
   //
   //
   
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
   
   //
   //
   //
   //
   //
//Forex-Station Zone template copy and paste start 6
         if (TimeFrame!=Period()) 
         { 
            GlobalVariableSet(ChartID()+":"+UniqueZoneID,Time[0]+_Period*60-1);
            // don't forget to change to PERIOD_CURRENT in the next line
            iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,HMAPeriod,HMAPrice,HMAMethod,HMASpeed,DisplayType,0,0,ShowZones,ColorUp,ColorDown,UniqueZoneID,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsPushNotif,ArrowOnFirst,UpArrowSize,DnArrowSize,UpArrowCode,DnArrowCode,UpArrowGap,DnArrowGap,UpArrowColor,DnArrowColor,0,0);
         }
//Forex-Station Zone template copy and paste end 6
      
   limit = (int)fmax(limit,fmin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/_Period));

//Forex-Station Zone template copy and paste start 7
   if (trend[limit]==-1) CleanPoint(limit,hmaDa,hmaDb);
//Forex-Station Zone template copy and paste end 7

   for(i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,TimeFrame,Time[i]);
      int x = y;
      if (ArrowOnFirst)
            {  if (i<Bars-1) x = iBarShift(NULL,TimeFrame,Time[i+1]);          }
      else  {  if (i>0) x = iBarShift(NULL,TimeFrame,Time[i-1]); else x = -1;  }
         hma[i]    = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,HMAPeriod,HMAPrice,HMAMethod,HMASpeed,DisplayType,0,0,ShowZones,ColorUp,ColorDown,UniqueZoneID,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsPushNotif,ArrowOnFirst,UpArrowSize,DnArrowSize,UpArrowCode,DnArrowCode,UpArrowGap,DnArrowGap,UpArrowColor,DnArrowColor,0,y);
         trend[i]  = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,HMAPeriod,HMAPrice,HMAMethod,HMASpeed,DisplayType,0,0,ShowZones,ColorUp,ColorDown,UniqueZoneID,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsPushNotif,ArrowOnFirst,UpArrowSize,DnArrowSize,UpArrowCode,DnArrowCode,UpArrowGap,DnArrowGap,UpArrowColor,DnArrowColor,6,y);
         hmaDa[i]  = EMPTY_VALUE;
         hmaDb[i]  = EMPTY_VALUE;
         arrowu[i] = EMPTY_VALUE;
         arrowd[i] = EMPTY_VALUE;
         if (x!=y)
         {
            arrowu[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,HMAPeriod,HMAPrice,HMAMethod,HMASpeed,DisplayType,0,0,ShowZones,ColorUp,ColorDown,UniqueZoneID,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsPushNotif,ArrowOnFirst,UpArrowSize,DnArrowSize,UpArrowCode,DnArrowCode,UpArrowGap,DnArrowGap,UpArrowColor,DnArrowColor,3,y);
            arrowd[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,HMAPeriod,HMAPrice,HMAMethod,HMASpeed,DisplayType,0,0,ShowZones,ColorUp,ColorDown,UniqueZoneID,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsPushNotif,ArrowOnFirst,UpArrowSize,DnArrowSize,UpArrowCode,DnArrowCode,UpArrowGap,DnArrowGap,UpArrowColor,DnArrowColor,4,y);
         }
         if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1]))) continue;
                  
         //
         //
         //
         //
         //
                  
         int n,j; datetime time = iTime(NULL,TimeFrame,y);
            for(n = 1; (i+n)<Bars && Time[i+n] >= time; n++) continue;	
            for(j = 1; j<n && (i+n)<Bars && (i+j)<Bars; j++) hma[i+j] = hma[i] + (hma[i+n] - hma[i])*j/n;           
   }
   for (i=limit;i>=0;i--) if (trend[i]==-1) PlotPoint(i,hmaDa,hmaDb,hma);
   return(0);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

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
//
//
//
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
//
//
//
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
//
//
//
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
//
//
//
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
//
//
//
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
   //
   //
   //
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
//
//
//
//
//
//

#define priceInstances 1
double workHa[][priceInstances*4];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= Bars) ArrayResize(workHa,Bars); instanceNo*=4;
         int r = Bars-i-1;
         
         //
         //
         //
         //
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
         //
         //
         //
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
   //
   //
   //
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
//
//
//
//
//

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
//
//
//
//
//

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
//
//
//
//
//

void doAlert(string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
      if (previousAlert != doWhat || previousTime != Time[0]) {
          previousAlert  = doWhat;
          previousTime   = Time[0];

          //
          //
          //
          //
          //

          message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+" Hull trend changed to "+doWhat;
             if (alertsMessage)   Alert(message);
             if (alertsPushNotif) SendNotification(message);
             if (alertsEmail)     SendMail(_Symbol+" Hull ",message);
             if (alertsSound)     PlaySound("alert2.wav");
      }
}
//+------------------------------------------------------------------------------------------------------------------+
