//------------------------------------------------------------------
//
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_color1  LimeGreen
#property indicator_color2  PaleVioletRed
#property indicator_color3  LimeGreen
#property indicator_color4  PaleVioletRed
#property indicator_color5  Green
#property indicator_color6  Red
#property indicator_width3  3
#property indicator_width4  3
#property indicator_width5  1
#property indicator_width6  1

//
//
//
//
//

extern string TimeFrame       = "Current time frame";
extern int    RsiPeriod       = 21;
extern int    NlmPeriod       = 5;
extern int    Price           = 0;
extern double PctFilter       = 0;
extern bool   alertsOn        = false;
extern bool   alertsOnCurrent = true;
extern bool   alertsMessage   = true;
extern bool   alertsSound     = false;
extern bool   alertsEmail     = false;
extern bool   alertsNotify    = false;
extern bool   ShowArrows      = false;

//
//
//
//
//

double rsi[];
double rsihu[];
double rsihd[];
double rsihbu[];
double rsihbd[];
double CrossUp[];
double CrossDn[];
double trend[];

string indicatorFileName;
bool   returnBars;
bool   calculateValue;
int    timeFrame;

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
   SetIndexBuffer(0,rsihu);  SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(1,rsihd);  SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(2,rsihbu); SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(3,rsihbd); SetIndexStyle(3,DRAW_HISTOGRAM);
   SetIndexBuffer(4,CrossUp); 
   SetIndexBuffer(5,CrossDn);  
   SetIndexBuffer(6,rsi); 
   SetIndexBuffer(7,trend);
   
   if (ShowArrows)
   {
      SetIndexStyle(4,DRAW_ARROW); SetIndexArrow(4,233);
      SetIndexStyle(5,DRAW_ARROW); SetIndexArrow(5,234);
   }
   else
   {
      SetIndexStyle(4,DRAW_NONE);
      SetIndexStyle(5,DRAW_NONE); 
   }
   
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
      
   IndicatorShortName(timeFrameToString(timeFrame)+"   NonLagRsi Candles ("+RsiPeriod+")");
return(0);
}
  
//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//

int deinit()  {   return(0);  }

//
//
//
//
//

double work[][2];
#define _bchang 0
#define _achang 1

int start()
{
   int counted_bars=IndicatorCounted();
   int i,r,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { rsihu[0] = MathMin(limit+1,Bars-1); return(0); }

   
   //
   //
   //
   //
   //
   
   if (calculateValue || timeFrame == Period())
   {
      if (ArrayRange(work,0)!=Bars) ArrayResize(work,Bars);
      for(i=limit, r=Bars-i-1; i>=0; i--,r++)
      {
         rsi[i]    = iNonLagMa(iRsi(iMA(NULL,0,1,0,MODE_SMA,Price,i),RsiPeriod,i),NlmPeriod,i,0);
         rsihu[i]  = EMPTY_VALUE;
         rsihd[i]  = EMPTY_VALUE;
         rsihbu[i] = EMPTY_VALUE;
         rsihbd[i] = EMPTY_VALUE;
         trend[i]  = trend[i+1];

         //
         //
         //
         //
         //
               
         if (PctFilter>0)
         {
            work[r][_bchang] = MathAbs(rsi[i]-rsi[i+1]);
            work[r][_achang] = work[r][_bchang];
            for (int k=1; k<NlmPeriod; k++) work[r][_achang] += work[r-k][_bchang];
                                            work[r][_achang] /= 1.0*NlmPeriod;
    
            double stddev = 0; for (k=0; k<NlmPeriod; k++) stddev += MathPow(work[r-k][_bchang]-work[r-k][_achang],2);
                   stddev = MathSqrt(stddev/NlmPeriod); 
            double filter = PctFilter * stddev;
            if(MathAbs(rsi[i]-rsi[i+1]) < filter) rsi[i]=rsi[i+1];
         }

         //
         //
         //
         //
         //
               
         if (rsi[i]>rsi[i+1]) trend[i] =  1;
         if (rsi[i]<rsi[i+1]) trend[i] = -1;
            if (trend[i]== 1)
            {
               rsihu[i]  = High[i]; 
               rsihd[i]  = Low[i];
               rsihbu[i] = MathMax(Open[i],Close[i]);
               rsihbd[i] = MathMin(Open[i],Close[i]);
            }               
            if (trend[i]== -1)
            {
               rsihu[i]  = Low[i];
               rsihd[i]  = High[i];
               rsihbu[i] = MathMin(Open[i],Close[i]);
               rsihbd[i] = MathMax(Open[i],Close[i]);
            }
            
            //
            //
            //
            //
            //
            
            CrossUp[i] = EMPTY_VALUE;
            CrossDn[i] = EMPTY_VALUE;
            if (trend[i]!= trend[i+1])
            if (trend[i] == 1)
                  CrossUp[i] = Low[i]  - iATR(NULL,0,20,i)/2;
            else  CrossDn[i] = High[i] + iATR(NULL,0,20,i)/2;
                           
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
   for (i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         rsi[i]    = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,NlmPeriod,Price,PctFilter,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,6,y);
         rsihu[i]  = EMPTY_VALUE;
         rsihd[i]  = EMPTY_VALUE;
         rsihbu[i] = EMPTY_VALUE;
         rsihbd[i] = EMPTY_VALUE;
         trend[i] = trend[i+1];
            if (rsi[i]>rsi[i+1]) trend[i] =  1;
            if (rsi[i]<rsi[i+1]) trend[i] = -1;
            if (trend[i]== 1)
            {
              rsihu[i]  = High[i]; 
              rsihd[i]  = Low[i];
              rsihbu[i] = MathMax(Open[i],Close[i]);
              rsihbd[i] = MathMin(Open[i],Close[i]);
            }               
            if (trend[i]== -1)
            {
              rsihu[i]  = Low[i];
              rsihd[i]  = High[i];
              rsihbu[i] = MathMin(Open[i],Close[i]);
              rsihbd[i] = MathMax(Open[i],Close[i]);
            }
            
            //
            //
            //
            //
            //
            
            CrossUp[i] = EMPTY_VALUE;
            CrossDn[i] = EMPTY_VALUE;
            if (trend[i]!= trend[i+1])
            if (trend[i] == 1)
                  CrossUp[i] = Low[i]  - iATR(NULL,0,20,i)/2;
            else  CrossDn[i] = High[i] + iATR(NULL,0,20,i)/2;               
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

       message =  StringConcatenate(Symbol()," ",timeFrameToString(Period())," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," NonLagRsi slope changed to ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol(),"NonLag Rsi"),message);
          if (alertsNotify)  SendNotification(message);
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

#define Pi       3.14159265358979323846264338327950288
#define _length  0
#define _len     1
#define _weight  2

double  nlmvalues[3][1];
double  nlmprices[ ][1];
double  nlmalphas[ ][1];

//
//
//
//
//

double iNonLagMa(double price, double length, int r, int instanceNo=0)
{
   r = Bars-r-1;
   if (ArrayRange(nlmprices,0) != Bars) ArrayResize(nlmprices,Bars);
                               nlmprices[r][instanceNo]=price;
   if (length<3 || r<3) return(nlmprices[r][instanceNo]);
   
   //
   //
   //
   //
   //
   
   if (nlmvalues[_length][instanceNo] != length)
   {
      double Cycle = 4.0;
      double Coeff = 3.0*Pi;
      int    Phase = length-1;
      
         nlmvalues[_length][instanceNo] = length;
         nlmvalues[_len   ][instanceNo] = length*4 + Phase;  
         nlmvalues[_weight][instanceNo] = 0;

         if (ArrayRange(nlmalphas,0) < nlmvalues[_len][instanceNo]) ArrayResize(nlmalphas,nlmvalues[_len][instanceNo]);
         for (int k=0; k<nlmvalues[_len][instanceNo]; k++)
         {
            if (k<=Phase-1) 
                 double t = 1.0 * k/(Phase-1);
            else        t = 1.0 + (k-Phase+1)*(2.0*Cycle-1.0)/(Cycle*length-1.0); 
            double beta = MathCos(Pi*t);
            double g = 1.0/(Coeff*t+1); if (t <= 0.5 ) g = 1;
      
            nlmalphas[k][instanceNo]        = g * beta;
            nlmvalues[_weight][instanceNo] += nlmalphas[k][instanceNo];
         }
   }
   
   //
   //
   //
   //
   //
   
   if (nlmvalues[_weight][instanceNo]>0)
   {
      double sum = 0;
           for (k=0; k < nlmvalues[_len][instanceNo]; k++) sum += nlmalphas[k][instanceNo]*nlmprices[r-k][instanceNo];
           return( sum / nlmvalues[_weight][instanceNo]);
   }
   else return(0);           
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

double workRsi[][3];
#define _price  0
#define _change 1
#define _changa 2

//
//
//
//

double iRsi(double price, double period, int shift, int forz=0)
{
   if (ArrayRange(workRsi,0)!=Bars) ArrayResize(workRsi,Bars);
      int    z     = forz*3; 
      int    i     = Bars-shift-1;
      double alpha = 1.0/period; 

   //
   //
   //
   //
   //
   
   workRsi[i][_price+z] = price;
   if (i<period)
      {
         int k; double sum = 0; for (k=0; k<period && (i-k-1)>=0; k++) sum += MathAbs(workRsi[i-k][_price+z]-workRsi[i-k-1][_price+z]);
            workRsi[i][_change+z] = (workRsi[i][_price+z]-workRsi[0][_price+z])/MathMax(k,1);
            workRsi[i][_changa+z] =                                         sum/MathMax(k,1);
      }
   else
      {
         double change = workRsi[i][_price+z]-workRsi[i-1][_price+z];
                         workRsi[i][_change+z] = workRsi[i-1][_change+z] + alpha*(        change  - workRsi[i-1][_change+z]);
                         workRsi[i][_changa+z] = workRsi[i-1][_changa+z] + alpha*(MathAbs(change) - workRsi[i-1][_changa+z]);
      }
   if (workRsi[i][_changa+z] != 0)
         return(50.0*(workRsi[i][_change+z]/workRsi[i][_changa+z]+1));
   else  return(0);
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