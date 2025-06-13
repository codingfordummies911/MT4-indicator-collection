//+------------------------------------------------------------------+
//|                                                              rsi |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers  5
#property indicator_color1   Gray
#property indicator_color2   LimeGreen
#property indicator_color3   LimeGreen
#property indicator_color4   Orange
#property indicator_color5   Orange
#property indicator_width1   2
#property indicator_width2   2
#property indicator_width3   2
#property indicator_width4   2
#property indicator_minimum  0
#property indicator_maximum  100

//
//
//
//
//

extern ENUM_TIMEFRAMES  TimeFrame    = PERIOD_CURRENT;
extern string ForSymbol              = "";
extern int    Length                 = 14;
extern ENUM_APPLIED_PRICE Price      = PRICE_CLOSE;
extern double LevelUp                = 70;
extern double LevelDown              = 30;
extern bool   alertsOn               = false;
extern bool   alertsOnZoneEnter      = true;
extern bool   alertsOnZoneExit       = true;
extern bool   alertsOnCurrent        = true;
extern bool   alertsMessage          = true;
extern bool   alertsSound            = false;
extern bool   alertsEmail            = false;

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
   IndicatorBuffers(6);
      SetIndexBuffer(0,rsi);
      SetIndexBuffer(1,rsiUa);
      SetIndexBuffer(2,rsiUb);
      SetIndexBuffer(3,rsiDa);
      SetIndexBuffer(4,rsiDb);
      SetIndexBuffer(5,trend);
      SetLevelValue(0,LevelUp);
      SetLevelValue(1,LevelDown);
      
         Length = MathMax(Length ,1);
         indicatorFileName = WindowExpertName();
         returnBars        = TimeFrame==-99;
         TimeFrame         = MathMax(TimeFrame,_Period);
         if (ForSymbol=="") ForSymbol = Symbol(); 
   
   IndicatorShortName(timeFrameToString(TimeFrame)+" "+ForSymbol+" RSI ("+Length+")");
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
   int i,limit;

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

   if (ForSymbol == Symbol() && TimeFrame == Period())
   {
      if (trend[limit]== 1) CleanPoint(limit,rsiUa,rsiUb);
      if (trend[limit]==-1) CleanPoint(limit,rsiDa,rsiDb);
      for(i=limit; i >= 0; i--)
      {
         rsi[i]   = iRSI(NULL,0,Length,Price,i);
         rsiUa[i] = EMPTY_VALUE;
         rsiUb[i] = EMPTY_VALUE;
         rsiDa[i] = EMPTY_VALUE;
         rsiDb[i] = EMPTY_VALUE;
         trend[i] = trend[i+1];
            if (rsi[i]>LevelUp)                     trend[i]= 1;
            if (rsi[i]<LevelDown)                   trend[i]=-1;
            if (rsi[i]<LevelUp && rsi[i]>LevelDown) trend[i]= 0;
            if (trend[i] ==  1) PlotPoint(i,rsiUa,rsiUb,rsi);
            if (trend[i] == -1) PlotPoint(i,rsiDa,rsiDb,rsi);
      }
      manageAlerts();
      return(0);
   }   
   
   //
   //
   //
   //
   //

   limit = MathMax(limit,MathMin(Bars-1,iCustom(ForSymbol,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
   if (trend[limit]== 1) CleanPoint(limit,rsiUa,rsiUb);
   if (trend[limit]==-1) CleanPoint(limit,rsiDa,rsiDb);
   for (i=limit;i>=0;i--)
   {
      int y = iBarShift(ForSymbol,TimeFrame,Time[i]);
         rsi[i]   = iCustom(ForSymbol,TimeFrame,indicatorFileName,PERIOD_CURRENT,"",Length,Price,LevelUp,LevelDown,alertsOn,alertsOnZoneEnter,alertsOnZoneExit,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,0,y);
         trend[i] = iCustom(ForSymbol,TimeFrame,indicatorFileName,PERIOD_CURRENT,"",Length,Price,LevelUp,LevelDown,alertsOn,alertsOnZoneEnter,alertsOnZoneExit,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,5,y);
         rsiUa[i] = EMPTY_VALUE;
         rsiUb[i] = EMPTY_VALUE;
         rsiDa[i] = EMPTY_VALUE;
         rsiDb[i] = EMPTY_VALUE;
            if (trend[i]== 1) PlotPoint(i,rsiUa,rsiUb,rsi);
            if (trend[i]==-1) PlotPoint(i,rsiDa,rsiDb,rsi);
   }
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
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; 
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

       message =  StringConcatenate(ForSymbol," ",timeFrameToString(Period())," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," rsi level ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(ForSymbol," rsi "),message);
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