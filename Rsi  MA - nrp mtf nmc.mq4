//+------------------------------------------------------------------+
//|                                                           rsi ma |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1  DeepSkyBlue
#property indicator_color2  OrangeRed
#property indicator_color3  OrangeRed
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_minimum -1
#property indicator_maximum 101

//
//
//
//
//

extern string TimeFrame   = "Current time frame";
extern int    RsiPeriod   = 14;
extern int    RsiPrice    = PRICE_CLOSE;
extern bool   Interpolate = true;

//
//
//
//
//

double values[];
double valuesDa[];
double valuesDb[];
double trend[];

//
//
//
//
//

string indicatorFileName;
bool   calculateValue;
bool   returnBars;
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
   IndicatorBuffers(4);
      SetIndexBuffer(0,values);
      SetIndexBuffer(1,valuesDa);
      SetIndexBuffer(2,valuesDb);
      SetIndexBuffer(3,trend);

      //
      //
      //
      //
      //

      indicatorFileName = WindowExpertName();
      calculateValue    = (TimeFrame=="calculateValue"); if (calculateValue) return(0);
      returnBars        = (TimeFrame=="returnBars");     if (returnBars)     return(0);
      timeFrame         = stringToTimeFrame(TimeFrame);

   //
   //
   //
   //
   //
      
   IndicatorShortName(timeFrameToString(timeFrame)+" rsi ma ("+RsiPeriod+")");
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
   int counted_bars=IndicatorCounted();
   int i,limit;

      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
            limit = MathMin(Bars-counted_bars,Bars-1);
            if (returnBars) { values[0] = limit+1; return(0); }

   //
   //
   //
   //
   //

   if (calculateValue || timeFrame == Period())
   {
      if (!calculateValue && trend[limit]==-1) CleanPoint(limit,valuesDa,valuesDb);
      for(i=limit; i>=0; i--)
      {
         int maSlope   = (iMA(NULL,0,RsiPeriod,0,MODE_EMA,PRICE_WEIGHTED,i)-iMA(NULL,0,RsiPeriod,0,MODE_EMA,PRICE_WEIGHTED,i+1))/Point;
             values[i] = MathMax(MathMin(iRSI(NULL,0,RsiPeriod,RsiPrice,i)*maSlope,100),0);
             valuesDa[i] = EMPTY_VALUE;
             valuesDb[i] = EMPTY_VALUE;
             trend[i]    = trend[i+1];

             if (values[i]>values[i+1]) trend[i] =  1;
             if (values[i]<values[i+1]) trend[i] = -1;
             if (!calculateValue && trend[i]==-1) PlotPoint(i,valuesDa,valuesDb,values);
      }
      return(0);
   }   
      
   //
   //
   //
   //
   //
   
   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
   if (trend[limit]==-1) CleanPoint(limit,valuesDa,valuesDb);
   for (i=limit;i>=0;i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         trend[i]    = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,3,y);
         values[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,0,y);
         valuesDa[i] = EMPTY_VALUE;
         valuesDb[i] = EMPTY_VALUE;

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
            for(int n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
            for(int k = 1; k < n; k++)
               values[i+k] = values[i] + (values[i+n]-values[i])*k/n;
   }
   for (i=limit;i>=0;i--) if (trend[i]==-1) PlotPoint(i,valuesDa,valuesDb,values);

   //
   //
   //
   //
   //
   
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