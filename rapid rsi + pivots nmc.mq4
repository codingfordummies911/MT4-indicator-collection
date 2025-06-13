//------------------------------------------------------------------
#property copyright "www,forex-station.com"
#property link      "www,forex-station.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_color1  LimeGreen
#property indicator_color2  LimeGreen
#property indicator_color3  LimeGreen
#property indicator_color4  Silver
#property indicator_color5  PaleVioletRed
#property indicator_color6  PaleVioletRed
#property indicator_color7  PaleVioletRed
#property indicator_color8  DimGray
#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DOT
#property indicator_style3  STYLE_DOT
#property indicator_style4  STYLE_DOT
#property indicator_style5  STYLE_DOT
#property indicator_style6  STYLE_DOT
#property indicator_style7  STYLE_DOT
#property indicator_width8  2

extern int    RsiPeriod      = 50;
extern int    RsiPrice       = PRICE_CLOSE;
extern int    Filter         = 3;
extern int    FilterMode     = MODE_LWMA;
extern string PivotTimeFrame = "H4";
extern int    Level          = 2;

double tp[];
double tr1[];
double tr2[];
double tr3[];
double ts1[];
double ts2[];
double ts3[];
double rsi[];
int TimeFrame;

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
   SetIndexBuffer(0,tr3);
   SetIndexBuffer(1,tr2);
   SetIndexBuffer(2,tr1);
   SetIndexBuffer(3,tp);
   SetIndexBuffer(4,ts1);
   SetIndexBuffer(5,ts2);
   SetIndexBuffer(6,ts3);
   SetIndexBuffer(7,rsi);
      TimeFrame = stringToTimeFrame(PivotTimeFrame);
   IndicatorShortName("Rapid Rsi + "+timeFrameToString(TimeFrame)+" pivots ("+RsiPeriod+")");
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

int start()
{
   int i,countedBars = IndicatorCounted();
      if (countedBars<0) return(-1);
      if (countedBars>0) countedBars--;
         int limit = MathMin(Bars-countedBars,Bars-1);

   for(i=limit; i>=0; i--)
   {
      rsi[i] = iRapidRsi(iMA(NULL,0,Filter,0,FilterMode,RsiPrice,i),RsiPeriod,i);
      if (TimeFrame>Period())
      {
         double phigh,plow,pclose;
            findPivot(phigh,plow,pclose,rsi[i],rsi[i],rsi[i],TimeFrame,i);
            double pivot = (phigh+plow+pclose)/3.0;
            double range = (phigh-plow);
            tp[i]  = pivot;
               if (Level>0) tr1[i] = pivot*2-plow;
               if (Level>1) tr2[i] = pivot  +range;
               if (Level>2) tr3[i] = pivot*2+phigh-plow*2;
               if (Level>0) ts1[i] = pivot*2-phigh;
               if (Level>1) ts2[i] = pivot  -range;
               if (Level>2) ts3[i] = pivot*2+plow-phigh*2;
      }
   }
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

double workRRsi[][1];
double iRapidRsi(double price, int period, int i, int instanceNo=0)
{
   if (ArrayRange(workRRsi,0) != Bars) ArrayResize(workRRsi,Bars); i=Bars-i-1;
   
   //
   //

   workRRsi[i][instanceNo] = price;
   
      double up   =0;
      double down =0;
      for(int k=0;  k<period && (i-k-1)>=0; k++)
      {
         double diff = workRRsi[i-k][instanceNo]-workRRsi[i-k-1][instanceNo];
         if(diff>0)
               up   += diff;
         else  down -= diff;
      }
      double trsi = 0; if((up+down) != 0) trsi = 100.0 * up / (up + down);
      return(trsi);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workPiv[][3];
#define _high  0
#define _low   1
#define _close 2

void findPivot(double &phigh, double &plow, double &pclose, double vhigh, double vlow, double vclose, int timeFrame, int i)
{
   if (ArrayRange(workPiv,0) != Bars) ArrayResize(workPiv,Bars); int r = Bars-i-1;
      workPiv[r][_high]  = vhigh;
      workPiv[r][_low ]  = vlow;
      workPiv[r][_close] = vclose;
      
   //
   //
   //
   //
   //
 
      i = iBarShift(NULL,timeFrame,Time[i]);
         datetime startTime = iTime(NULL,timeFrame,i+1);
         datetime endTime   = iTime(NULL,timeFrame,i);
      i = iBarShift(NULL,0,endTime)+1; r=Bars-i-1;

      //
      //
      //
      //
      //
      
      pclose = workPiv[r][_close];
      phigh  = workPiv[r][_high];
      plow   = workPiv[r][_low];

      for (i++,r--; Time[i]>=startTime && r>=0; i++,r--)      
      {
            phigh = MathMax(workPiv[r][_high],phigh);
            plow  = MathMin(workPiv[r][_low] ,plow );
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
string stringUpperCase(string str) { StringToUpper(str); return(str); }