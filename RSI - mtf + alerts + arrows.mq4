//+------------------------------------------------------------------+
//|                                                              rsi |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers    1
#property indicator_color1     clrLimeGreen
#property indicator_width1     2
#property indicator_minimum    0
#property indicator_maximum    100
#property indicator_level1     50
#property indicator_levelcolor clrMediumOrchid

//
//
//
//
//

extern ENUM_TIMEFRAMES    TimeFrame        = PERIOD_CURRENT;
extern int                RsiPeriod        = 14;
extern ENUM_APPLIED_PRICE RsiPrice         = PRICE_CLOSE;
extern bool               alertsOn         = true;
extern bool               alertsOnCurrent  = false;
extern bool               alertsMessage    = true;
extern bool               alertsSound      = false;
extern bool               alertsNotify     = false;
extern bool               alertsEmail      = false;
extern bool               arrowsVisible    = false;            // Arrows visible?
extern bool               arrowsOnNewest   = false;            // Arrows drawn on newst bar of higher time frame bar?
extern string             arrowsIdentifier = "rsi Arrows1";    // Unique ID for arrows
extern double             arrowsUpperGap   = 1.0;              // Upper arrow gap
extern double             arrowsLowerGap   = 1.0;              // Lower arrow gap
extern color              arrowsUpColor    = clrLimeGreen;     // Up arrow color
extern color              arrowsDnColor    = clrOrange;        // Down arrow color
extern int                arrowsUpCode     = 241;              // Up arrow code
extern int                arrowsDnCode     = 242;              // Down arrow code
extern bool               Interpolate      = true;

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
   IndicatorBuffers(2);
      SetIndexBuffer(0,rsi);
      SetIndexBuffer(1,trend);
      
      RsiPeriod         = MathMax(RsiPeriod ,1);
      indicatorFileName = WindowExpertName();
      returnBars        = TimeFrame==-99;
      TimeFrame         = MathMax(TimeFrame,_Period);
      
   IndicatorShortName(timeFrameToString(TimeFrame)+" RSI ("+RsiPeriod+")");
return(0);
}
int deinit()
{
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
   }
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

   if (TimeFrame == Period())
   {
      for(i=limit; i >= 0; i--)
      {
         rsi[i]   = iRSI(NULL,0,RsiPeriod,RsiPrice,i);
         trend[i] = trend[i+1];
            if (rsi[i]>50) trend[i]= 1;
            if (rsi[i]<50) trend[i]=-1;
            
            //
            //
            //
            //
            //
               
            if (arrowsVisible)
            {
               string lookFor = arrowsIdentifier+":"+(string)Time[i]; ObjectDelete(lookFor);            
                  if (trend[i] != trend[i+1])
                  {
                     if (trend[i] == 1) drawArrow(i,arrowsUpColor,arrowsUpCode,false);
                     if (trend[i] ==-1) drawArrow(i,arrowsDnColor,arrowsDnCode, true);
                  }
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
       {
         if (trend[whichBar] == 1) doAlert(whichBar,"crossed 50 up");
         if (trend[whichBar] ==-1) doAlert(whichBar,"crossed 50 down");
       }         
      }
      return(0);
   }   
   
   //
   //
   //
   //
   //

   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
   for (i=limit;i>=0; i--)
   {
      int y = iBarShift(NULL,TimeFrame,Time[i]);
         rsi[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiPrice,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,arrowsVisible,arrowsOnNewest,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,0,y);
          
         //
         //
         //
         //
         //
            
         if (!Interpolate || y==iBarShift(NULL,TimeFrame,Time[i-1])) continue;

          //
          //
          //
          //
          //

          datetime time = iTime(NULL,TimeFrame,y);
          for(int n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
          for(int k = 1; k < n; k++) rsi[i+k] = rsi[i] + (rsi[i+n] - rsi[i])* k/n;
      
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

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
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

           message =  StringConcatenate(Symbol()," ",timeFrameToString(_Period)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," Rsi ",doWhat);
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol(), Period(), " Rsi "),message);
             if (alertsSound)   PlaySound("alert2.wav");
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

void drawArrow(int i,color theColor,int theCode,bool up)
{
   string name = arrowsIdentifier+":"+(string)Time[i];
   double gap  = iATR(NULL,0,20,i);   
   
      //
      //
      //
      //
      //

      datetime time = Time[i]; if (arrowsOnNewest) time += _Period*60-1;      
      ObjectCreate(name,OBJ_ARROW,0,time,0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsUpperGap * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsLowerGap * gap);
}
