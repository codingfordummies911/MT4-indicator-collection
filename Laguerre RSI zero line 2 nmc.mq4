//+------------------------------------------------------------------+
//|                                           LaGuerre RSI v1.00.mq4 |
//|LaGuerre RSI v1.01 smz mtf                                 mladen |
//+------------------------------------------------------------------+
//mod
#property copyright "mladen"
#property link      ""

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Green
#property indicator_color2 Lime
#property indicator_color3 OrangeRed
#property indicator_width1 2

//
//
// Alternative: Gama = 0.55,levels 0.75,0.45,0.15
//
//

extern double Gama          = 0.70;
extern int    PriceType     = 0;
extern int    Smooth        = 0;           // smz: 1...3; if>3 smz=3
extern bool   SmoothPrice   = false;
extern bool   ShowAsZeroLevel = true;
extern double Level1        = 0.85;
extern double Level2        = 0.50;
extern double Level3        = 0.15;
extern string timeFrame     = "Current time frame";
extern bool   ShowLevels    = false; 
extern bool   ShowLevelSig  = true; 
extern bool   ShowCrossings = true; 
extern bool   alertsOn      = false;
extern bool   alertsMessage = true;
extern bool   alertsSound   = false;
extern bool   alertsEmail   = false;
extern color  LevelsColor   = C'30,33,36';
extern string UniqueID      = "Laguerre RSI";

//
//
//
//
//

double MainBuffer[];
double CUpBuffer[];
double CDnBuffer[];
double L0[];
double L1[];
double L2[];
double L3[];
double L4[];
string ShortName;
string IndicatorName;
int    TimeFrame;
double modifier=0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int init()
{
   IndicatorBuffers(8);
   SetIndexBuffer(0, MainBuffer);
   SetIndexBuffer(1, CUpBuffer);
   SetIndexBuffer(2, CDnBuffer);
   SetIndexBuffer(3, L0);
   SetIndexBuffer(4, L1);
   SetIndexBuffer(5, L2);
   SetIndexBuffer(6, L3);
   SetIndexBuffer(7, L4);

   //
   //
   //
   //
   //
   
   if (ShowCrossings||ShowLevelSig)
      {
         SetIndexStyle(1,DRAW_ARROW);         
         SetIndexStyle(2,DRAW_ARROW);         
         SetIndexArrow(1,159);
         SetIndexArrow(2,159);
      }
   else
      {
         SetIndexStyle(1,DRAW_NONE);
         SetIndexStyle(2,DRAW_NONE);
      }      

   //
   //
   //
   //
   //

   if (ShowAsZeroLevel) modifier = 0.5;
   IndicatorName     = WindowExpertName();
   TimeFrame         = stringToTimeFrame(timeFrame);
   string shortName  = UniqueID;
   if (TimeFrame != Period()) shortName=shortName+TimeFrameToString(TimeFrame);
   IndicatorShortName(ShortName);
   SetIndexLabel(0,"Laguerre RSI");
   return(0);
}

int deinit()
{
   DeleteBounds();
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int start()
{
   int    counted_bars=IndicatorCounted();
   int    i,y,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = Bars - counted_bars;

   //
   //
   //
   //
   //
   
   if (TimeFrame != Period())
   {
      datetime TimeArray[];
         limit = MathMax(limit,TimeFrame/Period());
         ArrayCopySeries(TimeArray ,MODE_TIME ,NULL,TimeFrame);
         
         //
         //
         //
         //
         //
         
         for(i=0,y=0; i<limit; i++)
         {
            if(Time[i]<TimeArray[y]) y++;
               MainBuffer[i] = iCustom(NULL,TimeFrame,IndicatorName,Gama,PriceType,Smooth,SmoothPrice,ShowAsZeroLevel,0,y);
         }
   }
   
   //
   //
   //
   //
   //
   
   if (TimeFrame == Period())
   for(i = limit; i >= 0 ; i--) MainBuffer[i] = LaGuerre(Gama,i,PriceType);
   for(i = limit; i >= 0 ; i--)
   {
      CUpBuffer[i]  = EMPTY_VALUE;
      CDnBuffer[i]  = EMPTY_VALUE;
 
      if (ShowCrossings) 
            {

            if (MainBuffer[i] > (Level1-modifier) && MainBuffer[i+1] < (Level1-modifier)) CUpBuffer[i] = Level1-modifier;
            if (MainBuffer[i] < (Level1-modifier) && MainBuffer[i+1] > (Level1-modifier)) CDnBuffer[i] = Level1-modifier;
            if (MainBuffer[i] > (Level3-modifier) && MainBuffer[i+1] < (Level3-modifier)) CUpBuffer[i] = Level3-modifier;
            if (MainBuffer[i] < (Level3-modifier) && MainBuffer[i+1] > (Level3-modifier)) CDnBuffer[i] = Level3-modifier;
            }
   
      if (ShowLevelSig)
            { 
      
            if (MainBuffer[i] > (Level1-modifier) ) CUpBuffer[i] = Level1-modifier;
            if (MainBuffer[i] < (Level3-modifier) ) CDnBuffer[i] = Level3-modifier;
            }
 
   
   }            
   
   //
   //
   //
   //
   //

   if (ShowLevels) UpdateBounds();
   if (alertsOn) CheckCrossings();
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

double LaGuerre(double gamma, int i, int priceType)
{
	double Price = iMA(NULL,0,1,0,MODE_SMA,priceType,i);
	double RSI   = 0.00;
	double CU    = 0.00;
	double CD    = 0.00;


   if (SmoothPrice) Price = iTma(Price,Smooth,i);
   L0[i] = (1.0 - gamma)*Price + gamma*L0[i+1];
	L1[i] = -gamma*L0[i] + L0[i+1]     + gamma*L1[i+1];
	L2[i] = -gamma*L1[i] + L1[i+1]     + gamma*L2[i+1];
	L3[i] = -gamma*L2[i] + L2[i+1]     + gamma*L3[i+1];

   //
   //
   //
   //
   //
   
	if (L0[i] >= L1[i])
   			CU = L0[i] - L1[i];
	else	   CD = L1[i] - L0[i];
	if (L1[i] >= L2[i])
   			CU = CU + L1[i] - L2[i];
	else	   CD = CD + L2[i] - L1[i];
	if (L2[i] >= L3[i])
			   CU = CU + L2[i] - L3[i];
	else	   CD = CD + L3[i] - L2[i];

   //
   //
   //
   //
   //

   if (CU + CD != 0) RSI = CU / (CU + CD) ;
                     if (!SmoothPrice) RSI = iTma(RSI,Smooth,i);
   return(RSI-modifier);
}

//
//
//
//
//


double workTma[][1];
double iTma(double price, double period, int r, int instanceNo=0)
{
   if (period<2) return(price);
   if (ArrayRange(workTma,0)!= Bars) ArrayResize(workTma,Bars); r = Bars-r-1;
   
   //
   //
   //
   //
   //
   
   workTma[r][instanceNo] = price;

      double half = (period+1.0)/2.0;
      double sum  = price;
      double sumw = 1;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = k+1; if (weight > half) weight = period-k;
                sumw  += weight;
                sum   += weight*workTma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

void CheckCrossings()
{
   if (CUpBuffer[0] == (Level1-modifier)) doAlert("level "+DoubleToStr(Level1-modifier,2)+" crossed up");
   if (CDnBuffer[0] == (Level1-modifier)) doAlert("level "+DoubleToStr(Level1-modifier,2)+" crossed down");
   if (CUpBuffer[0] == (Level3-modifier)) doAlert("level "+DoubleToStr(Level3-modifier,2)+" crossed up");
   if (CDnBuffer[0] == (Level3-modifier)) doAlert("level "+DoubleToStr(Level3-modifier,2)+" crossed down");
}

//
//
//
//
//

void doAlert(string doWhat)
{
   static string   previousAlert="";
   static datetime previousTime;
   string message;
   
      if (previousAlert != doWhat || previousTime != Time[0]) {
          previousAlert  = doWhat;
          previousTime   = Time[0];

          //
          //
          //
          //
          //

          message =  StringConcatenate(Symbol()," TF",TimeFrame," in M",Period()," chart at ",TimeToStr(TimeLocal(),TIME_SECONDS),":\n Laguerre ",doWhat);
             if (alertsMessage) Alert(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol()," Laguerre line crossing"),message);
             if (alertsSound)   PlaySound("alert2.wav");
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

void DeleteBounds()
{
   ObjectDelete(ShortName+"-1");
   ObjectDelete(ShortName+"-2");
   ObjectDelete(ShortName+"-3");
}
void UpdateBounds()
{
   if (Level1 > 0) SetUpBound(ShortName+"-1",1.0000-modifier       ,(Level1-modifier));
   if (Level2 > 0) SetUpBound(ShortName+"-2",(Level2-modifier)*1.01,(Level2-modifier)*0.99);
   if (Level3 > 0) SetUpBound(ShortName+"-3",(Level3-modifier)     ,       -modifier);
}
void SetUpBound(string name, double up, double down,int objType=OBJ_RECTANGLE)
{
   if (ObjectFind(name) == -1)
      {
         ObjectCreate(name,objType,WindowFind(ShortName),0,0);
         ObjectSet(name,OBJPROP_PRICE1,up);
         ObjectSet(name,OBJPROP_PRICE2,down);
         ObjectSet(name,OBJPROP_COLOR,LevelsColor);
         ObjectSet(name,OBJPROP_BACK,true);
         ObjectSet(name,OBJPROP_TIME1,iTime(NULL,0,Bars-1));
      }
   if (ObjectGet(name,OBJPROP_TIME2) != iTime(NULL,0,0))
       ObjectSet(name,OBJPROP_TIME2,    iTime(NULL,0,0));
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   int tf=0;
       tfs = StringUpperCase(tfs);
         if (tfs=="M1" || tfs=="1")     tf=PERIOD_M1;
         if (tfs=="M5" || tfs=="5")     tf=PERIOD_M5;
         if (tfs=="M15"|| tfs=="15")    tf=PERIOD_M15;
         if (tfs=="M30"|| tfs=="30")    tf=PERIOD_M30;
         if (tfs=="H1" || tfs=="60")    tf=PERIOD_H1;
         if (tfs=="H4" || tfs=="240")   tf=PERIOD_H4;
         if (tfs=="D1" || tfs=="1440")  tf=PERIOD_D1;
         if (tfs=="W1" || tfs=="10080") tf=PERIOD_W1;
         if (tfs=="MN" || tfs=="43200") tf=PERIOD_MN1;
         if (tf<Period()) tf=Period();
  return(tf);
}
string TimeFrameToString(int tf)
{
   string tfs="Current time frame";
   switch(tf) {
      case PERIOD_M1:  tfs="M1 "  ; break;
      case PERIOD_M5:  tfs="M5 "  ; break;
      case PERIOD_M15: tfs="M15 " ; break;
      case PERIOD_M30: tfs="M30 " ; break;
      case PERIOD_H1:  tfs="H1 "  ; break;
      case PERIOD_H4:  tfs="H4 "  ; break;
      case PERIOD_D1:  tfs="D1 "  ; break;
      case PERIOD_W1:  tfs="W1 "  ; break;
      case PERIOD_MN1: tfs="MN ";
   }
   return(tfs);
}

//
//
//
//
//

string StringUpperCase(string str)
{
   string   s = str;
   int      lenght = StringLen(str) - 1;
   int      tchar;
   
   while(lenght >= 0)
      {
         tchar = StringGetChar(s, lenght);
         
         //
         //
         //
         //
         //
         
         if((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
                  s = StringSetChar(s, lenght, tchar - 32);
         else 
              if(tchar > -33 && tchar < 0)
                  s = StringSetChar(s, lenght, tchar + 224);
         lenght--;
   }
   
   //
   //
   //
   //
   //
   
   return(s);
}