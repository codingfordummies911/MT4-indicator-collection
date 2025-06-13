//+------------------------------------------------------------------+
//|                        Smoothed Rsi Inverse Fisher Transform.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1  PaleVioletRed
#property indicator_width1  2
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_levelcolor DimGray

//
//
//
//
//

extern string TimeFrame   = "Current time frame";
extern int    RsiPeriod   = 4;
extern int    EmaPeriod   = 4;
extern int    RwmaPeriod  = 2;
extern int    RwmaDepth   = 10;
extern int    RwmaPrice   = PRICE_CLOSE;
extern double LevelUp     = 88;
extern double LevelDown   = 12;
extern bool   Interpolate = true;

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

#define MAX_depth 50
double  inv[];
double  rwm[];
double  ema1[];
double  ema2[];
double  trend[];
double  pBuffer[][MAX_depth];

//
//
//
//
//

int    timeFrame;
string indicatorFileName;
bool   returnBars;
bool   calculateValue;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

#define noCheckValue 9999991
int init()
{
   IndicatorBuffers(5);
      SetIndexBuffer(0,inv);
      SetIndexBuffer(1,rwm);
      SetIndexBuffer(2,ema1);
      SetIndexBuffer(3,ema2);
      SetIndexBuffer(4,trend);
      
      //
      //
      //
      //
      //
      
         RwmaPeriod        = MathMax(RwmaPeriod,2);
         RwmaDepth         = MathMax(MathMin(RwmaDepth,MAX_depth),5);
         indicatorFileName = WindowExpertName();

               if (LevelDown>LevelUp)
               {
                  double temp = LevelUp;
                                LevelUp = LevelDown;
                                          LevelDown = temp;
               }
               if (LevelUp   < 0 || LevelUp   > 100) LevelUp   =  noCheckValue; SetLevelValue(0,LevelUp);
               if (LevelDown < 0 || LevelDown > 100) LevelDown = -noCheckValue; SetLevelValue(1,LevelDown);
            
         calculateValue    = (TimeFrame=="calculateValue"); if (calculateValue) return(0);
         returnBars        = (TimeFrame=="returnBars");     if (returnBars)     return(0);
         timeFrame         = stringToTimeFrame(TimeFrame);
         
      //
      //
      //
      //
      //
               
   IndicatorShortName(timeFrameToString(timeFrame)+" Smoothed Rsi Inverse Fisher Transform ("+RsiPeriod+","+EmaPeriod+","+RwmaPeriod+","+RwmaDepth+")");
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
   int i,k,l,n,r,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { inv[0] = limit+1; return(0); }

   //
   //
   //
   //
   //
   
   if (calculateValue || timeFrame == Period())
   {
      if (ArrayRange(pBuffer,0) != Bars) ArrayResize(pBuffer,Bars);
      
      //
      //
      //
      //
      //
      
      double alpha  = 2.0 / (1+EmaPeriod);
      double weight = (RwmaPeriod+1.0)*RwmaPeriod*0.5;
      for(i=limit, r=Bars-limit-1; i>=0; i--,r++)
      {
         double price = iMA(NULL,0,1,0,MODE_SMA,RwmaPrice,i);
         double coeff = 5;
         double sum   = 0;
         double sumc  = 0;
            for (k=0; k<RwmaDepth; k++)
            {
               pBuffer[r][k] = price;
               if (r>RwmaPeriod)
               {
                  for (l=0, price=0; l<RwmaPeriod; l++) price += (RwmaPeriod-l)*pBuffer[r-l][k];
                                                        price /= weight;
               }
               sum  += coeff*price;
               sumc += coeff;
               coeff = MathMax(coeff-1,1);
            }
            rwm[i] = sum/sumc;
      }

      //
      //
      //
      //
      //
      
      for(i=limit; i>=0; i--)
      {
         double rsi      = 0.1 * (iRSIOnArray(rwm,0,RsiPeriod,i)-50.0);
                ema1[i]  = ema1[i+1]+alpha*(rsi    -ema1[i+1]);
                ema2[i]  = ema2[i+1]+alpha*(ema1[i]-ema2[i+1]);
         double zlema    = 2.0*ema1[i]-ema2[i];
                inv[i]   = ((MathExp(2.0*zlema)-1.0)/(MathExp(2.0*zlema)+1.0)+1.0)*50.0;
                trend[i] = trend[i+1];
                     if (inv[i]>LevelUp  )                   trend[i] =  1;
                     if (inv[i]<LevelDown)                   trend[i] = -1;
                     if (inv[i]<LevelUp && inv[i]>LevelDown) trend[i] =  0;
      }
      manageAlerts();
      return(0);
   }

   //
   //
   //
   //
   //

   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
   for(i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         inv[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,EmaPeriod,RwmaPeriod,RwmaDepth,RwmaPrice,LevelUp,LevelDown,0,y);
         trend[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,EmaPeriod,RwmaPeriod,RwmaDepth,RwmaPrice,LevelUp,LevelDown,4,y);
            
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
               inv[i+k] = inv[i] + (inv[i+n]-inv[i])*k/n;
   }
   manageAlerts();
   
   //
   //
   //
   //
   //
            
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
         if (alertsOnZoneEnter && trend[whichBar]   == 1)                        doAlert(whichBar,DoubleToStr(LevelUp  ,2)+" crossed up");
         if (alertsOnZoneEnter && trend[whichBar]   ==-1)                        doAlert(whichBar,DoubleToStr(LevelDown,2)+" crossed down");
         if (alertsOnZoneExit  && trend[whichBar+1] == 1 && trend[whichBar]!=-1) doAlert(whichBar,DoubleToStr(LevelUp  ,2)+" crossed down");
         if (alertsOnZoneExit  && trend[whichBar+1] ==-1 && trend[whichBar]!= 1) doAlert(whichBar,DoubleToStr(LevelDown,2)+" crossed up");
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

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," ",timeFrameToString(timeFrame)," Smoothed Rsi IFT level ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," Smoothed Rsi ift "),message);
          if (alertsSound)   PlaySound("alert2.wav");
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