//------------------------------------------------------------------
#property copyright "mladen"
#property link      "mladenfx@gmail.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_color1  LimeGreen
#property indicator_color2  Orange
#property indicator_color3  Orange
#property indicator_color4  LimeGreen
#property indicator_color5  Orange
#property indicator_width1  3
#property indicator_width2  3
#property indicator_width3  3

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
enum enInterpolation
{
   int_noint, // No interpolation
   int_line,  // Linear interpolation
   int_quad   // Quadratic interpolation
};

//
//
//
//
//

extern ENUM_TIMEFRAMES TimeFrame                 = PERIOD_CURRENT;
extern double          RsiPeriod                 = 3;
extern enPrices        RsiPrice                  = pr_haclose;
extern int             RsiDepth                  = 6;
extern bool            RsiFast                   = false;
extern int             StochasticLength          = 14;
extern int             SmoothEMA                 = 5;
extern enPrices        VolatilityPrice           = pr_close;
extern int             VolatilityPeriod          = 5;
extern int             VolatilitySmooth          = 10;
extern bool            AdjustRsiPeriod           = true;
extern bool            AdjustStochasticPeriod    = true;
extern bool            drawDivergences           = true;
extern int             DivergearrowSize          = 2.0;
extern double          DivergencearrowsUpperGap  = 0.1;
extern double          DivergencearrowsLowerGap  = 0.1;
extern bool            ShowClassicalDivergence   = true;
extern bool            ShowHiddenDivergence      = true;
extern bool            drawIndicatorTrendLines   = false;
extern bool            drawPriceTrendLines       = false;
extern string          drawLinesIdentificator    = "Dssdiverge1";
extern color           divergenceBullishColor    = Lime;
extern color           divergenceBearishColor    = Magenta;
extern bool            divergenceAlert           = true;
extern bool            divergenceAlertsMessage   = true;
extern bool            divergenceAlertsSound     = true;
extern bool            divergenceAlertsEmail     = false;
extern bool            divergenceAlertsNotify    = false;
extern string          divergenceAlertsSoundName = "alert1.wav";
extern bool            alertsOn                  = false;
extern bool            alertsOnCurrent           = true;
extern bool            alertsMessage             = true;
extern bool            alertsSound               = false;
extern bool            alertsEmail               = false;
extern bool            alertsNotify              = false;
extern string          soundFile                 = "alert2.wav";
extern enInterpolation Interpolate               = int_line;


double dssBuffer[];
double ddaBuffer[];
double ddbBuffer[];
double bullishDivergence[];
double bearishDivergence[];
double trend[];
double price[];
double sum[];

string indicatorFileName;
bool   returnBars;
string indicatorName;
string labelNames;

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int init()
{
   IndicatorBuffers(8);
   SetIndexBuffer(0,dssBuffer);
   SetIndexBuffer(1,ddaBuffer);
   SetIndexBuffer(2,ddbBuffer);
   SetIndexBuffer(3,bullishDivergence); SetIndexStyle(3,DRAW_ARROW,0,DivergearrowSize); SetIndexArrow(3,233);
   SetIndexBuffer(4,bearishDivergence); SetIndexStyle(4,DRAW_ARROW,0,DivergearrowSize); SetIndexArrow(4,234);  
   SetIndexBuffer(5,trend);
   SetIndexBuffer(6,price);
   SetIndexBuffer(7,sum);
      RsiDepth          = MathMax(MathMin(RsiDepth,25),2);
      StochasticLength  = MathMax(1,StochasticLength);
      SmoothEMA         = MathMax(1,SmoothEMA);
      indicatorFileName = WindowExpertName();
      returnBars        = TimeFrame==-99; 
      TimeFrame         = MathMax(TimeFrame,_Period);
      labelNames        = "Dss Bressert CRSI_DivergenceLine "+drawLinesIdentificator+":";
      indicatorName     = timeFrameToString(TimeFrame)+" DSS Bressert of Composite RSI ("+DoubleToStr(RsiPeriod,1)+","+RsiDepth+","+StochasticLength+","+SmoothEMA+")";
IndicatorShortName(indicatorName);
return(0);
}
int deinit()
{  
   int length=StringLen(labelNames);
   for(int i=ObjectsTotal()-1; i>=0; i--)
   {
      string name = ObjectName(i);
      if(StringSubstr(name,0,length) == labelNames)  ObjectDelete(name);   
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

int start()
{
   int k,counted_bars=IndicatorCounted();
      if(counted_bars < 0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { dssBuffer[0] = limit+1; return(0); }
         if (TimeFrame != _Period)
         {
            limit = (int)MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
            if (trend[limit]==-1) CleanPoint(limit,ddaBuffer,ddbBuffer);
            for (int i=limit; i>=0; i--)
            {
               int y = iBarShift(NULL,TimeFrame,Time[i]);
                  dssBuffer[i]         = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiPrice,RsiDepth,RsiFast,StochasticLength,SmoothEMA,VolatilityPrice,VolatilityPeriod,VolatilitySmooth,AdjustRsiPeriod,AdjustStochasticPeriod,drawDivergences,DivergearrowSize,DivergencearrowsUpperGap,DivergencearrowsLowerGap,ShowClassicalDivergence,ShowHiddenDivergence,drawIndicatorTrendLines,drawPriceTrendLines,drawLinesIdentificator,divergenceBullishColor,divergenceBearishColor,divergenceAlert,divergenceAlertsMessage,divergenceAlertsSound,divergenceAlertsEmail,divergenceAlertsNotify,divergenceAlertsSoundName,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,soundFile,0,y);
                  trend[i]             = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiPrice,RsiDepth,RsiFast,StochasticLength,SmoothEMA,VolatilityPrice,VolatilityPeriod,VolatilitySmooth,AdjustRsiPeriod,AdjustStochasticPeriod,drawDivergences,DivergearrowSize,DivergencearrowsUpperGap,DivergencearrowsLowerGap,ShowClassicalDivergence,ShowHiddenDivergence,drawIndicatorTrendLines,drawPriceTrendLines,drawLinesIdentificator,divergenceBullishColor,divergenceBearishColor,divergenceAlert,divergenceAlertsMessage,divergenceAlertsSound,divergenceAlertsEmail,divergenceAlertsNotify,divergenceAlertsSoundName,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,soundFile,5,y);
                  ddaBuffer[i]         = EMPTY_VALUE;   
                  ddbBuffer[i]         = EMPTY_VALUE;
                  bullishDivergence[i] = EMPTY_VALUE;
                  bearishDivergence[i] = EMPTY_VALUE;
               int firstBar = iBarShift(NULL,0,iTime(NULL,TimeFrame,y));
               if (i==firstBar)
               {
                  bullishDivergence[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiPrice,RsiDepth,RsiFast,StochasticLength,SmoothEMA,VolatilityPrice,VolatilityPeriod,VolatilitySmooth,AdjustRsiPeriod,AdjustStochasticPeriod,drawDivergences,DivergearrowSize,DivergencearrowsUpperGap,DivergencearrowsLowerGap,ShowClassicalDivergence,ShowHiddenDivergence,drawIndicatorTrendLines,drawPriceTrendLines,drawLinesIdentificator,divergenceBullishColor,divergenceBearishColor,divergenceAlert,divergenceAlertsMessage,divergenceAlertsSound,divergenceAlertsEmail,divergenceAlertsNotify,divergenceAlertsSoundName,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,soundFile,3,y);
                  bearishDivergence[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiPrice,RsiDepth,RsiFast,StochasticLength,SmoothEMA,VolatilityPrice,VolatilityPeriod,VolatilitySmooth,AdjustRsiPeriod,AdjustStochasticPeriod,drawDivergences,DivergearrowSize,DivergencearrowsUpperGap,DivergencearrowsLowerGap,ShowClassicalDivergence,ShowHiddenDivergence,drawIndicatorTrendLines,drawPriceTrendLines,drawLinesIdentificator,divergenceBullishColor,divergenceBearishColor,divergenceAlert,divergenceAlertsMessage,divergenceAlertsSound,divergenceAlertsEmail,divergenceAlertsNotify,divergenceAlertsSoundName,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,soundFile,4,y);
               }
                  if (!Interpolate || y==iBarShift(NULL,TimeFrame,Time[i-1])) continue;
                     interpolate(dssBuffer,TimeFrame,i,Interpolate);
            }
            for (i=limit; i>=0; i--) if (trend[i]==-1) PlotPoint(i,ddaBuffer,ddbBuffer,dssBuffer); 
            return(0);            
         }
   
   //
   //
   //
   //
   //
   
   if (trend[limit]==-1) CleanPoint(limit,ddaBuffer,ddbBuffer);
 	for(i = limit; i>=0; i--)
 	{
      price[i]   =  getPrice(VolatilityPrice,Open,Close,High,Low,i);
      sum[i]     =  0;       for (k = 0; k<VolatilityPeriod; k++) sum[i] += MathAbs(price[i+k]-price[i+k+1]);
      double avg =  sum[i];  for (k = 1; k<VolatilitySmooth; k++) avg    += sum[i+k];
             avg /= VolatilitySmooth;
         
                //
                //
                //
                //
                //
                
                if (AdjustRsiPeriod && avg!=0 && sum[i]!=0)
                     double rsiPer = MathMin(MathMax(RsiPeriod/(sum[i]/avg),RsiPeriod/2.0),RsiPeriod*5.0);
                else        rsiPer = RsiPeriod;
                if (AdjustStochasticPeriod && avg!=0 && sum[i]!=0)
                     double stoPer = MathMin(MathMax(RsiPeriod/(sum[i]/avg),StochasticLength/2.0),StochasticLength*5.0);
                else        stoPer = StochasticLength;
 	    double rsi = iCompRsi(price[i],rsiPer,RsiDepth,RsiFast,i);
 	       dssBuffer[i] = iDss(rsi,rsi,rsi,stoPer,SmoothEMA,i);
 	       ddaBuffer[i] = EMPTY_VALUE;   
          ddbBuffer[i] = EMPTY_VALUE;
          trend[i]     = trend[i+1];
            if (dssBuffer[i]>dssBuffer[i+1]) trend[i] =  1;
            if (dssBuffer[i]<dssBuffer[i+1]) trend[i] = -1;  
            if (trend[i]==-1) PlotPoint(i,ddaBuffer,ddbBuffer,dssBuffer); 
            if (drawDivergences)
            {
              CatchBullishDivergence(i);
              CatchBearishDivergence(i);
            }            
   } 
   
   //
   //
   //
   //
   //
      
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1;
      if (trend[whichBar] != trend[whichBar+1])
      if (trend[whichBar] == 1)
            doAlert("Buy");
      else  doAlert("Sell");       
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

void interpolate(double& target[], int ptimeFrame, int i, int interpolateType)
{
   int bar = iBarShift(NULL,ptimeFrame,Time[i]); double x0 = 0, x1 = 1, x2 = 2, y0 =0, y1 = 0, y2 = 0;
   if (interpolateType==int_quad)
   {
      y0 = target[i];                                                
      y1 = target[(int)MathMin(iBarShift(NULL,0,iTime(NULL,ptimeFrame,bar+0))+1,Bars-1)]; 
      y2 = target[(int)MathMin(iBarShift(NULL,0,iTime(NULL,ptimeFrame,bar+1))+1,Bars-1)]; 
   }      

      //
      //
      //
      //
      //

      datetime time = iTime(NULL,ptimeFrame,bar);
      int n,k;
         for(n = 1; (i+n)<Bars && Time[i+n] >= time; n++) continue;
         for(k = 1; (i+n)<Bars && (i+k)<Bars && k<n; k++)
         if (interpolateType==int_quad)
         {
            double x3 = (double)k/n;
               target[i+k]  = y0*(x3-x1)*(x3-x2)/(-x1*(-x2))+
                              y1*(x3-x0)*(x3-x2)/( x1*(-x1))+
		                        y2*(x3-x0)*(x3-x1)/( x2*( x1));         
         }
         else target[i+k] = target[i] + (target[i+n] - target[i])*k/n;
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workCompRsi[][26];

//
//
//
//
//

double iCompRsi(double tprice, double period, int depth, bool fast, int i, int instanceNo=0)
{
   if (ArrayRange(workCompRsi,0) !=Bars) ArrayResize(workCompRsi,Bars);
   if (!fast)
        double alpha = 2.0/(1.0 + period);
   else        alpha = 2.0/(2.0 + (period-1.0)/2.0);
   instanceNo *= 26; i = Bars-i-1;
   
   //
   //
   //
   //
   //
   
   double CU = 0;
   double CD = 0;
   for (int k=0; k<=depth; k++)
   {
      if (i == 0)
            workCompRsi[i][instanceNo+k] = tprice;
      else  workCompRsi[i][instanceNo+k] = workCompRsi[i-1][instanceNo+k]+alpha*(tprice-workCompRsi[i-1][instanceNo+k]);

      //
      //
      //
      //
      //
         
      tprice = workCompRsi[i][k+instanceNo];
      if (k>0)
         if (workCompRsi[i][instanceNo+k-1] >= workCompRsi[i][instanceNo+k])
              CU += workCompRsi[i][instanceNo+k-1] - workCompRsi[i][instanceNo+k  ];
         else CD += workCompRsi[i][instanceNo+k  ] - workCompRsi[i][instanceNo+k-1];
   }
   double rsi = 0; if (CU + CD != 0) rsi = CU / (CU + CD); 
   return(rsi);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workDss[][5];
#define _st1    0
#define _ss1    1
#define _pHigh  2
#define _pLow   3
#define _dss    4

double iDss(double close, double high, double low, int length, double smooth, int r)
{
   if (ArrayRange(workDss,0)!=Bars) ArrayResize(workDss,Bars); r=Bars-r-1;
   
   //
   //
   //
   //
   //
   
      double alpha = 2.0 / (1.0+smooth);
         workDss[r][_pHigh]  = high;
         workDss[r][_pLow]   = low;
     
         double min = workDss[r][_pLow];
         double max = workDss[r][_pHigh];
         for (int k=1; k<length && (r-k)>=0; k++)
         {
            min = MathMin(min,workDss[r-k][_pLow]);
            max = MathMax(max,workDss[r-k][_pHigh]);
         }
      
         workDss[r][_st1] = 0;
               if (min!=max) workDss[r][_st1] = 100*(close-min)/(max-min);
         workDss[r][_ss1] = workDss[r-1][_ss1]+alpha*(workDss[r][_st1]-workDss[r-1][_ss1]);

         //
         //
         //
         //
         //
         
         min = workDss[r][_ss1];
         max = workDss[r][_ss1];
         for (k=1; k<length && (r-k)>=0; k++)
         {
            min = MathMin(min,workDss[r-k][_ss1]);
            max = MathMax(max,workDss[r-k][_ss1]);
         }
         double stoch = 0; if (min!=max) stoch = 100*(workDss[r][_ss1]-min)/(max-min);
         
         //
         //
         //
         //
         //
         
         workDss[r][_dss] = workDss[r-1][_dss]+alpha*(stoch -workDss[r-1][_dss]);
   return(workDss[r][_dss]);
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

void CleanPoint(int i,double& first[],double& second[])
{
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

//
//
//
//
//

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (first[i+1] == EMPTY_VALUE)
      {
         if (first[i+2] == EMPTY_VALUE) {
                first[i]   = from[i];
                first[i+1] = from[i+1];
                second[i]  = EMPTY_VALUE;
            }
         else {
                second[i]   =  from[i];
                second[i+1] =  from[i+1];
                first[i]    = EMPTY_VALUE;
            }
      }
   else
      {
         first[i]  = from[i];
         second[i] = EMPTY_VALUE;
      }
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

          message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," DSS Bressert composite rsi ",doWhat);
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol()," DSS Bressert composite rsi "),message);
             if (alertsSound)   PlaySound(soundFile);
      }
}

//
//
//
//
//

void CatchBullishDivergence(int shift)
{
   shift++;
         bullishDivergence[shift] = EMPTY_VALUE;
            ObjectDelete(labelNames+"l"+DoubleToStr(Time[shift],0));
            ObjectDelete(labelNames+"l"+"os" + DoubleToStr(Time[shift],0));            
   if(!IsIndicatorLow(shift)) return;  
   int currentLow = shift;
   int lastLow    = GetIndicatorLastLow(shift+1);
   
   //
   //
   //
   //
   //
   
   if (dssBuffer[currentLow] > dssBuffer[lastLow] && Low[currentLow] < Low[lastLow])
   {
     if (ShowClassicalDivergence)
     {
        bullishDivergence[currentLow] = dssBuffer[currentLow] - DivergencearrowsLowerGap;
        if (drawPriceTrendLines)    DrawPriceTrendLine("l",Time[currentLow],Time[lastLow],Low[currentLow],Low[lastLow],                divergenceBullishColor,STYLE_SOLID);
        if (drawIndicatorTrendLines)DrawIndicatorTrendLine("l",Time[currentLow],Time[lastLow],dssBuffer[currentLow],dssBuffer[lastLow],divergenceBullishColor,STYLE_SOLID);
        if (divergenceAlert)        DisplayAlert("Classical bullish divergence",currentLow);  
     }
                        
   }
     
   //
   //
   //
   //
   //
        
   if (dssBuffer[currentLow] < dssBuffer[lastLow] && Low[currentLow] > Low[lastLow])
   {
     if (ShowHiddenDivergence)
     {
        bullishDivergence[currentLow] = dssBuffer[currentLow] - DivergencearrowsLowerGap;
        if (drawPriceTrendLines)     DrawPriceTrendLine("l",Time[currentLow],Time[lastLow],Low[currentLow],Low[lastLow],                divergenceBullishColor, STYLE_DOT);
        if (drawIndicatorTrendLines) DrawIndicatorTrendLine("l",Time[currentLow],Time[lastLow],dssBuffer[currentLow],dssBuffer[lastLow],divergenceBullishColor, STYLE_DOT);
        if (divergenceAlert)         DisplayAlert("Reverse bullish divergence",currentLow); 
     }
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

void CatchBearishDivergence(int shift)
{
   shift++; 
         bearishDivergence[shift] = EMPTY_VALUE;
            ObjectDelete(labelNames+"h"+DoubleToStr(Time[shift],0));
            ObjectDelete(labelNames+"h"+"os" + DoubleToStr(Time[shift],0));            
   if(!IsIndicatorPeak(shift)) return;
   int currentPeak = shift;
   int lastPeak    = GetIndicatorLastPeak(shift+1);

   //
   //
   //
   //
   //
      
   if (dssBuffer[currentPeak] < dssBuffer[lastPeak] && High[currentPeak]>High[lastPeak])
   {
     if (ShowClassicalDivergence)
     {
        bearishDivergence[currentPeak] = dssBuffer[currentPeak] + DivergencearrowsUpperGap;
        if (drawPriceTrendLines)     DrawPriceTrendLine("h",Time[currentPeak],Time[lastPeak],High[currentPeak],High[lastPeak],              divergenceBearishColor,STYLE_SOLID);
        if (drawIndicatorTrendLines) DrawIndicatorTrendLine("h",Time[currentPeak],Time[lastPeak],dssBuffer[currentPeak],dssBuffer[lastPeak],divergenceBearishColor,STYLE_SOLID);
        if (divergenceAlert)         DisplayAlert("Classical bearish divergence",currentPeak);
     } 
                        
   }
   
   //
   //
   //
   //
   //

   if (dssBuffer[currentPeak] > dssBuffer[lastPeak] && High[currentPeak] < High[lastPeak])
   {
     if (ShowHiddenDivergence)
     {
        bearishDivergence[currentPeak] = dssBuffer[currentPeak] + DivergencearrowsUpperGap;
        if (drawPriceTrendLines)     DrawPriceTrendLine("h",Time[currentPeak],Time[lastPeak],High[currentPeak],High[lastPeak],              divergenceBearishColor, STYLE_DOT);
        if (drawIndicatorTrendLines) DrawIndicatorTrendLine("h",Time[currentPeak],Time[lastPeak],dssBuffer[currentPeak],dssBuffer[lastPeak],divergenceBearishColor, STYLE_DOT);
        if (divergenceAlert)         DisplayAlert("Reverse bearish divergence",currentPeak);
     }
                         
   }   
}

//
//
//
//
//

bool IsIndicatorPeak(int shift)
{
   if(dssBuffer[shift] >= dssBuffer[shift+1] && dssBuffer[shift] > dssBuffer[shift+2] && dssBuffer[shift] > dssBuffer[shift-1])
       return(true);
   else 
       return(false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//

bool IsIndicatorLow(int shift)
{
   if(dssBuffer[shift] <= dssBuffer[shift+1] && dssBuffer[shift] < dssBuffer[shift+2] && dssBuffer[shift] < dssBuffer[shift-1])
       return(true);
   else 
       return(false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//

int GetIndicatorLastPeak(int shift)
{
    for(int i = shift+5; i < Bars; i++)
    {
       if(dssBuffer[i] >= dssBuffer[i+1] && dssBuffer[i] > dssBuffer[i+2] && dssBuffer[i] >= dssBuffer[i-1] && dssBuffer[i] > dssBuffer[i-2])
    return(i);
    }
return(-1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//

int GetIndicatorLastLow(int shift)
{
    for (int i = shift+5; i < Bars; i++)
    {
       if (dssBuffer[i] <= dssBuffer[i+1] && dssBuffer[i] < dssBuffer[i+2] && dssBuffer[i] <= dssBuffer[i-1] && dssBuffer[i] < dssBuffer[i-2])
    return(i);
    }
     
return(-1);
}

//
//
//
//
//

void DisplayAlert(string doWhat, int shift)
{
    string dmessage;
    static datetime lastAlertTime;
    if(shift <= 2 && Time[0] != lastAlertTime)
    {
      dmessage =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," DSS Bressert - composite rsi ",doWhat);
          if (divergenceAlertsMessage) Alert(dmessage);
          if (divergenceAlertsNotify)  SendNotification(dmessage);
          if (divergenceAlertsEmail)   SendMail(StringConcatenate(Symbol()," DSS Bressert - composite rsi  "),dmessage);
          if (divergenceAlertsSound)   PlaySound(divergenceAlertsSoundName); 
          lastAlertTime = Time[0];
    }
}

//
//
//
//
//

void DrawPriceTrendLine(string first,datetime t1, datetime t2, double p1, double p2, color lineColor, double style)
{
    string label = labelNames+first+"os"+DoubleToStr(t1,0);
      ObjectDelete(label);
      ObjectCreate(label, OBJ_TREND, 0, t1, p1, t2, p2, 0, 0);
         ObjectSet(label, OBJPROP_RAY, 0);
         ObjectSet(label, OBJPROP_COLOR, lineColor);
         ObjectSet(label, OBJPROP_STYLE, style);
}

//
//
//
//
//

void DrawIndicatorTrendLine(string first,datetime t1, datetime t2, double p1, double p2, color lineColor, double style)
{
    int indicatorWindow = WindowFind(indicatorName);
    if (indicatorWindow < 0) return;
    
    //
    //
    //
    //
    //
    
    string label = labelNames+first+DoubleToStr(t1,0);
      ObjectDelete(label);
      ObjectCreate(label, OBJ_TREND, indicatorWindow, t1, p1, t2, p2, 0, 0);
         ObjectSet(label, OBJPROP_RAY, 0);
         ObjectSet(label, OBJPROP_COLOR, lineColor);
         ObjectSet(label, OBJPROP_STYLE, style);
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
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i, int instanceNo=0)
{
  if (tprice>=pr_haclose && tprice<=pr_hatbiased)
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
