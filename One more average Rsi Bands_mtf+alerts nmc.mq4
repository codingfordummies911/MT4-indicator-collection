//------------------------------------------------------------------
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"
//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers    6
#property indicator_color1     Yellow
#property indicator_color2     Aqua
#property indicator_color3     Aqua
#property indicator_color4     Lime
#property indicator_color5     Red
#property indicator_color6     Red
#property indicator_width1     3
#property indicator_minimum    0
#property indicator_maximum    100
#property indicator_levelcolor DarkSlateGray


//
//
//
//
//

extern string TimeFrame       = "current time frame";
extern int    RsiPrice        = 0;
extern double RsiPeriod       = 34;
extern double OmaSpeed        = 2.0;
extern bool   OmaAdaptive     = true;
extern int    MaPeriod        = 34;
extern int    MaMethod        = 3;
extern int    koridor         = 5;
extern bool   Interpolate     = true;

extern bool   drawDots        = true;   
extern double levelOs         = 20;
extern double levelOb         = 80;

extern string note            = "turn on Alert = true; turn off = false";
extern bool   alertsOn        = true;
extern bool   alertsOnCurrent = true;
extern bool   alertsMessage   = true;
extern bool   alertsSound     = true;
extern bool   alertsNotify    = false;
extern bool   alertsEmail     = false;
extern string soundfile       = "alert2.wav";

//
//
//
//
//

double rsi[];
double upBand[];
double dnBand[];
double rsiMaDa[];
double rsiMaDb[];
double rsiMa[];
double trend[];

//
//
//
//
//

int    timeFrame;
string indicatorFileName;
bool   returnBars;
bool   calculateValue;

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
   IndicatorBuffers(7);
   SetIndexBuffer(0,rsi); 
   SetIndexBuffer(1,upBand);
   SetIndexBuffer(2,dnBand); 
   SetIndexBuffer(3,rsiMa);    
   SetIndexBuffer(4,rsiMaDa);
   SetIndexBuffer(5,rsiMaDb);  
   SetIndexBuffer(6,trend);
   SetLevelValue(0,levelOs); 
   SetLevelValue(1,levelOb);
   
   if (drawDots) 
   {
     SetIndexStyle(3, DRAW_ARROW,0); SetIndexArrow(3, 110);
     SetIndexStyle(4, DRAW_ARROW,0); SetIndexArrow(4, 110);
     SetIndexStyle(5, DRAW_NONE);
   }
   else
   {
     SetIndexStyle(3, DRAW_LINE);
     SetIndexStyle(4, DRAW_LINE);
     SetIndexStyle(5, DRAW_LINE);
   }        
            
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
      
   IndicatorShortName(timeFrameToString(timeFrame)+ " OMA Rsi Bands ("+DoubleToStr(RsiPeriod,2)+","+MaPeriod+")");
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
         limit = MathMin(Bars - counted_bars,Bars-1);
         if (returnBars) { rsi[0] = limit+1; return(0); }

   //
   //
   //
   //
   //
   
   if (calculateValue || timeFrame==Period())
   {
     if (!drawDots) if (trend[limit] == -1) ClearPoint(limit,rsiMaDa,rsiMaDb);
     for (i=limit; i>=0; i--) rsi[i] = iRsi(getPrice(RsiPrice,i),RsiPeriod,OmaSpeed,OmaAdaptive,i);
     for (i=limit; i>=0; i--) 
     {
        rsiMa[i]  = iMAOnArray(rsi,0,MaPeriod,0,MaMethod,i);
        upBand[i] = rsiMa[i]+koridor;
        dnBand[i] = rsiMa[i]-koridor;
        rsiMaDa[i] = EMPTY_VALUE;
        rsiMaDb[i] = EMPTY_VALUE;
        trend[i]   = trend[i+1];
           if (rsi[i]>rsiMa[i]) trend[i]= 1;
           if (rsi[i]<rsiMa[i]) trend[i]=-1;
           if (trend[i]==-1) if    (drawDots) rsiMaDa[i] = rsiMa[i];
                             else  PlotPoint(i,rsiMaDa,rsiMaDb,rsiMa);
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
   if (trend[limit]==-1) ClearPoint(limit,rsiMaDa,rsiMaDb);
   for(i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         rsi[i]     = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,koridor,0,y);
         upBand[i]  = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,koridor,1,y);
         dnBand[i]  = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,koridor,2,y);
         rsiMa[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,koridor,3,y);
         rsiMaDa[i] = EMPTY_VALUE;
         rsiMaDb[i] = EMPTY_VALUE;
         trend[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPrice,RsiPeriod,OmaSpeed,OmaAdaptive,MaPeriod,MaMethod,koridor,6,y);
         
         if (drawDots && trend[i]==-1) rsiMaDa[i] = rsiMa[i]; 
         
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
            {
               rsi[i+k]    = rsi[i]    + (rsi[i+n]    - rsi[i])   * k/n;
               upBand[i+k] = upBand[i] + (upBand[i+n] - upBand[i])* k/n;
               dnBand[i+k] = dnBand[i] + (dnBand[i+n] - dnBand[i])* k/n;
               rsiMa[i+k]  = rsiMa[i]  + (rsiMa[i+n]  - rsiMa[i]) * k/n;
               if (rsiMaDa[i+k] != EMPTY_VALUE) rsiMaDa[i+k] = rsiMa[i+k];
           }               
   }
   if (!drawDots) for(i=limit; i>=0; i--) if (trend[i]== -1) PlotPoint(i,rsiMaDa,rsiMaDb,rsiMa);
   manageAlerts(); 
return(0);
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

double getPrice(int type, int i)
{
   switch (type)
   {
      case 7:     return((Open[i]+Close[i])/2.0);
      case 8:     return((Open[i]+High[i]+Low[i]+Close[i])/4.0);
      default :   return(iMA(NULL,0,1,0,MODE_SMA,type,i));
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
//

double workRsi[][3];
#define _price  0
#define _change 1
#define _changa 2

double iRsi(double price, double period, double speed, bool adaptive, int i, int instanceNo=0)
{
   if (ArrayRange(workRsi,0)!=Bars) ArrayResize(workRsi,Bars);
      int z = instanceNo*3; 
      int r = Bars-i-1;
   
   //
   //
   //
   //
   //
   
   workRsi[r][z+_price] = price;
         double chng   = workRsi[r][_price]-workRsi[r-1][_price];
         double changn = iOma(        chng ,period,speed,adaptive,i,instanceNo*2+0);
         double changa = iOma(MathAbs(chng),period,speed,adaptive,i,instanceNo*2+1);
            if (changn != 0)
                  return(MathMin(MathMax(50.0*(changn/MathMax(changa,0.0000001)+1.0),0),100));
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

double workOma[][14];
#define F01 0
#define F02 1
#define F03 2
#define F04 3
#define F05 4
#define F06 5
#define prc 6

//
//
//
//
//

double iOma(double price, double averagePeriod, double constant, bool adaptive, int r, int s=0)
{
   if (averagePeriod <=1) return(price);
   if (ArrayRange(workOma,0) != Bars) ArrayResize(workOma,Bars); r=Bars-r-1; s *=7;
   if (r<=1) 
   {
      for (int i=0; i<6; i++) workOma[r][i  +s] = 0;
                              workOma[r][prc+s] = price;
                              return(price);
   }      
   double f01=workOma[r-1][F01+s];  double f02=workOma[r-1][F02+s];
   double f03=workOma[r-1][F03+s];  double f04=workOma[r-1][F04+s];
   double f05=workOma[r-1][F05+s];  double f06=workOma[r-1][F06+s];

   //
   //
   //
   //
   //

      if (adaptive && (averagePeriod > 1))
      {
         double minPeriod = MathMin(averagePeriod,r)/2.0;
         double maxPeriod = MathMin(minPeriod*5.0,r);
         int    endPeriod = (int)MathCeil(maxPeriod);
         double signal    = MathAbs((price-workOma[r-endPeriod][prc+s]));
         double noise     = 0.00000000001;

            for(i=1; i<endPeriod; i++) noise=noise+MathAbs(price-workOma[r-i][prc+s]);

         averagePeriod = ((signal/noise)*(maxPeriod-minPeriod))+minPeriod;
      }
      
      //
      //
      //
      //
      //
      
      double Kg = (2.0+constant)/(1.0+constant+averagePeriod);
      double Hg = 1.0-Kg;

      f01 = Kg * price + Hg * f01; f02 = Kg * f01 + Hg * f02; double v01 = 1.5 * f01 - 0.5 * f02;
      f03 = Kg * v01   + Hg * f03; f04 = Kg * f03 + Hg * f04; double v02 = 1.5 * f03 - 0.5 * f04;
      f05 = Kg * v02   + Hg * f05; f06 = Kg * f05 + Hg * f06; double v03 = 1.5 * f05 - 0.5 * f06;

   //
   //
   //
   //
   //

   workOma[r][F01+s] = f01;  workOma[r][F02+s] = f02;
   workOma[r][F03+s] = f03;  workOma[r][F04+s] = f04;
   workOma[r][F05+s] = f05;  workOma[r][F06+s] = f06;
   workOma[r][prc+s] = price;
   return(v03);
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

//
//
//
//
//

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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

void ClearPoint(int i,double& first[],double& second[])
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
          first[i]    = from[i];
          first[i+1]  = from[i+1];
          second[i]   = EMPTY_VALUE;
         }
      else {
          second[i]   = from[i];
          second[i+1] = from[i+1];
          first[i]    = EMPTY_VALUE;
         }
      }
   else
      {
         first[i]   = from[i];
         second[i]  = EMPTY_VALUE;
      }
}

//
//
//
//
//

void manageAlerts()
{
   if (!calculateValue && alertsOn)
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

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," ",timeFrameToString(Period())+" Tarzan trend changed to ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsNotify)  SendNotification(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol(),"Tarzan "),message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}

