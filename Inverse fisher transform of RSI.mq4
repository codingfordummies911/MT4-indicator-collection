//+------------------------------------------------------------------+
//|                              Inverse fisher transform of RSI.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property  copyright "mladen"
#property  link      "mladenfx@gmail.com"

#property  indicator_separate_window
#property  indicator_buffers   5
#property  indicator_color1    DimGray
#property  indicator_color2    Red
#property  indicator_color3    Red
#property  indicator_color4    DeepSkyBlue
#property  indicator_color5    DeepSkyBlue
#property  indicator_width2    2
#property  indicator_width3    2
#property  indicator_width4    2
#property  indicator_width5    2
#property  indicator_maximum   1
#property  indicator_minimum  -1

//
//
//
//
//

extern string TimeFrame   = "Current time frame";
extern int    RSIPeriod   =  5;
extern int    RSIPrice    =  PRICE_CLOSE;
extern int    MAPeriod    =  9;
extern int    MAMode      =  MODE_LWMA;
extern double Level1      =  0.5;
extern double Level2      =  0.0;
extern double Level3      = -0.5;
extern bool   Interpolate = true;

//
//
//
//
//

double ifishua[];
double ifishub[];
double ifishda[];
double ifishdb[];
double ifisher[];
double rsi[];
double avg[];
double trend[];

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
   IndicatorBuffers(8);
      SetIndexBuffer(0,ifisher);

      //
      //
      //
      //
      //
      
      indicatorFileName = WindowExpertName();
      returnBars        = TimeFrame=="returnBars";     if (returnBars)     return(0);
      calculateValue    = TimeFrame=="calculateValue";
         if (calculateValue)
         {
            SetIndexBuffer(1,trend);
            SetIndexBuffer(2,ifishda);
            SetIndexBuffer(3,ifishdb);
            SetIndexBuffer(4,ifishua);
            SetIndexBuffer(5,ifishub);
            SetIndexBuffer(6,rsi);
            SetIndexBuffer(7,avg);
            return(0);
         }         

      //
      //
      //
      //
      //
      
         SetIndexBuffer(1,ifishda);
         SetIndexBuffer(2,ifishdb);
         SetIndexBuffer(3,ifishua);
         SetIndexBuffer(4,ifishub);
         SetIndexBuffer(5,rsi);
         SetIndexBuffer(6,avg);
         SetIndexBuffer(7,trend);
      
         SetLevelValue(0,Level1);
         SetLevelValue(1,Level2);
         SetLevelValue(2,Level3);

   //
   //
   //
   //
   //
            
   timeFrame = stringToTimeFrame(TimeFrame);
   IndicatorShortName(timeFrameToString(timeFrame)+" inverse fisher of RSI ("+RSIPeriod+","+MAPeriod+")");
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
   int    limit, i; 
   int    counted_bars=IndicatorCounted();
   
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=MathMax(Bars-counted_bars,Bars-1);
           if (returnBars) { ifisher[0] = limit+1; return(0); }

   //
   //
   //
   //
   //
   
   if (calculateValue || timeFrame==Period())
   {
      if (!calculateValue) if (trend[limit]== 1) CleanPoint(limit,ifishua,ifishub);
      if (!calculateValue) if (trend[limit]==-1) CleanPoint(limit,ifishda,ifishdb);

      //
      //
      //
      //
      //
      
      for(i=limit; i>=0; i--) rsi[i] = 0.1*(iRSI(NULL,0,RSIPeriod,RSIPrice,i)-50);
      for(i=limit; i>=0; i--)
      {
         avg[i]     = iMAOnArray(rsi,0,MAPeriod,0,MAMode,i);
         ifisher[i] = (MathExp(2*avg[i])-1)/(MathExp(2*avg[i])+1);
         trend[i]   = trend[i+1];
            if (ifisher[i] < Level1 && ifisher[i] > Level3) trend[i] =  0;
            if (ifisher[i] > Level1)                        trend[i] =  1;
            if (ifisher[i] < Level3)                        trend[i] = -1;
            if (calculateValue) continue;
            
         //
         //
         //
         //
         //

            ifishda[i] = EMPTY_VALUE; ifishdb[i] = EMPTY_VALUE;         
            ifishua[i] = EMPTY_VALUE; ifishub[i] = EMPTY_VALUE;         
               if (trend[i]== 1) PlotPoint(i,ifishua,ifishub,ifisher);
               if (trend[i]==-1) PlotPoint(i,ifishda,ifishdb,ifisher);
      }
      return(0);
   }      

   //
   //
   //
   //
   //

   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));

   if (trend[limit]== 1) CleanPoint(limit,ifishua,ifishub);
   if (trend[limit]==-1) CleanPoint(limit,ifishda,ifishdb);
   for(i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         trend[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,MAPeriod,MAMode,Level1,Level2,Level3,1,y);
         ifisher[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,MAPeriod,MAMode,Level1,Level2,Level3,0,y);
         ifishda[i] = EMPTY_VALUE; 
         ifishdb[i] = EMPTY_VALUE;         
         ifishua[i] = EMPTY_VALUE; 
         ifishub[i] = EMPTY_VALUE;         

         //
         //
         //
         //
         //
      
         if (timeFrame <= Period() || y==iBarShift(NULL,timeFrame,Time[i-1])) continue;
         if (!Interpolate) continue;

         //
         //
         //
         //
         //

         datetime time = iTime(NULL,timeFrame,y);
            for(int n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
            double factor = 1.0 / n;
            for(int k = 1; k < n; k++)
               ifisher[i+k] = k*factor*ifisher[i+n] + (1.0-k*factor)*ifisher[i];
   }
   for(i=limit; i>=0; i--)
   {
      if (trend[i]== 1) PlotPoint(i,ifishua,ifishub,ifisher);
      if (trend[i]==-1) PlotPoint(i,ifishda,ifishdb,ifisher);
   }
   
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
   tfs = StringUpperCase(tfs);
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

string StringUpperCase(string str)
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