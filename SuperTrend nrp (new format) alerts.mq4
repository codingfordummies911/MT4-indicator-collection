//------------------------------------------------------------------
#property copyright "Copyright 2016, mladen - MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 clrLimeGreen
#property indicator_color2 clrOrange
#property indicator_color3 clrOrange
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property strict

extern int     period          = 10;              // Super trend period
extern double  multiplier      = 4.0;             // Super trend multiplier
extern bool    alertsOn        = false;           // Turn alerts on?
extern bool    alertsOnCurrent = false;           // Alerts on still opened bar?
extern bool    alertsMessage   = true;            // Alerts should display message?
extern bool    alertsSound     = false;           // Alerts should play a sound?
extern bool    alertsNotify    = false;           // Alerts should send a notification?
extern bool    alertsEmail     = false;           // Alerts should send an email?
extern string  soundFile       = "alert2.wav";    // Sound file

double Trend[],TrendDoA[],TrendDoB[],Direction[],Up[],Dn[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   IndicatorBuffers(6);
      SetIndexBuffer(0, Trend);
      SetIndexBuffer(1, TrendDoA);
      SetIndexBuffer(2, TrendDoB);
      SetIndexBuffer(3, Direction);
      SetIndexBuffer(4, Up);
      SetIndexBuffer(5, Dn);
   IndicatorShortName("SuperTrend");
   return(0);
}
void OnDeinit(const int reason) { }

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int &spread[])
{
   int counted_bars = prev_calculated;
      if(counted_bars < 0) return(-1);
      if(counted_bars > 0) counted_bars--;
           int limit=MathMin(rates_total-counted_bars,rates_total-1);

   //
   //
   //
   //
   //

   if (Direction[limit] <= 0) CleanPoint(limit,TrendDoA,TrendDoB);
   for(int i = limit; i >= 0; i--)
   {
      double atr    = iATR(NULL,0,period,i);
      double cprice =  close[i];
      double mprice = (high[i]+low[i])/2;
         Up[i]  = mprice+multiplier*atr;
         Dn[i]  = mprice-multiplier*atr;
         
         //
         //
         //
         //
         //
         
         Direction[i] = (i<rates_total-1) ? (cprice > Up[i+1]) ? 1 : (cprice < Dn[i+1]) ? -1 : Direction[i+1] : 0;
         TrendDoA[i]  = EMPTY_VALUE;
         TrendDoB[i]  = EMPTY_VALUE;
            if (Direction[i] ==  1) { Dn[i] = MathMax(Dn[i],Dn[i+1]); Trend[i] = Dn[i]; }
            if (Direction[i] == -1) { Up[i] = MathMin(Up[i],Up[i+1]); Trend[i] = Up[i]; PlotPoint(i,TrendDoA,TrendDoB,Trend); }
   }
   //
   //
   //
   //
   //
      
   if (alertsOn)
   {
      int whichBar = 1; if (alertsOnCurrent) whichBar = 0; 
      if (Direction[whichBar] != Direction[whichBar+1])
      {
         if (Direction[whichBar] == 1) doAlert(" up");
         if (Direction[whichBar] ==-1) doAlert(" down");       
      }         
   }              
   return(rates_total);
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

          message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+" super trend state changed to "+doWhat;
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(_Symbol+" super trend ",message);
             if (alertsSound)   PlaySound(soundFile);
      }
}

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
   if (i>Bars-2) return;
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (i>Bars-3) return;
   if (first[i+1] == EMPTY_VALUE)
         if (first[i+2] == EMPTY_VALUE) 
               { first[i]  = from[i]; first[i+1]  = from[i+1]; second[i] = EMPTY_VALUE; }
         else  { second[i] = from[i]; second[i+1] = from[i+1]; first[i]  = EMPTY_VALUE; }
   else        { first[i]  = from[i];                          second[i] = EMPTY_VALUE; }
}