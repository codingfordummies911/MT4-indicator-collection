//+------------------------------------------------------------------+
//|                                  Dynamic zone ab RSI of MACD.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1  DeepSkyBlue
#property indicator_color2  LimeGreen
#property indicator_color3  DimGray
#property indicator_color4  Red
#property indicator_style3  STYLE_DOT
#property indicator_width1  2
#property indicator_minimum   0
#property indicator_maximum 100
 
//
//
//
//
//

extern string TimeFrame      = "current time frame";
extern int    MacdFastPeriod =  12;
extern int    MacdSlowPeriod =  26;
extern int    MacdPrice      =  PRICE_CLOSE;
extern int    RsiPeriod      =  14;
extern int    LookBack       =  60;
extern double Percent        =  95; 
extern double OBLevel        =  90;
extern double OSLevel        =  10;
extern bool   Interpolate    = true;

//
//
//
//
//
//

double Rsi[];
double upBuffer[];
double miBuffer[];
double dnBuffer[];
double macd[];

//
//
//
//
//

int    timeFrame;
string IndicatorFileName;
bool   CalculatingRsi;
bool   ReturningBars;

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------

int init()
{
   IndicatorBuffers(5);
      SetIndexBuffer(0,Rsi);  SetIndexLabel(0,"RSi of MACD");
      SetIndexBuffer(1,upBuffer);
      SetIndexBuffer(2,miBuffer);
      SetIndexBuffer(3,dnBuffer);
      SetIndexBuffer(4,macd);
      
      //
      //
      //
      //
      //
         
         IndicatorFileName = WindowExpertName();
         CalculatingRsi    = (TimeFrame=="calculateRsi"); if (ReturningBars)  return(0);
         ReturningBars     = (TimeFrame=="returnBars");   if (ReturningBars)  return(0);
         timeFrame         = stringToTimeFrame(TimeFrame);
      
      //
      //
      //
      //
      //
         
   string shortName = "Dynamic zone ab RSI of MACD "+timeFrameToString(timeFrame)+" ("+MacdFastPeriod+","+MacdSlowPeriod+","+RsiPeriod+")";
   IndicatorShortName(shortName);
   return(0);
}

//
//
//
//
//

int deinit()
{
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

int start()
{
   int counted_bars=IndicatorCounted();
   int i,limit;

   if(counted_bars < 0)   return(-1);
   if(counted_bars > 0)   counted_bars--;
           limit = MathMin(Bars-counted_bars,Bars-1);
           if (ReturningBars)  { Rsi[0] = limit+1; return(0); }

   //
   //
   //
   //
   //

   if (CalculatingRsi || timeFrame==Period())
   {  
      for(i=limit; i>=0; i--)
      {
         macd[i]  = iMACD(NULL,0,MacdFastPeriod,MacdSlowPeriod,1,MacdPrice,MODE_MAIN,i);
         double macdU = 0;
         double macdD = 0;
            if (macd[i]>macd[i+1]) macdU = macd[i]-macd[i+1];
            if (macd[i]<macd[i+1]) macdD = macd[i+1]-macd[i];

         //
         //
         //
         //
         //
         
         double up = Wilders(macdU,0,RsiPeriod,i);
         double dn = Wilders(macdD,2,RsiPeriod,i);
            if ((up+dn)!=0) 
                  Rsi[i] = 100.0*up/(dn+up);
            else  Rsi[i] =  50.0;             
      
         //
         //
         //
         //
         //
         
         double max = Rsi[ArrayMaximum(Rsi,LookBack,i)];
         double min = Rsi[ArrayMinimum(Rsi,LookBack,i)];
         double rng = (max-min)*Percent/100.0;
            upBuffer[i] = min+rng;
            dnBuffer[i] = max-rng;

         //
         //
         //
         //
         //
         
         miBuffer[i] = (max+min)/2.0;
            if (Rsi[i]>OBLevel) miBuffer[i] = 100;
            if (Rsi[i]<OSLevel) miBuffer[i] =   0;
      }
      
      //
      //
      //
      //
      //
      
      return(0);
   }

   //
   //
   //
   //
   //
   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,IndicatorFileName,"returnBars",0,0)*timeFrame/Period()));
   for(i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         Rsi[i] = iCustom(NULL,timeFrame,IndicatorFileName,"calculateRsi",MacdFastPeriod,MacdSlowPeriod,MacdPrice,RsiPeriod,LookBack,Percent,0,y);
         Rsi[i]      = iCustom(NULL,timeFrame,IndicatorFileName,"calculateRsi",MacdFastPeriod,MacdSlowPeriod,MacdPrice,RsiPeriod,LookBack,Percent,0,y);
         upBuffer[i] = iCustom(NULL,timeFrame,IndicatorFileName,"calculateRsi",MacdFastPeriod,MacdSlowPeriod,MacdPrice,RsiPeriod,LookBack,Percent,1,y);
         miBuffer[i] = iCustom(NULL,timeFrame,IndicatorFileName,"calculateRsi",MacdFastPeriod,MacdSlowPeriod,MacdPrice,RsiPeriod,LookBack,Percent,2,y);
         dnBuffer[i] = iCustom(NULL,timeFrame,IndicatorFileName,"calculateRsi",MacdFastPeriod,MacdSlowPeriod,MacdPrice,RsiPeriod,LookBack,Percent,3,y);
      
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
            {
               Rsi[i+k]      = k*factor*Rsi[i+n]      + (1.0-k*factor)*Rsi[i];
               upBuffer[i+k] = k*factor*upBuffer[i+n] + (1.0-k*factor)*upBuffer[i];
               miBuffer[i+k] = k*factor*miBuffer[i+n] + (1.0-k*factor)*miBuffer[i];
               dnBuffer[i+k] = k*factor*dnBuffer[i+n] + (1.0-k*factor)*dnBuffer[i];
            }
   }      
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

double arrayWilders[][4];
double Wilders(double price,int forArray,int period, int i)
{
   if (ArrayRange(arrayWilders,0) != Bars) ArrayResize(arrayWilders,Bars);
   
      int r = Bars-i-1;
         if(r < period) arrayWilders[r][forArray] = Sma(price,forArray+1,period,r);
         else           arrayWilders[r][forArray] = arrayWilders[r-1][forArray] + (price-arrayWilders[r-1][forArray])/period; 
      return(arrayWilders[r][forArray]);
}

//
//
//
//
//

double Sma(double price, int forArray,int period, int r)
{
   double sum = price; arrayWilders[r][forArray] = price;
      for (int k=1; k<period && (r-k)>=0; k++) sum += arrayWilders[r-k][forArray];
   return(sum/k);
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