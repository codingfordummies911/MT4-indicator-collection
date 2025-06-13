//+------------------------------------------------------------------
//|
//+------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_color3  DeepSkyBlue  
#property indicator_color4  DimGray
#property indicator_color5  PaleVioletRed
#property indicator_color6  DeepSkyBlue
#property indicator_width6  2
#property indicator_style3  STYLE_DOT
#property indicator_style4  STYLE_DOT
#property indicator_style5  STYLE_DOT

//
//
//
//
//

extern string TimeFrame       = "Current time frame";
extern int    RsiPeriod       =  14;
extern int    RsiPrice        =  PRICE_CLOSE;
extern int    RsiMethod       =   0;
extern int    MinMaxPeriod    = 100;
extern double LevelUp         =  80;
extern double LevelDown       =  20;
extern double SmoothPeriod    =   8;
extern double SmoothPhase     =   0;
extern bool   Interpolate     = true;

extern bool   alertsOn        = true;
extern bool   alertsOnCurrent = true;
extern bool   alertsMessage   = true;
extern bool   alertsSound     = true;
extern bool   alertsNotify    = false;
extern bool   alertsEmail     = false;
extern string soundfile       = "alert2.wav";

extern bool   ShowArrows      = true;
extern string arrowsIdentifier= "RSI Arrows1";
extern double arrowsUpperGap  = 0.5;
extern double arrowsLowerGap  = 0.5;
extern color  arrowsUpColor   = LimeGreen;
extern color  arrowsDnColor   = Red;
extern int    arrowsUpCode    = 241;
extern int    arrowsDnCode    = 242;

//
//
//
//
//

double rsiMin[];
double rsiMax[];
double rsiLUp[];
double rsiLMi[];
double rsiLDn[];
double rsi[];
double trend[];

int    timeFrame;
string indicatorFileName;
bool   returnBars;
bool   calculateValue;

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
// 
//
//
//
//

int init()
{
   IndicatorBuffers(7);
   SetIndexBuffer(0,rsiMin); SetIndexStyle(0,DRAW_NONE);
   SetIndexBuffer(1,rsiMax); SetIndexStyle(1,DRAW_NONE);
   SetIndexBuffer(2,rsiLUp);
   SetIndexBuffer(3,rsiLMi);
   SetIndexBuffer(4,rsiLDn);
   SetIndexBuffer(5,rsi);
   SetIndexBuffer(6,trend);

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
   
      IndicatorShortName(timeFrameToString(timeFrame)+" "+getRsiName(RsiMethod)+" ("+RsiPeriod+","+DoubleToStr(LevelDown,2)+","+DoubleToStr(LevelUp,2)+")");
   return(0);
}
int deinit() 
{ 

   if (!calculateValue && ShowArrows) deleteArrows();

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

int start()
{
   int i,limit,counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { rsiMin[0] = limit+1; return(0); }

   //
   //
   //
   //
   //

   if (calculateValue || timeFrame == Period())
   {
      for(i=limit; i>=0; i--) 
      {
         rsi[i]    = iSmooth(iRsi(iMA(NULL,0,1,0,MODE_SMA,RsiPrice,i),RsiPeriod,i,0,RsiMethod),SmoothPeriod,SmoothPhase,i);
         rsiMin[i] = rsi[ArrayMinimum(rsi,MinMaxPeriod,i)];
         rsiMax[i] = rsi[ArrayMaximum(rsi,MinMaxPeriod,i)];
            double range = rsiMax[i]-rsiMin[i];
               rsiLDn[i] = rsiMin[i]+range*LevelDown/100.0;
               rsiLMi[i] = rsiMin[i]+range*0.5;
               rsiLUp[i] = rsiMin[i]+range*LevelUp/100.0;
               trend[i] = 0;
               if (rsi[i]>rsiLUp[i]) trend[i] = 1;
               if (rsi[i]<rsiLDn[i]) trend[i] =-1;  
           manageArrow(i);   
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
   for(i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         rsiMin[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,RsiMethod,MinMaxPeriod,LevelUp,LevelDown,SmoothPeriod,SmoothPhase,false,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundfile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,0,y);
         rsiMax[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,RsiMethod,MinMaxPeriod,LevelUp,LevelDown,SmoothPeriod,SmoothPhase,false,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundfile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,1,y);
         rsiLUp[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,RsiMethod,MinMaxPeriod,LevelUp,LevelDown,SmoothPeriod,SmoothPhase,false,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundfile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,2,y);
         rsiLMi[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,RsiMethod,MinMaxPeriod,LevelUp,LevelDown,SmoothPeriod,SmoothPhase,false,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundfile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,3,y);
         rsiLDn[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,RsiMethod,MinMaxPeriod,LevelUp,LevelDown,SmoothPeriod,SmoothPhase,false,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundfile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,4,y);
         rsi   [i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,RsiMethod,MinMaxPeriod,LevelUp,LevelDown,SmoothPeriod,SmoothPhase,false,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundfile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,5,y);
            
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
               rsiMin[i+k] = rsiMin[i] + (rsiMin[i+n] - rsiMin[i])*k/n;
               rsiMax[i+k] = rsiMax[i] + (rsiMax[i+n] - rsiMax[i])*k/n;
               rsiLUp[i+k] = rsiLUp[i] + (rsiLUp[i+n] - rsiLUp[i])*k/n;
               rsiLMi[i+k] = rsiLMi[i] + (rsiLMi[i+n] - rsiLMi[i])*k/n;
               rsiLDn[i+k] = rsiLDn[i] + (rsiLDn[i+n] - rsiLDn[i])*k/n;
               rsi[i+k]    = rsi[i]    + (rsi[i+n]    - rsi[i]   )*k/n;
            }
   }
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

string rsiMethodNames[] = {"rsi","empasized","rsx","Ehlers rsi","Cuttler RSI"};
string getRsiName(int& method)
{
   int max = ArraySize(rsiMethodNames)-1;
      method=MathMax(MathMin(method,max),0); return(rsiMethodNames[method]);
}

//
//
//
//
//

double workRsi[][13];
#define _price  0
#define _change 1
#define _changa 2

double iRsi(double price, double period, int i, int instanceNo=0, int rsiMode=0)
{
   if (ArrayRange(workRsi,0)!=Bars) ArrayResize(workRsi,Bars);
      int z = instanceNo*13; 
      int r = Bars-i-1;
   
   //
   //
   //
   //
   //
   
   workRsi[r][z+_price] = price;
   switch (rsiMode)
   {
      case 0:
         double alpha = 1.0/period; 
         if (r<period)
            {
               int k; double sum = 0; for (k=0; k<period && (r-k-1)>=0; k++) sum += MathAbs(workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price]);
                  workRsi[r][z+_change] = (workRsi[r][z+_price]-workRsi[0][z+_price])/MathMax(k,1);
                  workRsi[r][z+_changa] =                                         sum/MathMax(k,1);
            }
         else
            {
               double change = workRsi[r][z+_price]-workRsi[r-1][z+_price];
                               workRsi[r][z+_change] = workRsi[r-1][z+_change] + alpha*(        change  - workRsi[r-1][z+_change]);
                               workRsi[r][z+_changa] = workRsi[r-1][z+_changa] + alpha*(MathAbs(change) - workRsi[r-1][z+_changa]);
            }
         if (workRsi[r][z+_changa] != 0)
               return(50.0*(workRsi[r][z+_change]/workRsi[r][z+_changa]+1));
         else  return(50.0);
         
      //
      //
      //
      //
      //
      
      case 1:
         workRsi[r][z+1] = iSmma(0.5*(MathAbs(workRsi[r][z+_price]-workRsi[r-1][z+_price])+(workRsi[r][z+_price]-workRsi[r-1][z+_price])),0.5*(period-1),Bars-i-1,1);
         workRsi[r][z+2] = iSmma(0.5*(MathAbs(workRsi[r][z+_price]-workRsi[r-1][z+_price])-(workRsi[r][z+_price]-workRsi[r-1][z+_price])),0.5*(period-1),Bars-i-1,2);
         if((workRsi[r][z+1] + workRsi[r][z+2]) != 0) 
               return(100.0 * workRsi[r][z+1]/(workRsi[r][z+1] + workRsi[r][z+2]));
         else  return(50);

      //
      //
      //
      //
      //

      case 2 :     
         double Kg = (3.0)/(2.0+period), Hg = 1.0-Kg;
            if (r<period) { for (k=1; k<13; k++) workRsi[r][k+z] = 0; return(50); }  

            //
            //
            //
            //
            //
      
            double mom = workRsi[r][_price+z]-workRsi[r-1][_price+z];
            double moa = MathAbs(mom);
            for (k=0; k<3; k++)
            {
               int kk = k*2;
               workRsi[r][z+kk+1] = Kg*mom                + Hg*workRsi[r-1][z+kk+1];
               workRsi[r][z+kk+2] = Kg*workRsi[r][z+kk+1] + Hg*workRsi[r-1][z+kk+2]; mom = 1.5*workRsi[r][z+kk+1] - 0.5 * workRsi[r][z+kk+2];
               workRsi[r][z+kk+7] = Kg*moa                + Hg*workRsi[r-1][z+kk+7];
               workRsi[r][z+kk+8] = Kg*workRsi[r][z+kk+7] + Hg*workRsi[r-1][z+kk+8]; moa = 1.5*workRsi[r][z+kk+7] - 0.5 * workRsi[r][z+kk+8];
            }
            if (moa != 0)
                 return(MathMax(MathMin((mom/moa+1.0)*50.0,100.00),0.00)); 
            else return(50);
            
      //
      //
      //
      //
      //
      
      case 3 :
      
         double changeu = 0;
         double changed = 0;
         for (k=0; k<period; k++)
            {
               double diff = workRsi[r-k][_price+z]-workRsi[r-k-1][_price+z];
                  if (diff > 0)
                        changeu += diff;
                  else  changed -= diff;
            }
         if ((changeu+changed)!=0)
               return(50.0*((changeu-changed)/(changeu+changed)+1.0));
         else  return(50.0);

      //
      //
      //
      //
      //
      
      case 4 :
         double sump = 0;
         double sumn = 0;
            for (k=0; k<period; k++)
            {
               diff = workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price];
                  if (diff > 0) sump += diff;
                  if (diff < 0) sumn -= diff;
            }
            if (sumn > 0)
                  return(100.0-100.0/(1.0+sump/sumn));
            else  return(50);
               
   } 
   return(50);
}

//
//
//
//
//
//

double workSmma[][6];
double iSmma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= Bars) ArrayResize(workSmma,Bars);

   //
   //
   //
   //
   //

   if (r<period)
         workSmma[r][instanceNo] = price;
   else  workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}


//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

double wrk[][10];

#define bsmax  5
#define bsmin  6
#define volty  7
#define vsum   8
#define avolty 9

//
//
//
//
//

double iSmooth(double price, double length, double phase, int i, int s=0)
{
   if (length <=1) return(price);
   if (ArrayRange(wrk,0) != Bars) ArrayResize(wrk,Bars); s*= 10;
   
   int r = Bars-i-1; 
      if (r==0) { for(int k=0; k<7; k++) wrk[r][k+s]=price; for(; k<10; k++) wrk[r][k+s]=0; return(price); }

   //
   //
   //
   //
   //
   
      double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = MathMax(len1-2.0,0.5);
      double del1   = price - wrk[r-1][bsmax+s];
      double del2   = price - wrk[r-1][bsmin+s];
      double div    = 1.0/(10.0+10.0*(MathMin(MathMax(length-10,0),100))/100);
      int    forBar = MathMin(r,10);
	
         wrk[r][volty+s] = 0;
               if(MathAbs(del1) > MathAbs(del2)) wrk[r][volty+s] = MathAbs(del1); 
               if(MathAbs(del1) < MathAbs(del2)) wrk[r][volty+s] = MathAbs(del2); 
         wrk[r][vsum+s] =	wrk[r-1][vsum+s] + (wrk[r][volty+s]-wrk[r-forBar][volty+s])*div;
         
         //
         //
         //
         //
         //
   
         wrk[r][avolty+s] = wrk[r-1][avolty+s]+(2.0/(MathMax(4.0*length,30)+1.0))*(wrk[r][vsum+s]-wrk[r-1][avolty+s]);
            if (wrk[r][avolty+s] > 0)
               double dVolty = wrk[r][volty+s]/wrk[r][avolty+s]; else dVolty = 0;   
	               if (dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
                  if (dVolty < 1)                      dVolty = 1.0;

      //
      //
      //
      //
      //
	        
   	double pow2 = MathPow(dVolty, pow1);
      double len2 = MathSqrt(0.5*(length-1))*len1;
      double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

         if (del1 > 0) wrk[r][bsmax+s] = price; else wrk[r][bsmax+s] = price - Kv*del1;
         if (del2 < 0) wrk[r][bsmin+s] = price; else wrk[r][bsmin+s] = price - Kv*del2;
	
   //
   //
   //
   //
   //
      
      double R     = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

         wrk[r][0+s] = price + alpha*(wrk[r-1][0+s]-price);
         wrk[r][1+s] = (price - wrk[r][0+s])*(1-beta) + beta*wrk[r-1][1+s];
         wrk[r][2+s] = (wrk[r][0+s] + R*wrk[r][1+s]);
         wrk[r][3+s] = (wrk[r][2+s] - wrk[r-1][4+s])*MathPow((1-alpha),2) + MathPow(alpha,2)*wrk[r-1][3+s];
         wrk[r][4+s] = (wrk[r-1][4+s] + wrk[r][3+s]); 

   //
   //
   //
   //
   //

   return(wrk[r][4+s]);
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
         if (trend[whichBar+1] ==  1 && trend[whichBar] != 1) doAlert(whichBar,"sell");
         if (trend[whichBar+1] == -1 && trend[whichBar] !=-1) doAlert(whichBar,"buy");
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

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," - ",timeFrameToString(Period())+" rsi - floating levels ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsNotify)  SendNotification(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," rsi - floating levels "),message);
          if (alertsSound)   PlaySound(soundfile);
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

void manageArrow(int i)
{
   if (ShowArrows)
   {
      deleteArrow(Time[i]);
      if (trend[i]!=trend[i+1])
      {
         if (trend[i+1] ==  1 && trend[i] != 1) drawArrow(i,arrowsDnColor,arrowsDnCode,true);
         if (trend[i+1] == -1 && trend[i] !=-1) drawArrow(i,arrowsUpColor,arrowsUpCode,false);
      }
   }
}               

//
//
//
//
//

void drawArrow(int i,color theColor,int theCode,bool up)
{
   string name = arrowsIdentifier+":"+Time[i];
   double gap  = 3.0*iATR(NULL,0,20,i)/4.0;   
   
      //
      //
      //
      //
      //
      
      ObjectCreate(name,OBJ_ARROW,0,Time[i],0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsUpperGap * gap);
         else  ObjectSet(name,OBJPROP_PRICE1, Low[i] - arrowsLowerGap * gap);
}

//
//
//
//
//

void deleteArrows()
{
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
   }
}
void deleteArrow(datetime time)
{
   string lookFor = arrowsIdentifier+":"+time; ObjectDelete(lookFor);
}




