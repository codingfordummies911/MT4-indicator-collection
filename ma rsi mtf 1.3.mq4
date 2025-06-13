//------------------------------------------------------------------
//
//------------------------------------------------------------------
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1  clrSilver
#property indicator_color2  clrDodgerBlue
#property indicator_color3  clrDodgerBlue
#property indicator_color4  clrSandyBrown
#property indicator_color5  clrSandyBrown
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  2
#property strict

extern ENUM_TIMEFRAMES    timeFrame       = 0;           // Time frame to use
extern int                maPeriod        = 50;          // Ma period
extern ENUM_MA_METHOD     maMethod        = MODE_EMA;    // Ma method
extern ENUM_APPLIED_PRICE maPrice         = PRICE_CLOSE; // Ma price
extern int                rsiPeriod       = 40;          // Rsi period
extern int                rsiLevel        = 50;          // Rsi level to check (must be >= 50 and <=100)
extern bool               alertsOn        = false;       // Turn alerts on?
extern bool               alertsOnCurrent = true;        // Alerts on current (still opened) bar?
extern bool               alertsMessage   = true;        // Alerts should display a message?
extern bool               alertsSound     = false;       // Alerts should play a sound?
extern bool               alertsEmail     = false;       // Alerts should send an email?
extern int                LinesWidth      = 3;           // Lines width
extern bool               Interpolate     = true;        // Interpolate in mtf mode

double ma[],maua[],maub[],mada[],madb[],rsistate[];
string indicatorFileName;
bool   returnBars;

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//

int init()
{
   IndicatorBuffers(6);
   SetIndexBuffer(0,ma);   SetIndexStyle(0,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(1,maua); SetIndexStyle(1,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(2,maub); SetIndexStyle(2,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(3,mada); SetIndexStyle(3,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(4,madb); SetIndexStyle(4,EMPTY,EMPTY,LinesWidth);
   SetIndexBuffer(5,rsistate);
      indicatorFileName = WindowExpertName();
      returnBars        = timeFrame == -99;
      timeFrame         = MathMax(timeFrame,_Period);
   return(0);
}
int start()
{
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
            int limit=MathMin(Bars-counted_bars,Bars-1);
            if (returnBars) { ma[0] = limit+1; return(0); }
            if (timeFrame!=_Period) limit = (int)MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,-99,0,0)*timeFrame/Period()));

   //
   //
   //
   //
   //

   if (rsistate[limit]== 1) CleanPoint(limit,maua,maub);
   if (rsistate[limit]==-1) CleanPoint(limit,mada,madb);
   for(int i=limit; i>=0; i--)
     {
         int y = iBarShift(NULL,timeFrame,Time[i]);
            ma[i] = iMA(NULL,timeFrame,maPeriod, 0, maMethod, maPrice, y);
            double rsi = iRSI(NULL,timeFrame, rsiPeriod, maPrice, y);
         maua[i] = EMPTY_VALUE;            
         maub[i] = EMPTY_VALUE;            
         mada[i] = EMPTY_VALUE;            
         madb[i] = EMPTY_VALUE;            
         rsistate[i] = 0;
            if (rsi >     rsiLevel)rsistate[i] =  1;
            if (rsi < 100-rsiLevel)rsistate[i] = -1;
            if (!Interpolate || (i>0 && y==iBarShift(NULL,timeFrame,Time[i-1]))) continue;
                  
            //
            //
            //
            //
            //
                  
            int n,k; datetime time = iTime(NULL,timeFrame,y);
               for(n = 1; (i+n)<Bars && Time[i+n] >= time; n++) continue;	
               for(k = 1; k<n && (i+n)<Bars && (i+k)<Bars; k++) ma[i+k] = ma[i] + (ma[i+n] - ma[i] ) * k/n;
   }
   for(int i=limit; i>=0; i--)
   {
      if (rsistate[i] ==  1) PlotPoint(i,maua,maub,ma);
      if (rsistate[i] == -1) PlotPoint(i,mada,madb,ma);
   }      
   manageAlerts();
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

void manageAlerts()
{
   if (alertsOn)
   {
      int whichBar = 1; if (alertsOnCurrent) whichBar = 0;
      
      //
      //
      //
      //
      //
      
      static datetime time1 = 0;
      static string   mess1 = "";
         if (rsistate[whichBar] != rsistate[whichBar+1])
         {
            if (rsistate[whichBar] ==  1) doAlert(time1,mess1,whichBar," ma rsi trend changed to up");
            if (rsistate[whichBar] == -1) doAlert(time1,mess1,whichBar," ma rsi trend changed to down");
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

          message =  timeFrameToString(timeFrame)+" "+Symbol()+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+doWhat;
             if (alertsMessage) Alert(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol()," Step Kwan "),message);
             if (alertsSound)   PlaySound("alert2.wav");
      }
}

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