//------------------------------------------------------------------
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"
//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers    6
#property indicator_color1     clrYellow
#property indicator_color2     clrAqua
#property indicator_color3     clrAqua
#property indicator_color4     clrLime
#property indicator_color5     clrRed
#property indicator_color6     clrRed
#property indicator_width1     3
#property indicator_minimum    0
#property indicator_maximum    100
#property indicator_levelcolor clrDarkSlateGray
#property strict

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
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased   // Heiken ashi trend biased price
};
enum enColorOn
{
   clr_slp, // Color change on slope change
   clr_sig  // Color change on signal cross
};
extern ENUM_TIMEFRAMES TimeFrame       = PERIOD_CURRENT; // Time frame to use
extern enPrices        RsiPrice        = pr_close;       // Price to use 
extern double          RsiPeriod       = 34;             // Rsi Period
extern double          OmaSpeed        = 2.0;            // Oma Speed
extern bool            OmaAdaptive     = true;           // Use Oma Adaptive true or false
extern int             MaPeriod        = 34;             // Bands Ma Period
extern ENUM_MA_METHOD  MaMethod        = 3;              // Bands Ma Method
extern enColorOn       ColorOn         = clr_slp;        // Color change on :
extern int             koridor         = 5;              // Distance between bands
extern bool            alertsOn        = true;           // Turn alerts on
extern bool            alertsOnCurrent = true;           // Alerts on current (still opened) bar
extern bool            alertsMessage   = true;           // Alerts should display alert message
extern bool            alertsSound     = true;           // Alerts should play alert sound
extern bool            alertsEmail     = false;          // Alerts should send alert email?
extern bool            alertsNotify    = false;          // Alerts should send alert notification
extern string          soundfile       = "alert2.wav";   // Alerts soundfile name
extern bool            Interpolate     = true;           // Interpolate in multi time frame mode?
extern bool            drawDots        = true;           // Draw as dots or regular line
extern double          levelOs         = 20;             // Oversold level
extern double          levelOb         = 80;             // Overbought level

//
//
//
//
//

double rsi[];
double upBand[];
double dnBand[];
double rsiMaDa[];
double rsiMaDb[];
double rsiMa[];
double trend[];
string indicatorFileName;
bool   returnBars;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int init()
{
   IndicatorBuffers(7);
   SetIndexBuffer(0,rsi); 
   SetIndexBuffer(1,upBand);
   SetIndexBuffer(2,dnBand); 
   SetIndexBuffer(3,rsiMa);    
   SetIndexBuffer(4,rsiMaDa);
   SetIndexBuffer(5,rsiMaDb);  
   SetIndexBuffer(6,trend);
   if (drawDots) 
   {
     SetIndexStyle(3, DRAW_ARROW,0); SetIndexArrow(3, 110);
     SetIndexStyle(4, DRAW_ARROW,0); SetIndexArrow(4, 110);
     SetIndexStyle(5, DRAW_NONE);
   }
   else
   {
     SetIndexStyle(3, DRAW_LINE);
     SetIndexStyle(4, DRAW_LINE);
     SetIndexStyle(5, DRAW_LINE);
   }        
            
       //
       //
       //
       //
       //
         
       OmaSpeed          = MathMax(OmaSpeed,-1.5);
       indicatorFileName = WindowExpertName();
       returnBars        = TimeFrame==-99;
       TimeFrame         = MathMax(TimeFrame,_Period);

       //
       //
       //
       //   
       //
          
   SetLevelValue(0,levelOb);
   SetLevelValue(1,levelOs);
   IndicatorShortName(timeFrameToString(TimeFrame)+ " OMA Rsi Bands ("+DoubleToStr(RsiPeriod,2)+","+(string)MaPeriod+")");
return(0);
}
int deinit() { return(0); }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int start()
{
   int counted_bars=IndicatorCounted();
   int i,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars - counted_bars,Bars-1);
         if (returnBars) { rsi[0] = MathMin(limit+1,Bars-1); return(0); }

   //
   //
   //
   //
   //
   
   if (TimeFrame==Period())
   {
     if (!drawDots) if (trend[limit] == -1) CleanPoint(limit,rsiMaDa,rsiMaDb);
     for (i=limit; i>=0; i--) rsi[i] = iRsi(getPrice(RsiPrice,Open,Close,High,Low,i),RsiPeriod,OmaSpeed,OmaAdaptive,i);
     for (i=limit; i>=0; i--) 
     {
        rsiMa[i]  = iMAOnArray(rsi,0,MaPeriod,0,MaMethod,i);
        upBand[i] = rsiMa[i]+koridor;
        dnBand[i] = rsiMa[i]-koridor;
        rsiMaDa[i] = EMPTY_VALUE;
        rsiMaDb[i] = EMPTY_VALUE;
        if (i<Bars-1)
        {
            trend[i] = trend[i+1];
            if (ColorOn==clr_sig)
            {
               if (rsi[i]>rsiMa[i]) trend[i]= 1;
               if (rsi[i]<rsiMa[i]) trend[i]=-1;
            }
            else
            {
               if (rsi[i]>rsi[i+1]) trend[i]= 1;
               if (rsi[i]<rsi[i+1]) trend[i]=-1;
            }               
            if (trend[i]==-1) 
               if    (drawDots) rsiMaDa[i] = rsiMa[i];
               else  PlotPoint(i,rsiMaDa,rsiMaDb,rsiMa);
         }                             
      }
   
   //
   //
   //
   //
   //
   
   if (alertsOn)
   {
      int whichBar = 1; if (alertsOnCurrent) whichBar = 0;
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] ==  1) doAlert(whichBar,"up");
         if (trend[whichBar] == -1) doAlert(whichBar,"down");
      }
   }
   return(0);
   }
   
   //
   //
   //
   //
   //

   limit = (int)MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
   if (trend[limit]==-1) CleanPoint(limit,rsiMaDa,rsiMaDb);
   for(i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,TimeFrame,Time[i]);
         rsi[i]     = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,ColorOn,koridor,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,soundfile,0,y);
         upBand[i]  = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,ColorOn,koridor,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,soundfile,1,y);
         dnBand[i]  = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,ColorOn,koridor,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,soundfile,2,y);
         rsiMa[i]   = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,ColorOn,koridor,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,soundfile,3,y);
         rsiMaDa[i] = EMPTY_VALUE;
         rsiMaDb[i] = EMPTY_VALUE;
         trend[i]   = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,ColorOn,koridor,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,soundfile,6,y);
         if (drawDots && trend[i]==-1) rsiMaDa[i] = rsiMa[i]; 
         
         //
         //
         //
         //
         //
      
         if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1]))) continue;

         //
         //
         //
         //
         //

         int n,k; datetime time = iTime(NULL,TimeFrame,y);
            for(n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;
            for(k = 1; k < n; k++) 
            {
               rsi[i+k]    = rsi[i]    + (rsi[i+n]    - rsi[i])   * k/n;
               upBand[i+k] = upBand[i] + (upBand[i+n] - upBand[i])* k/n;
               dnBand[i+k] = dnBand[i] + (dnBand[i+n] - dnBand[i])* k/n;
               rsiMa[i+k]  = rsiMa[i]  + (rsiMa[i+n]  - rsiMa[i]) * k/n;
               if (rsiMaDa[i+k] != EMPTY_VALUE) rsiMaDa[i+k] = rsiMa[i+k];
             }               
   }
   if (!drawDots) for(i=limit; i>=0; i--) if (trend[i]== -1) PlotPoint(i,rsiMaDa,rsiMaDb,rsiMa);
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
//

double workHa[][4];
double getPrice(int price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int instanceNo=0)
{
  if (price>=pr_haclose && price<=pr_hatbiased)
   {
      if (ArrayRange(workHa,0)!= Bars) ArrayResize(workHa,Bars);
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
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[r][instanceNo+0] = haLow;  workHa[r][instanceNo+1] = haHigh; } 
         else                 { workHa[r][instanceNo+0] = haHigh; workHa[r][instanceNo+1] = haLow;  } 
                                workHa[r][instanceNo+2] = haOpen;
                                workHa[r][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (price)
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
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (price)
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
   }
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
//

double workRsi[][1];
double iRsi(double price, double period, double speed, bool adaptive, int i, int instanceNo=0)
{
   if (ArrayRange(workRsi,0)!=Bars) ArrayResize(workRsi,Bars); int r = Bars-i-1;
   
   //
   //
   //
   //
   //
   
   workRsi[r][instanceNo] = price; if (r<1) return(price);
         double chng   = workRsi[r][instanceNo]-workRsi[r-1][instanceNo];
         double changn = iOma(price,        chng ,period,speed,adaptive,i,instanceNo*2+0);
         double changa = iOma(price,MathAbs(chng),period,speed,adaptive,i,instanceNo*2+1);
            if (changn != 0)
                  return(MathMin(MathMax(50.0*(changn/MathMax(changa,0.0000001)+1.0),0),100));
            else  return(50.0);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

#define omaInstances 2
double workOma[][omaInstances*8];
#define F01 0
#define F02 1
#define F03 2
#define F04 3
#define F05 4
#define F06 5
#define prc 6
#define pro 7

//
//
//
//
//

double iOma(double oprice, double price, double averagePeriod, double constant, bool adaptive, int r, int s=0)
{
   if (averagePeriod <=1) return(price);
   if (ArrayRange(workOma,0) != Bars) ArrayResize(workOma,Bars); r=Bars-r-1; s *=8;
   if (r<=1) 
   {
      for (int i=0; i<6; i++) workOma[r][i  +s] = 0;
                              workOma[r][prc+s] = price;
                              workOma[r][pro+s] = oprice;
                              return(price);
   }      
   double f01=workOma[r-1][F01+s];  double f02=workOma[r-1][F02+s];
   double f03=workOma[r-1][F03+s];  double f04=workOma[r-1][F04+s];
   double f05=workOma[r-1][F05+s];  double f06=workOma[r-1][F06+s];

   //
   //
   //
   //
   //

      if (adaptive && (averagePeriod > 1))
      {
         double minPeriod = MathMin(averagePeriod,r)/2.0;
         double maxPeriod = MathMin(minPeriod*5.0,r);
         int    endPeriod = (int)MathCeil(maxPeriod);
         double signal    = MathAbs((oprice-workOma[r-endPeriod][pro+s]));
         double noise     = 0.00000000001;

            for(int i=1; i<endPeriod; i++) noise=noise+MathAbs(oprice-workOma[r-i][pro+s]);

         averagePeriod = ((signal/noise)*(maxPeriod-minPeriod))+minPeriod;
      }
      
      //
      //
      //
      //
      //
      
      double Kg = (2.0+constant)/(1.0+constant+averagePeriod);
      double Hg = 1.0-Kg;

      f01 = Kg * price + Hg * f01; f02 = Kg * f01 + Hg * f02; double v01 = 1.5 * f01 - 0.5 * f02;
      f03 = Kg * v01   + Hg * f03; f04 = Kg * f03 + Hg * f04; double v02 = 1.5 * f03 - 0.5 * f04;
      f05 = Kg * v02   + Hg * f05; f06 = Kg * f05 + Hg * f06; double v03 = 1.5 * f05 - 0.5 * f06;

   //
   //
   //
   //
   //

   workOma[r][F01+s] = f01;   workOma[r][F02+s] = f02;
   workOma[r][F03+s] = f03;   workOma[r][F04+s] = f04;
   workOma[r][F05+s] = f05;   workOma[r][F06+s] = f06;
   workOma[r][prc+s] = price; workOma[r][pro+s] = oprice;
   return(v03);
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
            { first[i]  = from[i];  first[i+1]  = from[i+1]; second[i] = EMPTY_VALUE; }
      else  { second[i] =  from[i]; second[i+1] = from[i+1]; first[i]  = EMPTY_VALUE; }
   else     { first[i]  = from[i];                           second[i] = EMPTY_VALUE; }
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

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," ",timeFrameToString(_Period)+" OMA Rsi Bands trend changed to ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsNotify)  SendNotification(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," OMA Rsi Bands "),message);
          if (alertsSound)   PlaySound(soundfile);
   }
}

