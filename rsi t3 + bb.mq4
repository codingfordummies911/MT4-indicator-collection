//------------------------------------------------------------------
#property copyright "www.forex-station.com" 
#property link      "www.forex-station.com" 
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1  LimeGreen
#property indicator_color2  Orange
#property indicator_color3  LimeGreen
#property indicator_color4  Red
#property indicator_width3  2
#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DOT

//
//
//
//
//

extern string TimeFrame    = "Current time frame";
extern double RsiPeriod    = 25;
extern int    RsiPrice     = PRICE_CLOSE;
extern double Hot          = 0.7;
extern bool   OriginalT3   = false;
extern int    SignalPeriod = 6; 
extern int    SignalMode   = MODE_EMA; 
extern int    BBPeriod     = 20;
extern double BBDeviations = 1;
extern int    BBShift      = 0;
extern bool   Interpolate  = true;

double rsi[];
double bbup[];
double bbdn[];
double sign[];

int      timeFrame;
bool     calculateValue;
bool     returnBars;
string   indicatorFileName;

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
   SetIndexBuffer(0,bbup);
   SetIndexBuffer(1,bbdn);
   SetIndexBuffer(2,rsi);
   SetIndexBuffer(3,sign);

         //
         //
         //
         //
         //
                  
         indicatorFileName = WindowExpertName();
         calculateValue    = (TimeFrame=="CalculateValue"); if (calculateValue) return(0);
         returnBars        = (TimeFrame=="returnBars");     if (returnBars)     return(0);
         timeFrame         = stringToTimeFrame(TimeFrame);
            SetIndexShift(0,BBShift*timeFrame/Period());
            SetIndexShift(1,BBShift*timeFrame/Period());
         
         //
         //
         //
         //
         //

   IndicatorShortName(timeFrameToString(timeFrame)+" rsi t3 ("+DoubleToStr(RsiPeriod,1)+","+DoubleToStr(Hot,2)+")");
   return(0);
}
int deinit() { return(0); }

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
   int count,counted_bars=IndicatorCounted();
      if(counted_bars < 0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { bbup[0] = limit+1; return(0); }

   //
   //
   //
   //
   //
    
   if (calculateValue || timeFrame==Period())
   {
      for(int i = limit; i >= 0; i--) rsi[i] = iRsi(iMA(NULL,0,1,0,MODE_SMA,RsiPrice,i),RsiPeriod,Hot,OriginalT3,i);
      for(    i = limit; i >= 0; i--)
      {
         sign[i] = iMAOnArray(rsi,0,SignalPeriod,0,SignalMode,i);
            double dev = iStdDevOnArray(rsi,0,BBPeriod,0,MODE_SMA,i);
            double avg = iMAOnArray(rsi,0,BBPeriod,0,MODE_SMA,i);
         bbup[i] = avg+dev*BBDeviations;
         bbdn[i] = avg-dev*BBDeviations;
      }
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
         bbup[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,Hot,OriginalT3,SignalPeriod,SignalMode,BBPeriod,BBDeviations,0,y);
         bbdn[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,Hot,OriginalT3,SignalPeriod,SignalMode,BBPeriod,BBDeviations,1,y);
         rsi [i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,Hot,OriginalT3,SignalPeriod,SignalMode,BBPeriod,BBDeviations,2,y);
         sign[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,Hot,OriginalT3,SignalPeriod,SignalMode,BBPeriod,BBDeviations,3,y);

         //
         //
         //
         //
         //
      
         if (!Interpolate || y==iBarShift(NULL,timeFrame,Time[i-1])) continue;
             interpolate(bbup,timeFrame,i);
             interpolate(bbdn,timeFrame,i);
             interpolate(rsi ,timeFrame,i);
             interpolate(sign,timeFrame,i);
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

void interpolate(double& target[], int timeFrame, int i)
{
   int t = iBarShift(NULL,timeFrame,Time[i]); 
      double y0 = target[i];
      double y1 = target[iBarShift(NULL,0,iTime(NULL,timeFrame,t+0))+1];
      double y2 = target[iBarShift(NULL,0,iTime(NULL,timeFrame,t+1))+1];

      //
      //
      //
      //
      //
      
      datetime time = iTime(NULL,timeFrame,t);
         for(int n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;
         for(int k = 1; k < n; k++)
            target[i+k] = target[i] + (target[i+n] - target[i])*k/n;
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workRsi[][1];
#define _price  0

double iRsi(double price, double period, double hot, bool original, int i)
{
   if (ArrayRange(workRsi,0)!=Bars) ArrayResize(workRsi,Bars); workRsi[Bars-i-1][_price] = price;
   
   //
   //
   //
   //
   //
   
   double chng   = workRsi[Bars-i-1][_price]-workRsi[Bars-i-2][_price];
   double change = iT3(        chng ,period,hot,original,i,0);
   double changa = iT3(MathAbs(chng),period,hot,original,i,1);
      if (changa != 0)
            return(MathMin(MathMax(50.0*(change/MathMax(changa,0.0000001)+1.0),0),100));
      else  return(50.0);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workT3[][18];
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
   if (ArrayRange(workT3,0) != Bars)                ArrayResize(workT3,Bars);
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

