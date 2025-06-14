//+-------------------------------------------------------------------------+
//+-------------------------------------------------------------------------+
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers 8








enum enRsiTypes
{
   rsi_rsi,  // Regular RSI
   rsi_wil,  // Slow RSI
   rsi_rap,  // Rapid RSI
   rsi_har,  // Harris RSI
   rsi_rsx,  // RSX
   rsi_cut   // Cuttlers RSI
};
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
   pr_hatbiased2, // Heiken ashi trend biased (extreme) price
   pr_habclose,   // Heiken ashi (better formula) close
   pr_habopen ,   // Heiken ashi (better formula) open
   pr_habhigh,    // Heiken ashi (better formula) high
   pr_hablow,     // Heiken ashi (better formula) low
   pr_habmedian,  // Heiken ashi (better formula) median
   pr_habtypical, // Heiken ashi (better formula) typical
   pr_habweighted,// Heiken ashi (better formula) weighted
   pr_habaverage, // Heiken ashi (better formula) average
   pr_habmedianb, // Heiken ashi (better formula) median body
   pr_habtbiased, // Heiken ashi (better formula) trend biased price
   pr_habtbiased2 // Heiken ashi (better formula) trend biased (extreme) price
};
//
enum enMaTypes
{
   ma_sma,    // Simple moving average
   ma_ema,    // Exponential moving average
   ma_smma,   // Smoothed MA
   ma_lwma,   // Linear weighted MA
   ma_tema    // Tripple exponential moving average
};
//

enum enArrowOn
{
   cc_onRSIcrosslevel,   // Color + alerts/arrows RSI cross level
   cc_onRSIcross50level, // Color + alerts/arrows RSI cross 50 level
   cc_RSIcrossMA,        // Color + alerts/arrows RSI cross MA 
   cc_onSLOPE,           // Color + alerts/arrows RSI slope
  
};



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

extern enTimeFrames    TimeFrame                 = tf_cu; 
extern int             RsiPeriod                 = 14;             // RSI period
extern enRsiTypes      RsiMethod                 = rsi_rsi;        // RSI method
extern enPrices        RsiPrice                  = pr_close;       // Price to use
extern int             AveragePeriod             = 21;             // Average signal period
extern enMaTypes       AverageType               = ma_ema;         // Average signal and MA-RSI type
extern bool            ShowAverage               = true;           // Average signal are visible?
input ENUM_LINE_STYLE  Averagestyle              = STYLE_DOT;     // Average signal style?
input color            Average_color_lines       = clrLightYellow; // Average signal color
input color            UpcolorRSI                = clrSeaGreen;          // RSI UP color
input color            DncolorRSI                = clrCrimson;           // RSI DOWN color
input color            NecolorRSI                = clrGray;              // RSI NEUTRAL color
extern int             LineWidthRSI              = 2;                  // RSI Lines width
extern bool            ShowHorlev                = true;             // Horizontal Levels are visible?
input ENUM_LINE_STYLE  levelstyle                =  STYLE_DOT;       // Zero level style?
input color            Level_color_lines         = clrGray;          // Levels color
input double           LevelUp                   = 60;              // UP level ?
input double           LevelDown                 = 40;               // DOWN level ?
extern enArrowOn       ColorOn                   = cc_onRSIcrosslevel;      // Arrows on:
extern bool            AlertsOn                  = false;          // Turn alerts on?
extern bool            AlertsOnCurrent           = false;          // Alerts on still opened bar?
extern bool            AlertsMessage             = true;           // Alerts should display message?
extern bool            AlertsSound               = false;          // Alerts should play a sound?
extern bool            AlertsNotify              = false;          // Alerts should send a notification?
extern bool            AlertsEmail               = false;          // Alerts should send an email?
extern string          AlertsSoundFile           = "alert2.wav";   // Sound file
input bool             arrowsVisible             = false;              // Arrows visible true/false?
input string           arrowsIdentifier          = " RSI MA";     // Unique ID for arrows
input bool             arrowsOnNewest            = false;
input double           arrowsUpperGap            = 1;                // Upper arrow gap
input double           arrowsLowerGap            = 0.5;                // Lower arrow gap
input color            arrowsUpColor             = clrMediumSeaGreen;       // Up arrow color
input color            arrowsDnColor             = clrCrimson;          // Down arrow color
input int              arrowsUpCode              = 233;                // Up arrow code
input int              arrowsDnCode              = 234;                // Down arrow code
input int              arrowsUpSize              = 2;                  // Up arrow size
input int              arrowsDnSize              = 2;  
input bool             Interpolate               = true;                // Down arrow size

string _avgNames[]={"SMA","EMA","SMMA","LWMA","TEMA"};
double rsi[],maDa[],maDb[],maUa[],maUb[],avg[],valup[],valdn[],trend[],count[];
string indicatorFileName;
#define _mtfCall(_buff,_ind) iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiMethod,RsiPrice,AveragePeriod,AverageType,ShowAverage,Averagestyle,Average_color_lines,UpcolorRSI,DncolorRSI,NecolorRSI,LineWidthRSI,ShowHorlev,levelstyle,Level_color_lines,LevelUp,LevelDown,ColorOn,AlertsOn,AlertsOnCurrent,AlertsMessage,AlertsSound,AlertsNotify,AlertsEmail,AlertsSoundFile,arrowsVisible,arrowsIdentifier,arrowsOnNewest,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,arrowsUpSize,arrowsDnSize,_buff,_ind)

int init()
{
   IndicatorBuffers(10);
   SetIndexBuffer(0,rsi  ,INDICATOR_DATA); SetIndexStyle(0,DRAW_LINE,EMPTY,LineWidthRSI,NecolorRSI);
   SetIndexBuffer(1,maUa ,INDICATOR_DATA); SetIndexStyle(1,DRAW_LINE,EMPTY,LineWidthRSI,UpcolorRSI);
   SetIndexBuffer(2,maUb ,INDICATOR_DATA); SetIndexStyle(2,DRAW_LINE,EMPTY,LineWidthRSI,UpcolorRSI);
   SetIndexBuffer(3,maDa ,INDICATOR_DATA); SetIndexStyle(3,DRAW_LINE,EMPTY,LineWidthRSI,DncolorRSI);
   SetIndexBuffer(4,maDb ,INDICATOR_DATA); SetIndexStyle(4,DRAW_LINE,EMPTY,LineWidthRSI,DncolorRSI);
   SetIndexBuffer(5,avg  ,INDICATOR_DATA); SetIndexStyle(5, ShowAverage ? DRAW_LINE :  DRAW_NONE,Averagestyle,0,Average_color_lines);
   SetIndexBuffer(6,valup,INDICATOR_DATA); SetIndexStyle(6, ShowHorlev  ? DRAW_LINE :  DRAW_NONE,levelstyle  ,0,Level_color_lines);
   SetIndexBuffer(7,valdn,INDICATOR_DATA); SetIndexStyle(7, ShowHorlev  ? DRAW_LINE :  DRAW_NONE,levelstyle  ,0,Level_color_lines);
   SetIndexBuffer(8,trend);
   SetIndexBuffer(9,count);
   
   RsiPeriod = fmax(RsiPeriod ,1);
   indicatorFileName = WindowExpertName();
   TimeFrame         = (enTimeFrames)timeFrameValue(TimeFrame);
  
   IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(TimeFrame)+ " Rsi Ma simple");
return(0);
}
int deinit() {  deleteArrows();   return(0); }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   
int start()
{ 
   int counted_bars=IndicatorCounted();
   int i,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1); count[0] = limit;
         
         //
         //
         //
         
         if (TimeFrame!=_Period)
         {
            limit = (int)fmax(limit,fmin(Bars-1,_mtfCall(9,0)*TimeFrame/_Period));
            if (trend[limit]== 1) CleanPoint(limit,maUa,maUb);
            if (trend[limit]==-1) CleanPoint(limit,maDa,maDb); 
            for(i=limit; i>=0 && !_StopFlag; i--)
            {
               int y = iBarShift(NULL,TimeFrame,Time[i]);
                  rsi[i]   = _mtfCall(0,y);
                  avg[i]   = _mtfCall(5,y);
                  valup[i] = LevelUp;
                  valdn[i] = LevelDown;
                  maDa[i]  = maDb[i] = maUa[i] = maUb[i] = EMPTY_VALUE;
                  trend[i] = _mtfCall(8,y);
              
                  //
                  //
                  //
                     
                  if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1]))) continue;
                    #define _interpolate(buff) buff[i+k] = buff[i]+(buff[i+n]-buff[i])*k/n
                    int n,k; datetime btime = iTime(NULL,TimeFrame,y);
                       for(n = 1; (i+n)<Bars && Time[i+n] >= btime; n++) continue;	
                       for(k = 1; k<n && (i+n)<Bars && (i+k)<Bars; k++) 
                       {
                          _interpolate(rsi);   
                          _interpolate(avg); 
                       }                         
         }
         for (i=limit; i >= 0; i--)
         {
            if (trend[i]==-1) PlotPoint(i,maDa,maDb,rsi);
            if (trend[i]== 1) PlotPoint(i,maUa,maUb,rsi);
	      }    
   return(0);
   }         
            
   //
   //
   //
   //
   //
   
 
   if (trend[limit]== 1) CleanPoint(limit,maUa,maUb);
   if (trend[limit]==-1) CleanPoint(limit,maDa,maDb);         
   for(i=limit; i>=0; i--)
   { 
      rsi[i] = iRsi(RsiMethod,iCustomMa(AverageType,getPrice(RsiPrice,Open,Close,High,Low,i,Bars),RsiPeriod,i,Bars,0),RsiPeriod,i);
      avg[i] = iCustomMa(AverageType,rsi[i],AveragePeriod,i,Bars,1);                                  
      valup[i] = LevelUp;
      valdn[i] = LevelDown;
    
    
    switch(ColorOn)
   {
     case cc_onRSIcrosslevel:  trend[i] = (rsi[i] > LevelUp) ? 1 : (rsi[i] < LevelDown) ? -1 :  0;  break;
     case cc_onRSIcross50level:trend[i] = (rsi[i] > 50) ? 1 : (rsi[i] < 50) ? -1 :  0;  break;
     case cc_RSIcrossMA    :   trend[i] = (i<Bars-1) ? (rsi[i] > avg[i]) ? 1 : (rsi[i] < avg[i]) ? -1 : trend[i+1] : 0;  break;
     default   : if (i<Bars-1) trend[i] = (i<Bars-1) ? (rsi[i] > rsi[i+1]) ? 1 : (rsi[i] < rsi[i+1]) ? -1 : trend[i+1] : 0; 
   }
   maDa[i] = maDb[i] = maUa[i] = maUb[i] = EMPTY_VALUE;
   if (trend[i]==-1) PlotPoint(i,maDa,maDb,rsi);
   if (trend[i]== 1) PlotPoint(i,maUa,maUb,rsi);
             
                          
     
   if (arrowsVisible)
   {
     string lookFor = arrowsIdentifier+":"+(string)Time[i]; ObjectDelete(lookFor);            
     if (i<(Bars-1) && trend[i] != trend[i+1])
     {
       if (trend[i] == 1) drawArrow(i,arrowsUpColor,arrowsUpCode,arrowsUpSize,false);
       if (trend[i] ==-1) drawArrow(i,arrowsDnColor,arrowsDnCode,arrowsDnSize, true);  
     }
   }     
   } 
   if (AlertsOn)
   {
      int whichBar = 1; if (AlertsOnCurrent) whichBar = 0; 
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] == 1)  doAlert(" up");
         if (trend[whichBar] ==-1)  doAlert(" down");       
              
      }         
   }      
return(0);
}
   
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

#define _maInstances 2
#define _maWorkBufferx1 _maInstances
#define _maWorkBufferx3 _maInstances*3
double iCustomMa(int mode, double price, double length, int r, int bars, int instanceNo=0)
{
   bars = Bars; r=bars-r-1;
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

double workSma[][_maWorkBufferx1];
double iSma(double price, int period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= _bars) ArrayResize(workSma,_bars);

   workSma[r][instanceNo+0] = price;
   double sma = price;  int k=1; for(; k<period && (r-k)>=0; k++) sma += workSma[r-k][instanceNo+0];  sma /= (double)k;
   return(sma);
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
   
   workLwma[r][instanceNo] = price; if (period<1) return(price);
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
   if (ArrayRange(workTema,0)!= bars) ArrayResize(workTema,bars); instanceNo*=3;

   //
   //
   //
   //
   //
      
   workTema[r][_tema1+instanceNo] = price;
   workTema[r][_tema2+instanceNo] = price;
   workTema[r][_tema3+instanceNo] = price;
   if (r>0 && period>1)
   {
      double alpha = 2.0 / (1.0+period);
          workTema[r][_tema1+instanceNo] = workTema[r-1][_tema1+instanceNo]+alpha*(price                         -workTema[r-1][_tema1+instanceNo]);
          workTema[r][_tema2+instanceNo] = workTema[r-1][_tema2+instanceNo]+alpha*(workTema[r][_tema1+instanceNo]-workTema[r-1][_tema2+instanceNo]);
          workTema[r][_tema3+instanceNo] = workTema[r-1][_tema3+instanceNo]+alpha*(workTema[r][_tema2+instanceNo]-workTema[r-1][_tema3+instanceNo]); }
   return(workTema[r][_tema3+instanceNo]+3.0*(workTema[r][_tema1+instanceNo]-workTema[r][_tema2+instanceNo]));
}  
 
//
//
//
//
//

string rsiMethodNames[] = {"RSI","Slow RSI","Rapid RSI","Harris RSI","RSX","Cuttler RSI"};
string getRsiName(int method)
{
   int max = ArraySize(rsiMethodNames)-1;
      method=fmax(fmin(method,max),0); return(rsiMethodNames[method]);
}

//
//
//
//
//

#define rsiInstances 1
double workRsi[][rsiInstances*13];
#define _price  0
#define _change 1
#define _changa 2
#define _rsival 1
#define _rsval  1

double iRsi(int rsiMode, double price, double period, int i, int instanceNo=0)
{
   if (ArrayRange(workRsi,0)!=Bars) ArrayResize(workRsi,Bars);
      int z = instanceNo*13; 
      int r = Bars-i-1;
   
   //
   //
   //
   //
   //
   
   workRsi[r][z+_price] = price;
   switch (rsiMode)
   {
      case rsi_rsi:
         {
         double alpha = 1.0/fmax(period,1); 
         if (r<period)
            {
               int k; double sum = 0; for (k=0; k<period && (r-k-1)>=0; k++) sum += fabs(workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price]);
                  workRsi[r][z+_change] = (workRsi[r][z+_price]-workRsi[0][z+_price])/fmax(k,1);
                  workRsi[r][z+_changa] =                                         sum/fmax(k,1);
            }
         else
            {
               double change = workRsi[r][z+_price]-workRsi[r-1][z+_price];
                               workRsi[r][z+_change] = workRsi[r-1][z+_change] + alpha*(     change  - workRsi[r-1][z+_change]);
                               workRsi[r][z+_changa] = workRsi[r-1][z+_changa] + alpha*(fabs(change) - workRsi[r-1][z+_changa]);
            }
         if (workRsi[r][z+_changa] != 0)
               return(50.0*(workRsi[r][z+_change]/workRsi[r][z+_changa]+1));
         else  return(50.0);
         }
         
      //
      //
      //
      //
      //
      
      case rsi_wil :
         {         
            double up = 0;
            double dn = 0;
            for(k=0; k<(int)period && (r-k-1)>=0; k++)
            {
               double diff = workRsi[r-k][z+_price]- workRsi[r-k-1][z+_price];
               if(diff>0)
                     up += diff;
               else  dn -= diff;
            }
            if (r<1)
                  workRsi[r][z+_rsival] = 50;
            else               
               if(up + dn == 0)
                     workRsi[r][z+_rsival] = workRsi[r-1][z+_rsival]+(1/fmax(period,1))*(50            -workRsi[r-1][z+_rsival]);
               else  workRsi[r][z+_rsival] = workRsi[r-1][z+_rsival]+(1/fmax(period,1))*(100*up/(up+dn)-workRsi[r-1][z+_rsival]);
            return(workRsi[r][z+_rsival]);      
         }
      
      //
      //
      //
      //
      //

      case rsi_rap :
         {
            up = 0;
            dn = 0;
            for(k=0; k<(int)period && (r-k-1)>=0; k++)
            {
               diff = workRsi[r-k][z+_price]- workRsi[r-k-1][z+_price];
               if(diff>0)
                     up += diff;
               else  dn -= diff;
            }
            if(up + dn == 0)
                  return(50);
            else  return(100 * up / (up + dn));      
         }            

      //
      //
      //
      //
      //

      
      case rsi_har :
         {
            double avgUp=0,avgDn=0; up=0; dn=0;
            for(k=0; k<(int)period && (r-k-1)>=0; k++)
            {
               diff = workRsi[r-k][instanceNo+_price]- workRsi[r-k-1][instanceNo+_price];
               if(diff>0)
                     { avgUp += diff; up++; }
               else  { avgDn -= diff; dn++; }
            }
            if (up!=0) avgUp /= up;
            if (dn!=0) avgDn /= dn;
            double rs = 1;
               if (avgDn!=0) rs = avgUp/avgDn;
               return(100-100/(1.0+rs));
         }               

      //
      //
      //
      //
      //
      
      case rsi_rsx :  
         {   
            double Kg = (3.0)/(2.0+period), Hg = 1.0-Kg;
            if (r<period) { for (k=1; k<13; k++) workRsi[r][k+z] = 0; return(50); }  

            //
            //
            //
            //
            //
      
            double mom = workRsi[r][_price+z]-workRsi[r-1][_price+z];
            double moa = fabs(mom);
            for (k=0; k<3; k++)
            {
               int kk = k*2;
               workRsi[r][z+kk+1] = Kg*mom                + Hg*workRsi[r-1][z+kk+1];
               workRsi[r][z+kk+2] = Kg*workRsi[r][z+kk+1] + Hg*workRsi[r-1][z+kk+2]; mom = 1.5*workRsi[r][z+kk+1] - 0.5 * workRsi[r][z+kk+2];
               workRsi[r][z+kk+7] = Kg*moa                + Hg*workRsi[r-1][z+kk+7];
               workRsi[r][z+kk+8] = Kg*workRsi[r][z+kk+7] + Hg*workRsi[r-1][z+kk+8]; moa = 1.5*workRsi[r][z+kk+7] - 0.5 * workRsi[r][z+kk+8];
            }
            if (moa != 0)
                 return(fmax(fmin((mom/moa+1.0)*50.0,100.00),0.00)); 
            else return(50);
         }            
            
      //
      //
      //
      //
      //
      
      case rsi_cut :
         {
            double sump = 0;
            double sumn = 0;
            for (k=0; k<(int)period && r-k-1>=0; k++)
            {
               diff = workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price];
                  if (diff > 0) sump += diff;
                  if (diff < 0) sumn -= diff;
            }
            if (sumn > 0)
                  return(100.0-100.0/(1.0+sump/sumn));
            else  return(50);
         }            
   } 
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

#define _prHABF(_prtype) (_prtype>=pr_habclose && _prtype<=pr_habtbiased2)
#define _priceInstances     1
#define _priceInstancesSize 4
double workHa[][_priceInstances*_priceInstancesSize];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars); instanceNo*=_priceInstancesSize; int r = bars-i-1;
         
         //
         //
         //
         //
         //
         
         double haOpen  = (r>0) ? (workHa[r-1][instanceNo+2] + workHa[r-1][instanceNo+3])/2.0 : (open[i]+close[i])/2;;
         double haClose = (open[i]+high[i]+low[i]+close[i]) / 4.0;
         if (_prHABF(tprice))
               if (high[i]!=low[i])
                     haClose = (open[i]+close[i])/2.0+(((close[i]-open[i])/(high[i]-low[i]))*fabs((close[i]-open[i])/2.0));
               else  haClose = (open[i]+close[i])/2.0; 
         double haHigh  = fmax(high[i], fmax(haOpen,haClose));
         double haLow   = fmin(low[i] , fmin(haOpen,haClose));

         //
         //
         //
         //
         //
         
         if(haOpen<haClose) { workHa[r][instanceNo+0] = haLow;  workHa[r][instanceNo+1] = haHigh; } 
         else               { workHa[r][instanceNo+0] = haHigh; workHa[r][instanceNo+1] = haLow;  } 
                              workHa[r][instanceNo+2] = haOpen;
                              workHa[r][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (tprice)
         {
            case pr_haclose:
            case pr_habclose:    return(haClose);
            case pr_haopen:   
            case pr_habopen:     return(haOpen);
            case pr_hahigh: 
            case pr_habhigh:     return(haHigh);
            case pr_halow:    
            case pr_hablow:      return(haLow);
            case pr_hamedian:
            case pr_habmedian:   return((haHigh+haLow)/2.0);
            case pr_hamedianb:
            case pr_habmedianb:  return((haOpen+haClose)/2.0);
            case pr_hatypical:
            case pr_habtypical:  return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:
            case pr_habweighted: return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:  
            case pr_habaverage:  return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
            case pr_habtbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
            case pr_habtbiased2:
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

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}
int timeFrameValue(int _tf)
{
   int add  = (_tf>=0) ? 0 : fabs(_tf);
   if (add != 0) _tf = _Period;
   int size = ArraySize(iTfTable); 
      int i =0; for (;i<size; i++) if (iTfTable[i]==_tf) break;
                                   if (i==size) return(_Period);
                                                return(iTfTable[(int)fmin(i+add,size-1)]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//

void doAlert(string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   
      if (previousAlert != doWhat || previousTime != Time[0]) 
      {
          previousAlert  = doWhat;
          previousTime   = Time[0];

          //
          //
          //
          //
          //

          string message = timeFrameToString(_Period)+" "+_Symbol+" at  RSI MA : "+doWhat;
             if (AlertsMessage) Alert(message);
             if (AlertsNotify)  SendNotification(message);
             if (AlertsEmail)   SendMail(_Symbol+" RSI MA ",message);
             if (AlertsSound)   PlaySound(AlertsSoundFile);
      }
}

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
//
//
//
//
//
void drawArrow(int i,color theColor,int theCode, int theSize, bool up)
{
   string name = arrowsIdentifier+":"+(string)Time[i];
   double gap  = iATR(NULL,0,20,i);   
   
      //
      //
      //
      //
      //

      datetime time = Time[i]; if (arrowsOnNewest) time += _Period*60-1;      
      ObjectCreate(name,OBJ_ARROW,0,Time[i],0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_WIDTH,    theSize);
         ObjectSet(name,OBJPROP_COLOR,    theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsUpperGap * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsLowerGap * gap);
}

void deleteArrows()
{
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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



//
//
//
//
//

