//+------------------------------------------------------------------+
//|                                          colored macd            |
//+------------------------------------------------------------------+
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"


#property indicator_separate_window
#property indicator_buffers    6
#property indicator_color1     MediumVioletRed
#property indicator_color2     MediumVioletRed
#property indicator_color3     DeepSkyBlue
#property indicator_color4     DeepSkyBlue
#property indicator_color5     DimGray
#property indicator_color6     Gold
#property indicator_width1     2
#property indicator_width3     2
#property indicator_width6     2
#property indicator_levelcolor DarkSlateGray

//
//
//
//
//

extern string TimeFrame                 = "Current time frame";
extern int    Price                     = 8;
extern int    FastPeriod                = 12;
extern int    SlowPeriod                = 26;
extern int    SignalPeriod              = 9;
extern int    Method                    = 2;
extern bool   divergenceVisible         = true;
extern bool   divergenceOnValuesVisible = true;
extern bool   divergenceOnChartVisible  = true;
extern color  divergenceBullishColor    = LimeGreen;
extern color  divergenceBearishColor    = OrangeRed;
extern string divergenceUniqueID        = "Macd diverge1";
extern bool   HistogramOnSlope          = true;
extern bool   Interpolate               = true;

extern double levelOb3                  = 0.0050;
extern double levelOb2                  = 0.0025;
extern double levelOb1                  = 0.0010;
extern double levelOs1                  = -0.0010;
extern double levelOs2                  = -0.0025;
extern double levelOs3                  = -0.0050;

extern bool   alertsOn                  = true;
extern bool   alertsOnZeroCross         = false;
extern bool   alertsOnMacdSignalCross   = true;
extern bool   alertsOnObLevel3Cross     = false;
extern bool   alertsOnObLevel2Cross     = false;
extern bool   alertsOnObLevel1Cross     = false;
extern bool   alertsOnOsLevel1Cross     = false;
extern bool   alertsOnOsLevel2Cross     = false;
extern bool   alertsOnOsLevel3Cross     = false;
extern bool   alertsOnCurrent           = false;
extern bool   alertsMessage             = true;
extern bool   alertsSound               = true;
extern bool   alertsEmail               = false;

extern bool   arrowsVisible             = false;
extern string arrowsIdentifier          = "macd Arrows1";
extern double arrowsDisplacement        = 1.0;
extern color  arrowsUpColor             = LimeGreen;
extern color  arrowsDnColor             = Red;
extern bool   arrowsOnZeroCross         = false;
extern bool   arrowsOnMacdSignalCross   = true;
extern bool   arrowsOnObLevel3Cross     = false;
extern bool   arrowsOnObLevel2Cross     = false;
extern bool   arrowsOnObLevel1Cross     = false;
extern bool   arrowsOnOsLevel1Cross     = false;
extern bool   arrowsOnOsLevel2Cross     = false;
extern bool   arrowsOnOsLevel3Cross     = false;

extern string  MAModePossibilities      = "";
extern string  __0                      = "SMA";
extern string  __1                      = "EMA";
extern string  __2                      = "Double smoothed EMA";
extern string  __3                      = "Double EMA (DEMA)";
extern string  __4                      = "Triple EMA (TEMA)";
extern string  __5                      = "Leader EMA";
extern string  __6                      = "Smoothed MA";
extern string  __7                      = "Linear weighted MA";
extern string  __8                      = "Parabolic weighted MA";
extern string  __9                      = "Alexander MA";
extern string  __10                     = "Volume weghted MA";
extern string  __11                     = "Hull MA";
extern string  __12                     = "Triangular MA";
extern string  __13                     = "Sine weighted MA";
extern string  __14                     = "Linear regression";
extern string  __15                     = "IE/2";
extern string  __16                     = "NonLag MA";
extern string  __17                     = "Zero lag EMA";

//
//
//
//
//

double Upa[];
double Upb[];
double Dna[];
double Dnb[];
double macd[];
double signal[];
double trend[];
double slope[];

double trends[][8];
#define _tmi1 0
#define _tsig 1
#define _tob3 2
#define _tob2 3
#define _tob1 4
#define _tos1 5
#define _tos2 6
#define _tos3 7

//
//
//
//
//

string indicatorFileName;
bool   returnBars;
bool   calculateValue;
int    timeFrame;
string shortName;

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
   IndicatorDigits(6);
   IndicatorBuffers(8);
   SetIndexBuffer(0,Dna);   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(1,Dnb);   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(2,Upa);   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(3,Upb);   SetIndexStyle(3,DRAW_HISTOGRAM);
   SetIndexBuffer(4,macd);
   SetIndexBuffer(5,signal);
   SetIndexBuffer(6,trend);
   SetIndexBuffer(7,slope);
   
   SetLevelValue(0,levelOb3);
   SetLevelValue(1,levelOb2);
   SetLevelValue(2,levelOb1);
   SetLevelValue(3,0);
   SetLevelValue(4,levelOs1);
   SetLevelValue(5,levelOs2);
   SetLevelValue(6,levelOs3);
   
   
      FastPeriod   = MathMax(FastPeriod,1);
      SlowPeriod   = MathMax(SlowPeriod,1);
      SignalPeriod = MathMax(SignalPeriod,1);
   
      //
      //
      //
      //
      //
   
      indicatorFileName = WindowExpertName();
      returnBars        = (TimeFrame=="returnBars");     if (returnBars)     return(0);
      calculateValue    = (TimeFrame=="calculateValue");
      if (calculateValue)
      {
         int s = StringFind(divergenceUniqueID,":",0);
               shortName = divergenceUniqueID;
               divergenceUniqueID = StringSubstr(divergenceUniqueID,0,s);
               return(0);
      }            
      timeFrame = stringToTimeFrame(TimeFrame);
      
      //
      //
      //
      //
      //
      
    shortName = divergenceUniqueID+":  "+timeFrameToString(timeFrame)+" MACD "+getAverageName(Method)+" ("+FastPeriod+","+SlowPeriod+","+SignalPeriod+")";
   IndicatorShortName(shortName);
   return(0);
}
               
//
//
//
//
//

int deinit() 
{ 

   int lookForLength = StringLen(divergenceUniqueID);
   
   for (int i=ObjectsTotal()-1; i>=0; i--) 
   {
   
   string objectName = ObjectName(i);
   if (StringSubstr(objectName,0,lookForLength) == divergenceUniqueID) ObjectDelete(objectName);
   
   }
   
   if (!calculateValue && arrowsVisible) deleteArrows();
   

return(0);
}

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
   int i,r,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { Dna[0] = limit+1; return(0); }

   //
   //
   //
   //
   //

   if (calculateValue || timeFrame == Period())
   {
      if (ArrayRange(trends,0)!=Bars) {  ArrayResize(trends,Bars); }
   
      for(i = limit, r=Bars-i-1; i>=0; i--,r++)
      {
    
         macd[i]   = iCustomMa(Method,getPrice(Price,i),FastPeriod,i,0) - iCustomMa(Method,getPrice(Price,i),SlowPeriod,i,1);
         signal[i] = iCustomMa(Method,macd[i],SignalPeriod,i,2);
         Dna[i]    = EMPTY_VALUE;
         Dnb[i]    = EMPTY_VALUE;
         Upa[i]    = EMPTY_VALUE;
         Upb[i]    = EMPTY_VALUE;
         trend[i]  = trend[i+1];
         slope[i]  = slope[i+1];
         if (macd[i] > 0)         trend[i] =  1;
         if (macd[i] < 0)         trend[i] = -1;
         if (macd[i] > macd[i+1]) slope[i] =  1;
         if (macd[i] < macd[i+1]) slope[i] = -1;
         
         setTrends(i,r);
         manageArrow(i,r);
         
         if (divergenceVisible)
          {
             CatchBullishDivergence(macd,i);
             CatchBearishDivergence(macd,i);
          }
                                     
          if (HistogramOnSlope)
          {
             if (trend[i]== 1 && slope[i] == 1) Upa[i] = macd[i];
             if (trend[i]== 1 && slope[i] ==-1) Upb[i] = macd[i];
             if (trend[i]==-1 && slope[i] ==-1) Dna[i] = macd[i];
             if (trend[i]==-1 && slope[i] == 1) Dnb[i] = macd[i];
          }
          else
          {                  
             if (trend[i]== 1) Upa[i] = macd[i];
             if (trend[i]==-1) Dna[i] = macd[i];
          }
          
          
          
               
      }
      manageAlerts();
      return(0);
      }  
      
      //
      //
      //
      //
      //
      
      limit = MathMax(limit,MathMin(Bars,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
      if (ArrayRange(trends,0)!=Bars) ArrayResize(trends,Bars);
             
      for(i=limit, r=Bars-i-1; i>=0; i--, r++)
      {
       int y = iBarShift(NULL,timeFrame,Time[i]);
         macd[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Price,FastPeriod,SlowPeriod,SignalPeriod,Method,divergenceVisible,divergenceOnValuesVisible,divergenceOnChartVisible,divergenceBullishColor,divergenceBearishColor,shortName,Interpolate,4,y);
         signal[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Price,FastPeriod,SlowPeriod,SignalPeriod,Method,divergenceVisible,divergenceOnValuesVisible,divergenceOnChartVisible,divergenceBullishColor,divergenceBearishColor,shortName,Interpolate,5,y);
         trend[i]  = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Price,FastPeriod,SlowPeriod,SignalPeriod,Method,divergenceVisible,divergenceOnValuesVisible,divergenceOnChartVisible,divergenceBullishColor,divergenceBearishColor,shortName,Interpolate,6,y);
         slope[i]  = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Price,FastPeriod,SlowPeriod,SignalPeriod,Method,divergenceVisible,divergenceOnValuesVisible,divergenceOnChartVisible,divergenceBullishColor,divergenceBearishColor,shortName,Interpolate,7,y);
         Dna[i]    = EMPTY_VALUE;
         Dnb[i]    = EMPTY_VALUE;
         Upa[i]    = EMPTY_VALUE;
         Upb[i]    = EMPTY_VALUE;
         
         setTrends(i,r);
         manageArrow(i,r);

         //
         //
         //
         //
         //
      
         if (!Interpolate || y==iBarShift(NULL,timeFrame,Time[i-1])) continue;

         //
         //
         //
         //
         //

         datetime time = iTime(NULL,timeFrame,y);
            for(int n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;
            for(int k = 1; k < n; k++)
               {
               macd[i+k]   = macd[i]   + (macd[i+n]   - macd[i])   * k/n;
               signal[i+k] = signal[i] + (signal[i+n] - signal[i]) * k/n;
               }
   }
   for (i=limit;i>=0;i--)
   {
      if (HistogramOnSlope)
          {
             if (trend[i]== 1 && slope[i] == 1) Upa[i] = macd[i];
             if (trend[i]== 1 && slope[i] ==-1) Upb[i] = macd[i];
             if (trend[i]==-1 && slope[i] ==-1) Dna[i] = macd[i];
             if (trend[i]==-1 && slope[i] == 1) Dnb[i] = macd[i];
          }
          else
          {                  
             if (trend[i]== 1) Upa[i] = macd[i];
             if (trend[i]==-1) Dna[i] = macd[i];
          }
                               
   }
   
   manageAlerts();
   return(0);
}

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//
//

double getPrice(int type, int i)
{
   switch (type)
   {
      case 7:     return((Open[i]+Close[i])/2.0);
      case 8:     return((Open[i]+High[i]+Low[i]+Close[i])/4.0);
      default :   return(iMA(NULL,0,1,0,MODE_SMA,type,i));
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

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

string methodNames[] = {"SMA","EMA","Double smoothed EMA","Double EMA","Triple EMA","Leader EMA","Smoothed MA","Linear weighted MA","Parabolic weighted MA","Alexander MA","Volume weghted MA","Hull MA","Triangular MA","Sine weighted MA","Linear regression","IE/2","NonLag MA","Zero lag EMA"};
string getAverageName(int& method)
{
   int max = ArraySize(methodNames)-1;
      method=MathMax(MathMin(method,max),0); return(methodNames[method]);
}

//
//
//
//
//

#define _maWorkBufferx1 3
#define _maWorkBufferx2 6
#define _maWorkBufferx3 9

double iCustomMa(int mode, double price, double length, int i, int instanceNo=0)
{
   int r = Bars-i-1;
   switch (mode)
   {
      case 0  : return(iSma(price,length,r,instanceNo));
      case 1  : return(iEma(price,length,r,instanceNo));
      case 2  : return(iDsema(price,length,r,instanceNo));
      case 3  : return(iDema(price,length,r,instanceNo));
      case 4  : return(iTema(price,length,r,instanceNo));
      case 5  : return(iLeader(price,length,r,instanceNo));
      case 6  : return(iSmma(price,length,r,instanceNo));
      case 7  : return(iLwma(price,length,r,instanceNo));
      case 8  : return(iLwmp(price,length,r,instanceNo));
      case 9  : return(iAlex(price,length,r,instanceNo));
      case 10  : return(iWwma(price,length,r,instanceNo));
      case 11 : return(iHull(price,length,r,instanceNo));
      case 12 : return(iTma(price,length,r,instanceNo));
      case 13 : return(iSineWMA(price,length,r,instanceNo));
      case 14 : return(iLinr(price,length,r,instanceNo));
      case 15 : return(iIe2(price,length,r,instanceNo));
      case 16 : return(iNonLagMa(price,length,r,instanceNo));
      case 17 : return(iZeroLag(price,length,r,instanceNo));
      default : return(0);
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

double workSma[][_maWorkBufferx2];
double iSma(double price, int period, int r, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= Bars) ArrayResize(workSma,Bars); instanceNo *= 2;

   //
   //
   //
   //
   //
      
   workSma[r][instanceNo] = price;
   if (r>=period)
          workSma[r][instanceNo+1] = workSma[r-1][instanceNo+1]+(workSma[r][instanceNo]-workSma[r-period][instanceNo])/period;
   else { workSma[r][instanceNo+1] = 0; for(int k=0; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo];  
          workSma[r][instanceNo+1] /= k; }
   return(workSma[r][instanceNo+1]);
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= Bars) ArrayResize(workEma,Bars);

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workDsema[][_maWorkBufferx2];
#define _ema1 0
#define _ema2 1

double iDsema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workDsema,0)!= Bars) ArrayResize(workDsema,Bars); instanceNo*=2;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 /(1.0+MathSqrt(period));
          workDsema[r][_ema1+instanceNo] = workDsema[r-1][_ema1+instanceNo]+alpha*(price                         -workDsema[r-1][_ema1+instanceNo]);
          workDsema[r][_ema2+instanceNo] = workDsema[r-1][_ema2+instanceNo]+alpha*(workDsema[r][_ema1+instanceNo]-workDsema[r-1][_ema2+instanceNo]);
   return(workDsema[r][_ema2+instanceNo]);
}

//
//
//
//
//

double workDema[][_maWorkBufferx2];
#define _ema1 0
#define _ema2 1

double iDema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workDema,0)!= Bars) ArrayResize(workDema,Bars); instanceNo*=2;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workDema[r][_ema1+instanceNo] = workDema[r-1][_ema1+instanceNo]+alpha*(price                        -workDema[r-1][_ema1+instanceNo]);
          workDema[r][_ema2+instanceNo] = workDema[r-1][_ema2+instanceNo]+alpha*(workDema[r][_ema1+instanceNo]-workDema[r-1][_ema2+instanceNo]);
   return(workDema[r][_ema1+instanceNo]*2.0-workDema[r][_ema2+instanceNo]);
}

//
//
//
//
//

double workLema[][_maWorkBufferx2];
double iLeader(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLema,0)!= Bars) ArrayResize(workLema,Bars); instanceNo*=2;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workLema[r][instanceNo+_ema1] = workLema[r-1][instanceNo+_ema1]+alpha*(price                              -workLema[r-1][instanceNo+_ema1]);
          workLema[r][instanceNo+_ema2] = workLema[r-1][instanceNo+_ema2]+alpha*(price-workLema[r][instanceNo+_ema1]-workLema[r-1][instanceNo+_ema2]);
   return(workLema[r][instanceNo+_ema1] + workLema[r][instanceNo+_ema2]);
}

//
//
//
//
//

double workTema[][_maWorkBufferx3];
#define _ema1 0
#define _ema2 1
#define _ema3 2

double iTema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workTema,0)!= Bars) ArrayResize(workTema,Bars); instanceNo*=3;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workTema[r][_ema1+instanceNo] = workTema[r-1][_ema1+instanceNo]+alpha*(price                        -workTema[r-1][_ema1+instanceNo]);
          workTema[r][_ema2+instanceNo] = workTema[r-1][_ema2+instanceNo]+alpha*(workTema[r][_ema1+instanceNo]-workTema[r-1][_ema2+instanceNo]);
          workTema[r][_ema3+instanceNo] = workTema[r-1][_ema3+instanceNo]+alpha*(workTema[r][_ema2+instanceNo]-workTema[r-1][_ema3+instanceNo]);
   return(workTema[r][_ema3+instanceNo]+3.0*(workTema[r][_ema1+instanceNo]-workTema[r][_ema2+instanceNo]));
}

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= Bars) ArrayResize(workSmma,Bars);

   //
   //
   //
   //
   //

   if (r<period)
         workSmma[r][instanceNo] = price;
   else  workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= Bars) ArrayResize(workLwma,Bars);
   
   //
   //
   //
   //
   //
   
   workLwma[r][instanceNo] = price;
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

double workLwmp[][_maWorkBufferx1];
double iLwmp(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLwmp,0)!= Bars) ArrayResize(workLwmp,Bars);
   
   //
   //
   //
   //
   //
   
   workLwmp[r][instanceNo] = price;
      double sumw = period*period;
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = (period-k)*(period-k);
                sumw  += weight;
                sum   += weight*workLwmp[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workAlex[][_maWorkBufferx1];
double iAlex(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workAlex,0)!= Bars) ArrayResize(workAlex,Bars);
   if (period<4) return(price);
   
   //
   //
   //
   //
   //

   workAlex[r][instanceNo] = price;
      double sumw = period-2;
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k-2;
                sumw  += weight;
                sum   += weight*workAlex[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workTma[][_maWorkBufferx1];
double iTma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workTma,0)!= Bars) ArrayResize(workTma,Bars);
   
   //
   //
   //
   //
   //
   
   workTma[r][instanceNo] = price;

      double half = (period+1.0)/2.0;
      double sum  = price;
      double sumw = 1;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = k+1; if (weight > half) weight = period-k;
                sumw  += weight;
                sum   += weight*workTma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workSineWMA[][_maWorkBufferx1];
#define Pi 3.14159265358979323846264338327950288

double iSineWMA(double price, int period, int r, int instanceNo=0)
{
   if (period<1) return(price);
   if (ArrayRange(workSineWMA,0)!= Bars) ArrayResize(workSineWMA,Bars);
   
   //
   //
   //
   //
   //
   
   workSineWMA[r][instanceNo] = price;
      double sum  = 0;
      double sumw = 0;
  
      for(int k=0; k<period && (r-k)>=0; k++)
      { 
         double weight = MathSin(Pi*(k+1.0)/(period+1.0));
                sumw  += weight;
                sum   += weight*workSineWMA[r-k][instanceNo]; 
      }
      return(sum/sumw);
}

//
//
//
//
//

double workWwma[][_maWorkBufferx1];
double iWwma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workWwma,0)!= Bars) ArrayResize(workWwma,Bars);
   
   //
   //
   //
   //
   //
   
   workWwma[r][instanceNo] = price;
      int    i    = Bars-r-1;
      double sumw = Volume[i];
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = Volume[i+k];
                sumw  += weight;
                sum   += weight*workWwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}


//
//
//
//
//

double workHull[][_maWorkBufferx2];
double iHull(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workHull,0)!= Bars) ArrayResize(workHull,Bars);

   //
   //
   //
   //
   //

      int HmaPeriod  = MathMax(period,2);
      int HalfPeriod = MathFloor(HmaPeriod/2);
      int HullPeriod = MathFloor(MathSqrt(HmaPeriod));
      double hma,hmw,weight; instanceNo *= 2;

         workHull[r][instanceNo] = price;

         //
         //
         //
         //
         //
               
         hmw = HalfPeriod; hma = hmw*price; 
            for(int k=1; k<HalfPeriod && (r-k)>=0; k++)
            {
               weight = HalfPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][instanceNo];  
            }             
            workHull[r][instanceNo+1] = 2.0*hma/hmw;

         hmw = HmaPeriod; hma = hmw*price; 
            for(k=1; k<period && (r-k)>=0; k++)
            {
               weight = HmaPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][instanceNo];
            }             
            workHull[r][instanceNo+1] -= hma/hmw;

         //
         //
         //
         //
         //
         
         hmw = HullPeriod; hma = hmw*workHull[r][instanceNo+1];
            for(k=1; k<HullPeriod && (r-k)>=0; k++)
            {
               weight = HullPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][1+instanceNo];  
            }
   return(hma/hmw);
}

//
//
//
//
//

double workLinr[][_maWorkBufferx1];
double iLinr(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLinr,0)!= Bars) ArrayResize(workLinr,Bars);

   //
   //
   //
   //
   //
   
      period = MathMax(period,1);
      workLinr[r][instanceNo] = price;
         double lwmw = period; double lwma = lwmw*price;
         double sma  = price;
         for(int k=1; k<period && (r-k)>=0; k++)
         {
            double weight = period-k;
                   lwmw  += weight;
                   lwma  += weight*workLinr[r-k][instanceNo];  
                   sma   +=        workLinr[r-k][instanceNo];
         }             
   
   return(3.0*lwma/lwmw-2.0*sma/period);
}

//
//
//
//
//

double workIe2[][_maWorkBufferx1];
double iIe2(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workIe2,0)!= Bars) ArrayResize(workIe2,Bars);

   //
   //
   //
   //
   //
   
      period = MathMax(period,1);
      workIe2[r][instanceNo] = price;
         double sumx=0, sumxx=0, sumxy=0, sumy=0;
         for (int k=0; k<period; k++)
         {
            price = workIe2[r-k][instanceNo];
                   sumx  += k;
                   sumxx += k*k;
                   sumxy += k*price;
                   sumy  +=   price;
         }
         double slope   = (period*sumxy - sumx*sumy)/(sumx*sumx-period*sumxx);
         double average = sumy/period;
   return(((average+slope)+(sumy+slope*sumx)/period)/2.0);
}

//
//
//
//
//

double workZl[][_maWorkBufferx2];
#define _price 0
#define _zlema 1

double iZeroLag(double price, double length, int r, int instanceNo=0)
{
   if (ArrayRange(workZl,0)!=Bars) ArrayResize(workZl,Bars); instanceNo *= 2;

   //
   //
   //
   //
   //

   double alpha = 2.0/(1.0+length); 
   int    per   = (length-1.0)/2.0; 

   workZl[r][_price+instanceNo] = price;
   if (r<per)
          workZl[r][_zlema+instanceNo] = price;
   else   workZl[r][_zlema+instanceNo] = workZl[r-1][_zlema+instanceNo]+alpha*(2.0*price-workZl[r-per][_price+instanceNo]-workZl[r-1][_zlema+instanceNo]);
   return(workZl[r][_zlema+instanceNo]);
}

//
//
//
//
//

#define Pi       3.14159265358979323846264338327950288
#define _length  0
#define _len     1
#define _weight  2

double  nlm.values[3][_maWorkBufferx1];
double  nlm.prices[ ][_maWorkBufferx1];
double  nlm.alphas[ ][_maWorkBufferx1];

//
//
//
//
//

double iNonLagMa(double price, double length, int r, int instanceNo=0)
{
   if (ArrayRange(nlm.prices,0) != Bars) ArrayResize(nlm.prices,Bars);
                               nlm.prices[r][instanceNo]=price;
   if (length<3 || r<3) return(nlm.prices[r][instanceNo]);
   
   //
   //
   //
   //
   //
   
   if (nlm.values[_length][instanceNo] != length)
   {
      double Cycle = 4.0;
      double Coeff = 3.0*Pi;
      int    Phase = length-1;
      
         nlm.values[_length][instanceNo] = length;
         nlm.values[_len   ][instanceNo] = length*4 + Phase;  
         nlm.values[_weight][instanceNo] = 0;

         if (ArrayRange(nlm.alphas,0) < nlm.values[_len][instanceNo]) ArrayResize(nlm.alphas,nlm.values[_len][instanceNo]);
         for (int k=0; k<nlm.values[_len][instanceNo]; k++)
         {
            if (k<=Phase-1) 
                 double t = 1.0 * k/(Phase-1);
            else        t = 1.0 + (k-Phase+1)*(2.0*Cycle-1.0)/(Cycle*length-1.0); 
            double beta = MathCos(Pi*t);
            double g = 1.0/(Coeff*t+1); if (t <= 0.5 ) g = 1;
      
            nlm.alphas[k][instanceNo]        = g * beta;
            nlm.values[_weight][instanceNo] += nlm.alphas[k][instanceNo];
         }
   }
   
   //
   //
   //
   //
   //
   
   if (nlm.values[_weight][instanceNo]>0)
   {
      double sum = 0;
           for (k=0; k < nlm.values[_len][instanceNo]; k++) sum += nlm.alphas[k][instanceNo]*nlm.prices[r-k][instanceNo];
           return( sum / nlm.values[_weight][instanceNo]);
   }
   else return(0);           
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

void setTrends(int i, int r)
{
   trends[r][_tmi1] = trends[r-1][_tmi1];
   trends[r][_tsig] = trends[r-1][_tsig];
   trends[r][_tob3] = trends[r-1][_tob3];
   trends[r][_tob2] = trends[r-1][_tob2];
   trends[r][_tob1] = trends[r-1][_tob1];
   trends[r][_tos1] = trends[r-1][_tos1];
   trends[r][_tos2] = trends[r-1][_tos2];
   trends[r][_tos3] = trends[r-1][_tos3];
   
      if (macd[i] > 0)         trends[r][_tmi1] =  1;
      if (macd[i] < 0)         trends[r][_tmi1] = -1;
      if (macd[i] > signal[i]) trends[r][_tsig] =  1;
      if (macd[i] < signal[i]) trends[r][_tsig] = -1;
      if (macd[i] > levelOb3)  trends[r][_tob3] =  1;
      if (macd[i] < levelOb3)  trends[r][_tob3] = -1;
      if (macd[i] > levelOb2)  trends[r][_tob2] =  1;
      if (macd[i] < levelOb2)  trends[r][_tob2] = -1;
      if (macd[i] > levelOb1)  trends[r][_tob1] =  1;
      if (macd[i] < levelOb1)  trends[r][_tob1] = -1;
      if (macd[i] > levelOs1)  trends[r][_tos1] =  1;
      if (macd[i] < levelOs1)  trends[r][_tos1] = -1;
      if (macd[i] > levelOs2)  trends[r][_tos2] =  1;
      if (macd[i] < levelOs2)  trends[r][_tos2] = -1;
      if (macd[i] > levelOs3)  trends[r][_tos3] =  1;
      if (macd[i] < levelOs3)  trends[r][_tos3] = -1;
 
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (!calculateValue && alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; whichBar = iBarShift(NULL,0,iTime(NULL,timeFrame,whichBar)); 
                             whichBar = Bars-whichBar-1;

      //
      //
      //
      //
      //
      
      static datetime time1 = 0;
      static string   mess1 = "";
      if (alertsOnZeroCross && trends[whichBar][_tmi1] != trends[whichBar-1][_tmi1])
      {
         if (trends[whichBar][_tmi1] ==  1) doAlert(time1,mess1,whichBar,"crossed mid band up");
         if (trends[whichBar][_tmi1] == -1) doAlert(time1,mess1,whichBar,"crossed mid band down");
      }
            
      static datetime time2 = 0;
      static string   mess2 = "";
      if (alertsOnMacdSignalCross && trends[whichBar][_tsig] != trends[whichBar-1][_tsig])
      {
         if (trends[whichBar][_tsig] ==  1) doAlert(time2,mess2,whichBar,"crossed signal up");
         if (trends[whichBar][_tsig] == -1) doAlert(time2,mess2,whichBar,"crossed signal down");
      }
      
      static datetime time3 = 0;
      static string   mess3 = "";
      if (alertsOnObLevel3Cross && trends[whichBar][_tob3] != trends[whichBar-1][_tob3])
      {
         if (trends[whichBar][_tob3] ==  1) doAlert(time3,mess3,whichBar,"crossed oblevel3  up");
         if (trends[whichBar][_tob3] == -1) doAlert(time3,mess3,whichBar,"crossed oblevel3 down");
      }
      
      static datetime time4 = 0;
      static string   mess4 = "";
      if (alertsOnObLevel2Cross && trends[whichBar][_tob2] != trends[whichBar-1][_tob2])
      {
         if (trends[whichBar][_tob2] ==  1) doAlert(time4,mess4,whichBar,"crossed oblevel2  up");
         if (trends[whichBar][_tob2] == -1) doAlert(time4,mess4,whichBar,"crossed oblevel2 down");
      }
      
      static datetime time5 = 0;
      static string   mess5 = "";
      if (alertsOnObLevel1Cross && trends[whichBar][_tob1] != trends[whichBar-1][_tob1])
      {
         if (trends[whichBar][_tob1] ==  1) doAlert(time5,mess5,whichBar,"crossed oblevel1  up");
         if (trends[whichBar][_tob1] == -1) doAlert(time5,mess5,whichBar,"crossed oblevel1 down");
      }
      
      static datetime time6 = 0;
      static string   mess6 = "";
      if (alertsOnOsLevel1Cross && trends[whichBar][_tos1] != trends[whichBar-1][_tos1])
      {
         if (trends[whichBar][_tos1] ==  1) doAlert(time6,mess6,whichBar,"crossed oslevel1  up");
         if (trends[whichBar][_tos1] == -1) doAlert(time6,mess6,whichBar,"crossed oslevel1 down");
      }
      
      static datetime time7 = 0;
      static string   mess7 = "";
      if (alertsOnOsLevel2Cross && trends[whichBar][_tos2] != trends[whichBar-1][_tos2])
      {
         if (trends[whichBar][_tos2] ==  1) doAlert(time7,mess7,whichBar,"crossed oslevel2  up");
         if (trends[whichBar][_tos2] == -1) doAlert(time7,mess7,whichBar,"crossed oslevel2 down");
      }
      
      static datetime time8 = 0;
      static string   mess8 = "";
      if (alertsOnOsLevel3Cross && trends[whichBar][_tos3] != trends[whichBar-1][_tos3])
      {
         if (trends[whichBar][_tos3] ==  1) doAlert(time8,mess8,whichBar,"crossed oslevel3  up");
         if (trends[whichBar][_tos3] == -1) doAlert(time8,mess8,whichBar,"crossed oslevel3 down");
      }
      
      
   }
}

//
//
//
//
//

void doAlert(datetime& previousTime, string& previousAlert, int forBar, string doWhat)
{
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message =  StringConcatenate(Symbol()," ",timeFrameToString(timeFrame)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," macd ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," macd "),message);
          if (alertsSound)   PlaySound("alert2.wav");
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

void manageArrow(int i, int r)
{
   if (!calculateValue && arrowsVisible)
   {
      deleteArrow(Time[i]);
      if (arrowsOnZeroCross && trends[r][_tmi1]!=trends[r-1][_tmi1])
      {
         if (trends[r][_tmi1] == 1) drawArrow(i,arrowsUpColor,241,false);
         if (trends[r][_tmi1] ==-1) drawArrow(i,arrowsDnColor,242,true);
      }
      
      if (arrowsOnMacdSignalCross && trends[r][_tsig]!=trends[r-1][_tsig])
      {
         if (trends[r][_tsig] == 1) drawArrow(i,arrowsUpColor,241,false);
         if (trends[r][_tsig] ==-1) drawArrow(i,arrowsDnColor,242,true);
      }
      
      if (arrowsOnObLevel3Cross && trends[r][_tob3]!=trends[r-1][_tob3])
      {
         if (trends[r][_tob3] == 1) drawArrow(i,arrowsUpColor,241,false);
         if (trends[r][_tob3] ==-1) drawArrow(i,arrowsDnColor,242,true);
      }
      
      if (arrowsOnObLevel2Cross && trends[r][_tob2]!=trends[r-1][_tob2])
      {
         if (trends[r][_tob2] == 1) drawArrow(i,arrowsUpColor,241,false);
         if (trends[r][_tob2] ==-1) drawArrow(i,arrowsDnColor,242,true);
      }
      
      if (arrowsOnObLevel1Cross && trends[r][_tob1]!=trends[r-1][_tob1])
      {
         if (trends[r][_tob1] == 1) drawArrow(i,arrowsUpColor,241,false);
         if (trends[r][_tob1] ==-1) drawArrow(i,arrowsDnColor,242,true);
      }
      
      if (arrowsOnOsLevel1Cross && trends[r][_tos1]!=trends[r-1][_tos1])
      {
         if (trends[r][_tos1] == 1) drawArrow(i,arrowsUpColor,241,false);
         if (trends[r][_tos1] ==-1) drawArrow(i,arrowsDnColor,242,true);
      }
      
      if (arrowsOnOsLevel2Cross && trends[r][_tos2]!=trends[r-1][_tos2])
      {
         if (trends[r][_tos2] == 1) drawArrow(i,arrowsUpColor,241,false);
         if (trends[r][_tos2] ==-1) drawArrow(i,arrowsDnColor,242,true);
      }
      
      if (arrowsOnOsLevel3Cross && trends[r][_tos3]!=trends[r-1][_tos3])
      {
         if (trends[r][_tos3] == 1) drawArrow(i,arrowsUpColor,241,false);
         if (trends[r][_tos3] ==-1) drawArrow(i,arrowsDnColor,242,true);
      }
   }
}               

//
//
//
//
//

void drawArrow(int i,color theColor,int theCode,bool up)
{
   string name = arrowsIdentifier+":"+Time[i];
   double gap  = iATR(NULL,0,20,i);   
   
      //
      //
      //
      //
      //
      
      ObjectCreate(name,OBJ_ARROW,0,Time[i],0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsDisplacement * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsDisplacement * gap);
}

//
//
//
//
//

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

//
//
//
//
//

void deleteArrow(datetime time)
{
   string lookFor = arrowsIdentifier+":"+time; ObjectDelete(lookFor);
}

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

void CatchBullishDivergence(double& values[], int i)
{
   i++;
            ObjectDelete(divergenceUniqueID+"l"+DoubleToStr(Time[i],0));
            ObjectDelete(divergenceUniqueID+"l"+"os" + DoubleToStr(Time[i],0));            
   if (!IsIndicatorLow(values,i)) return;  

   //
   //
   //
   //
   //

   int currentLow = i;
   int lastLow    = GetIndicatorLastLow(values,i+1);
      if (values[currentLow] > values[lastLow] && Low[currentLow] < Low[lastLow])
      {
         if(divergenceOnChartVisible)  DrawPriceTrendLine("l",Time[currentLow],Time[lastLow],Low[currentLow],Low[lastLow],divergenceBullishColor,STYLE_SOLID);
         if(divergenceOnValuesVisible) DrawIndicatorTrendLine("l",Time[currentLow],Time[lastLow],values[currentLow],values[lastLow],divergenceBullishColor,STYLE_SOLID);
      }
      if (values[currentLow] < values[lastLow] && Low[currentLow] > Low[lastLow])
      {
         if(divergenceOnChartVisible)  DrawPriceTrendLine("l",Time[currentLow],Time[lastLow],Low[currentLow],Low[lastLow], divergenceBullishColor, STYLE_DOT);
         if(divergenceOnValuesVisible) DrawIndicatorTrendLine("l",Time[currentLow],Time[lastLow],values[currentLow],values[lastLow], divergenceBullishColor, STYLE_DOT);
      }
}

//
//
//
//
//

void CatchBearishDivergence(double& values[], int i)
{
   i++; 
            ObjectDelete(divergenceUniqueID+"h"+DoubleToStr(Time[i],0));
            ObjectDelete(divergenceUniqueID+"h"+"os" + DoubleToStr(Time[i],0));            
   if (IsIndicatorPeak(values,i) == false) return;

   //
   //
   //
   //
   //
      
   int currentPeak = i;
   int lastPeak = GetIndicatorLastPeak(values,i+1);
      if (values[currentPeak] < values[lastPeak] && High[currentPeak]>High[lastPeak])
      {
         if (divergenceOnChartVisible)  DrawPriceTrendLine("h",Time[currentPeak],Time[lastPeak],High[currentPeak],High[lastPeak],divergenceBearishColor,STYLE_SOLID);
         if (divergenceOnValuesVisible) DrawIndicatorTrendLine("h",Time[currentPeak],Time[lastPeak],values[currentPeak],values[lastPeak],divergenceBearishColor,STYLE_SOLID);
      }
      if(values[currentPeak] > values[lastPeak] && High[currentPeak] < High[lastPeak])
      {
         if (divergenceOnChartVisible)  DrawPriceTrendLine("h",Time[currentPeak],Time[lastPeak],High[currentPeak],High[lastPeak], divergenceBearishColor, STYLE_DOT);
         if (divergenceOnValuesVisible) DrawIndicatorTrendLine("h",Time[currentPeak],Time[lastPeak],values[currentPeak],values[lastPeak], divergenceBearishColor, STYLE_DOT);
      }
}

//
//
//
//
//

bool IsIndicatorPeak(double& values[], int i) { return(values[i] >= values[i+1] && values[i] > values[i+2] && values[i] > values[i-1]); }
bool IsIndicatorLow( double& values[], int i) { return(values[i] <= values[i+1] && values[i] < values[i+2] && values[i] < values[i-1]); }

int GetIndicatorLastPeak(double& values[], int shift)
{
   for(int i = shift+5; i<Bars; i++)
         if (values[i] >= values[i+1] && values[i] > values[i+2] && values[i] >= values[i-1] && values[i] > values[i-2]) return(i);
   return(-1);
}

//
//
//
//
//

int GetIndicatorLastLow(double& values[], int shift)
{
   for(int i = shift+5; i<Bars; i++)
         if (values[i] <= values[i+1] && values[i] < values[i+2] && values[i] <= values[i-1] && values[i] < values[i-2]) return(i);
   return(-1);
}

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

void DrawPriceTrendLine(string first,datetime t1, datetime t2, double p1, double p2, color lineColor, double style)
{
   string   label = divergenceUniqueID+first+"os"+DoubleToStr(t1,0);
   if (Interpolate) t2 += Period()*60-1;
    
   ObjectDelete(label);
      ObjectCreate(label, OBJ_TREND, 0, t1+Period()*60-1, p1, t2, p2, 0, 0);
         ObjectSet(label, OBJPROP_RAY, false);
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
   int indicatorWindow = WindowFind(shortName);
   if (indicatorWindow < 0) return;
   if (Interpolate) t2 += Period()*60-1;
   
   string label = divergenceUniqueID+first+DoubleToStr(t1,0);
   ObjectDelete(label);
      ObjectCreate(label, OBJ_TREND, indicatorWindow, t1+Period()*60-1, p1, t2, p2, 0, 0);
         ObjectSet(label, OBJPROP_RAY, false);
         ObjectSet(label, OBJPROP_COLOR, lineColor);
         ObjectSet(label, OBJPROP_STYLE, style);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs) {
   tfs = stringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}

//
//
//
//
//

string timeFrameToString(int tf) {
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//
//
//
//
//

string stringUpperCase(string str) {
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--) {
      int char = StringGetChar(s, length);
         if((char > 96 && char < 123) || (char > 223 && char < 256))
                     s = StringSetChar(s, length, char - 32);
         else if(char > -33 && char < 0)
                     s = StringSetChar(s, length, char + 224);
   }
   return(s);
}


      


