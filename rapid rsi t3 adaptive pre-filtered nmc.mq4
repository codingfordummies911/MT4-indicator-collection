//+------------------------------------------------------------------+
//|                                                  rsi of averages |
//+------------------------------------------------------------------+
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers   3
#property indicator_color1    LimeGreen
#property indicator_color2    Orange
#property indicator_color3    Orange
#property indicator_width1    2
#property indicator_width2    2
#property indicator_width3    2
#property indicator_level1    20
#property indicator_level2    80
#property indicator_minimum  -5
#property indicator_maximum 105

//
//
//
//
//

extern string TimeFrame       = "Current time frame";
extern int    RsiPeriod       = 25;
extern double T3Period        = 15;
extern double T3Hot           = 0.7;
extern bool   T3Original      = true;
extern int    AdaptPeriod     = 25;
extern int    Price           = PRICE_CLOSE;
extern bool   alertsOn        = false;
extern bool   alertsOnCurrent = true;
extern bool   alertsMessage   = true;
extern bool   alertsSound     = false;
extern bool   alertsEmail     = false;
extern bool   Interpolate     = true;

//
//
//
//
//

double buffer1[];
double buffer2[];
double buffer3[];
double trend[];
double ma[];

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
   IndicatorBuffers(5);
   SetIndexBuffer(0,buffer1);
   SetIndexBuffer(1,buffer2);
   SetIndexBuffer(2,buffer3);
   SetIndexBuffer(3,trend);
   SetIndexBuffer(4,ma);
   
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
               
   IndicatorShortName(timeFrameToString(timeFrame)+" Rapid Rsi adaptive T3 filtered ("+RsiPeriod+","+T3Period+")");
return(0);
}
int deinit() { return(0); }

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
   int i,k,n,counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
           int limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { buffer1[0] = MathMin(limit+1,Bars-1); return(0); }

   //
   //
   //
   //
   //

   if (calculateValue || timeFrame == Period())
   {
      if (trend[limit]==-1) CleanPoint(limit,buffer2,buffer3);
      for(i=limit; i>=0; i--)
      {
         double dev = iStdDev(NULL,0,AdaptPeriod,0,MODE_SMA,Price,i);
         double avg = iSma(dev,AdaptPeriod,i,0);
            if (dev!=0) 
                   double period = T3Period*avg/dev;
            else          period = T3Period; 
            if (period<3) period = 3;
         ma[i] = iT3(iMA(NULL,0,1,0,MODE_SMA,Price,i),period,T3Hot,T3Original,i,0);
         double up   =0;
         double down =0;
         double diff =0;
         for( k=0;  k<RsiPeriod; k++)
         {
            diff = ma[i+k]- ma[i+k+1];
            if(diff>0)
                  up   += diff;
            else  down -= diff;
         }
         if(up + down == 0)
               buffer1[i] = 50;
         else  buffer1[i] = 100 * up / (up + down);         
         buffer2[i] = EMPTY_VALUE;
         buffer3[i] = EMPTY_VALUE;
         trend[i]   = trend[i+1];
            if (buffer1[i]>buffer1[i+1]) trend[i] =  1;
            if (buffer1[i]<buffer1[i+1]) trend[i] = -1;
            if (trend[i]==-1) PlotPoint(i,buffer2,buffer3,buffer1);
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
   if (trend[limit]==-1) CleanPoint(limit,buffer2,buffer3);
   for (i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         trend[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,T3Period,T3Hot,T3Original,AdaptPeriod,Price,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,3,y);
         buffer1[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,T3Period,T3Hot,T3Original,AdaptPeriod,Price,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,0,y);
         buffer2[i] = EMPTY_VALUE;
         buffer3[i] = EMPTY_VALUE;

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
                  buffer1[i+k] = buffer1[i] + (buffer1[i+n] - buffer1[i])*k/n;
   }
   for (i=limit;i>=0;i--) if (trend[i]==-1) PlotPoint(i,buffer2,buffer3,buffer1);
   
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
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; 
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] ==  1) doAlert(whichBar,"up");
         if (trend[whichBar] == -1) doAlert(whichBar,"down");
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

       message =  StringConcatenate(timeFrameToString(Period())+" "+Symbol()," ",timeFrameToString(timeFrame)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," rapid Rsi of slope changed to ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," rapid rsi t3"),message);
          if (alertsSound)   PlaySound("alert2.wav");
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

double workSma[][2];
double iSma(double price, int period, int r, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= Bars) ArrayResize(workSma,Bars); instanceNo *= 2; r = Bars-r-1;

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

double workT3[][6];
double workT3Coeffs[][6];
#define _period 0
#define _c1     1
#define _c2     2
#define _c3     3
#define _c4     4
#define _alpha  5

//
//
//
//
//

double iT3(double price, double period, double hot, bool original, int i, int instanceNo=0)
{
   if (ArrayRange(workT3,0) !=Bars)                 ArrayResize(workT3,Bars);
   if (ArrayRange(workT3Coeffs,0) < (instanceNo+1)) ArrayResize(workT3Coeffs,instanceNo+1);

   if (workT3Coeffs[instanceNo][_period] != period)
   {
     workT3Coeffs[instanceNo][_period] = period;
        double a = hot;
            workT3Coeffs[instanceNo][_c1] = -a*a*a;
            workT3Coeffs[instanceNo][_c2] = 3*a*a+3*a*a*a;
            workT3Coeffs[instanceNo][_c3] = -6*a*a-3*a-3*a*a*a;
            workT3Coeffs[instanceNo][_c4] = 1+3*a+a*a*a+3*a*a;
            if (original)
                 workT3Coeffs[instanceNo][_alpha] = 2.0/(1.0 + period);
            else workT3Coeffs[instanceNo][_alpha] = 2.0/(2.0 + (period-1.0)/2.0);
   }
   
   //
   //
   //
   //
   //
   
   int buffer = instanceNo*6;
   int r = Bars-i-1;
   if (r == 0)
      {
         workT3[r][0+buffer] = price;
         workT3[r][1+buffer] = price;
         workT3[r][2+buffer] = price;
         workT3[r][3+buffer] = price;
         workT3[r][4+buffer] = price;
         workT3[r][5+buffer] = price;
      }
   else
      {
         workT3[r][0+buffer] = workT3[r-1][0+buffer]+workT3Coeffs[instanceNo][_alpha]*(price              -workT3[r-1][0+buffer]);
         workT3[r][1+buffer] = workT3[r-1][1+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][0+buffer]-workT3[r-1][1+buffer]);
         workT3[r][2+buffer] = workT3[r-1][2+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][1+buffer]-workT3[r-1][2+buffer]);
         workT3[r][3+buffer] = workT3[r-1][3+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][2+buffer]-workT3[r-1][3+buffer]);
         workT3[r][4+buffer] = workT3[r-1][4+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][3+buffer]-workT3[r-1][4+buffer]);
         workT3[r][5+buffer] = workT3[r-1][5+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][4+buffer]-workT3[r-1][5+buffer]);
      }

   //
   //
   //
   //
   //
   
   return(workT3Coeffs[instanceNo][_c1]*workT3[r][5+buffer] + 
          workT3Coeffs[instanceNo][_c2]*workT3[r][4+buffer] + 
          workT3Coeffs[instanceNo][_c3]*workT3[r][3+buffer] + 
          workT3Coeffs[instanceNo][_c4]*workT3[r][2+buffer]);
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

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1","M5","M10","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,10,15,30,60,240,1440,10080,43200};

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