//+------------------------------------------------------------------+
//|                                                              rsi |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers  5
#property indicator_color1   DimGray
#property indicator_color2   DeepSkyBlue
#property indicator_color3   DeepSkyBlue
#property indicator_color4   PaleVioletRed
#property indicator_color5   PaleVioletRed
#property indicator_width2   3
#property indicator_width3   3
#property indicator_width4   3
#property indicator_width5   3
#property indicator_minimum  0
#property indicator_maximum  100

//
//
//
//
//

extern string TimeFrame         = "Current time frame";
extern int    Length            = 14;
extern int    Price             = PRICE_CLOSE;
extern double LevelUp           = 70;
extern double LevelDown         = 30;
extern bool   Interpolate       = true;
extern bool   alertsOn          = false;
extern bool   alertsOnZoneEnter = true;
extern bool   alertsOnZoneExit  = true;
extern bool   alertsOnCurrent   = true;
extern bool   alertsMessage     = true;
extern bool   alertsSound       = false;
extern bool   alertsEmail       = false;

//
//
//
//
//

double rsi[];
double rsiUa[];
double rsiUb[];
double rsiDa[];
double rsiDb[];
double trend[];

//
//
//
//
//

string indicatorFileName;
bool   returnBars;
bool   calculateValue;
int    timeFrame;

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
   IndicatorBuffers(6);
      SetIndexBuffer(0,rsi);
      SetIndexBuffer(1,rsiUa);
      SetIndexBuffer(2,rsiUb);
      SetIndexBuffer(3,rsiDa);
      SetIndexBuffer(4,rsiDb);
      SetIndexBuffer(5,trend);
         Length = MathMax(Length ,1);

   //
   //
   //
   //
   //

         indicatorFileName = WindowExpertName();
         calculateValue    = TimeFrame=="calculateValue"; if (calculateValue) { return(0); }
         returnBars        = TimeFrame=="returnBars";     if (returnBars)     { return(0); }
         timeFrame         = stringToTimeFrame(TimeFrame);

         //
         //
         //
         //
         //
         
         string PriceType;
         switch(Price)
         {
            case PRICE_CLOSE:    PriceType = "Close";    break;  // 0
            case PRICE_OPEN:     PriceType = "Open";     break;  // 1
            case PRICE_HIGH:     PriceType = "High";     break;  // 2
            case PRICE_LOW:      PriceType = "Low";      break;  // 3
            case PRICE_MEDIAN:   PriceType = "Median";   break;  // 4
            case PRICE_TYPICAL:  PriceType = "Typical";  break;  // 5
            case PRICE_WEIGHTED: PriceType = "Weighted"; break;  // 6
         }      

   //
   //
   //
   //
   //

   SetLevelValue(0,LevelUp);
   SetLevelValue(1,LevelDown);
   IndicatorShortName(timeFrameToString(timeFrame)+" RSI ("+Length+","+PriceType+")");
   return(0);
}
int deinit()
{
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
   int i,k,n,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { rsi[0] = MathMin(limit+1,Bars-1); return(0); }

   //
   //
   //
   //
   //
   //

   if (calculateValue || timeFrame == Period())
   {
      if (!calculateValue && trend[limit]== 1) CleanPoint(limit,rsiUa,rsiUb);
      if (!calculateValue && trend[limit]==-1) CleanPoint(limit,rsiDa,rsiDb);
      for(i=limit; i >= 0; i--)
      {
         rsi[i] = iRSI(NULL,0,Length,Price,i);
         
            trend[i] = trend[i+1];
               if (rsi[i]>LevelUp)                     trend[i]= 1;
               if (rsi[i]<LevelDown)                   trend[i]=-1;
               if (rsi[i]<LevelUp && rsi[i]>LevelDown) trend[i]= 0;
               if (!calculateValue && trend[i] ==  1) PlotPoint(i,rsiUa,rsiUb,rsi);
               if (!calculateValue && trend[i] == -1) PlotPoint(i,rsiDa,rsiDb,rsi);
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
   for (i=limit;i>=0;i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         rsi[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Length,Price,LevelUp,LevelDown,0,y);
         trend[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Length,Price,LevelUp,LevelDown,5,y);
         rsiUa[i] = EMPTY_VALUE;
         rsiUb[i] = EMPTY_VALUE;
         rsiDa[i] = EMPTY_VALUE;
         rsiDb[i] = EMPTY_VALUE;

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
            for(n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
            for(k = 1; k < n; k++)
               rsi[i+k] = rsi[i] + (rsi[i+n]-rsi[i])*k/n;
   }
   for (i=limit;i>=0;i--)
   {
      if (trend[i]== 1) PlotPoint(i,rsiUa,rsiUb,rsi);
      if (trend[i]==-1) PlotPoint(i,rsiDa,rsiDb,rsi);
   }
   
   //
   //
   //
   //
   //
   
   manageAlerts();
   return(0);   
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
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (alertsOnZoneEnter && trend[whichBar]   ==  1) doAlert(whichBar,DoubleToStr(LevelUp,2)  +" broken up");
         if (alertsOnZoneEnter && trend[whichBar]   == -1) doAlert(whichBar,DoubleToStr(LevelDown,2)+" broken down");
         if (alertsOnZoneExit  && trend[whichBar+1] == -1) doAlert(whichBar,DoubleToStr(LevelDown,2)+" broken up");
         if (alertsOnZoneExit  && trend[whichBar+1] ==  1) doAlert(whichBar,DoubleToStr(LevelUp,2)  +" broken down");
      }
   }
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

       message =  StringConcatenate(Symbol()," ",timeFrameToString(timeFrame)," at ",TimeToStr(TimeLocal(),TIME_SECONDS),"rsi level ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol(),"rsi"),message);
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

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = stringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
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

string stringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int tchar = StringGetChar(s, length);
         if((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
                     s = StringSetChar(s, length, tchar - 32);
         else if(tchar > -33 && tchar < 0)
                     s = StringSetChar(s, length, tchar + 224);
   }
   return(s);
}