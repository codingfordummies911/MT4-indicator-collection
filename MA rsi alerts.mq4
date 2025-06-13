#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1  clrSilver
#property indicator_color2  clrBlue
#property indicator_color3  clrBlue
#property indicator_color4  clrRed
#property indicator_color5  clrRed
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  2
#property strict

//
//
//
//
//

extern int                maPeriod        = 50;          // Ma period
extern ENUM_MA_METHOD     maMethod        = MODE_EMA;    // Ma method
extern ENUM_APPLIED_PRICE maPrice         = PRICE_CLOSE; // Ma price
extern int                rsiPeriod       = 40;          // Rsi period
extern int                rsiLevel        = 50;          // Rsi level to check (must be >= 50 and <=100)
extern int                LinesWidth      = 3;           // Lines width
extern bool               alertsOn        = true;        // Turn alerts on?
extern bool               alertsOnCurrent = false;       // Alerts on current (still opened) bar?
extern bool               alertsMessage   = true;        // Alerts should display alert message?
extern bool               alertsSound     = true;        // Alerts should play alert sound?
extern bool               alertsPushNotif = false;       // Alerts should send alert notification?
extern bool               alertsEmail     = false;       // Alerts should send alert email?
//---- buffers
double ma[],maua[],maub[],mada[],madb[],trend[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   IndicatorBuffers(6);
   SetIndexBuffer(0,ma);   SetIndexStyle(0,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(1,maua); SetIndexStyle(1,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(2,maub); SetIndexStyle(2,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(3,mada); SetIndexStyle(3,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(4,madb); SetIndexStyle(4,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(5,trend);
return(0);
}
int deinit() { return(0);}

//
//
//
//
//

int start()
{
   int i,counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
   
   //
   //
   //
   //
   //
   
   if (trend[limit]== 1) CleanPoint(limit,maua,maub);
   if (trend[limit]==-1) CleanPoint(limit,mada,madb);
   for(i=limit; i>=0; i--)
   {
       ma[i] = iMA(NULL,0,maPeriod, 0, maMethod, maPrice,i);
       double rsi = iRSI(NULL,0, rsiPeriod, maPrice,i);
       maua[i] = EMPTY_VALUE;            
       maub[i] = EMPTY_VALUE;            
       mada[i] = EMPTY_VALUE;            
       madb[i] = EMPTY_VALUE;   
       if (i<(Bars-1))
        {        
          trend[i] = 0;
            if (rsi >     rsiLevel) trend[i] =  1;
            if (rsi < 100-rsiLevel) trend[i] = -1; 
            if (trend[i] ==  1) PlotPoint(i,maua,maub,ma);
            if (trend[i] == -1) PlotPoint(i,mada,madb,ma);
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
        if (trend[whichBar] == 1)
              doAlert("up");
        else  doAlert("down");       
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

          message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," MA rsi ",doWhat);
             if (alertsMessage)   Alert(message);
             if (alertsPushNotif) SendNotification(message);
             if (alertsEmail)     SendMail(StringConcatenate(Symbol()," MA rsi "),message);
             if (alertsSound)     PlaySound("alert2.wav");
      }
}
