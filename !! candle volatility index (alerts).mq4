//+------------------------------------------------------------------+
//|                                      Candle Volatility Index.mq4 |
//|                                         Indicator made by Jas Wu |
//+------------------------------------------------------------------+
#property description      "Candle Volatility Index.mq4"
#property description      "Indicator made by Jas Wu"
#property description      "MA Options add by KHT in telegram group"
#property link      "https://www.mql5.com/en/market/product/52403"
#property copyright "Check out my Ultimate NNFX Backtester here"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 2


//--- Buffers
double Volatility[], Filter[], Base[],valc[];

//--- Main Inputs

extern string Notes = "-----------Main Inputs------------"; //-----------Main Inputs------------

enum maTypes
{
   SMA,                 // Simple Moving Average
   EMA,                 // Exponential Moving Average
   Wilder,              // Wilder Exponential Moving Average
   LWMA,                // Linear Weighted Moving Average
   SineWMA,             // Sine Weighted Moving Average
   TriMA,               // Triangular Moving Average
   LSMA,                // Least Square Moving Average (or EPMA, Linear Regression Line)
   SMMA,                // Smoothed Moving Average
   HMA,                 // Hull Moving Average by A.Hull
   ZeroLagEMA,          // Zero-Lag Exponential Moving Average
   DEMA,                // Double Exponential Moving Average by P.Mulloy
   T3_basic,            // T3 by T.Tillson (original version)
   ITrend,              // Instantaneous Trendline by J.Ehlers
   Median,              // Moving Median
   GeoMean,             // Geometric Mean
   REMA,                // Regularized EMA by C.Satchwell
   ILRS,                // Integral of Linear Regression Slope
   IE_2,                // Combination of LSMA and ILRS
   TriMAgen,            // Triangular Moving Average generalized by J.Ehlers
   VWMA,                // Volume Weighted Moving Average
   JSmooth,             // M.Jurik's Smoothing
   SMA_eq,              // Simplified SMA
   ALMA,                // Arnaud Legoux Moving Average
   TEMA,                // Triple Exponential Moving Average by P.Mulloy
   T3,                  // T3 by T.Tillson (correct version)
   Laguerre,            // Laguerre filter by J.Ehlers
   MD,                  // McGinley Dynamic
   BF2P,                // Two-pole modified Butterworth filter by J.Ehlers
   BF3P,                // Three-pole modified Butterworth filter by J.Ehlers
   SuperSmu,            // SuperSmoother by J.Ehlers
   Decycler,            // Simple Decycler by J.Ehlers
   eVWMA,               // Modified eVWMA
   EWMA,                // Exponential Weighted Moving Average
   DsEMA,               // Double Smoothed EMA
   TsEMA,               // Triple Smoothed EMA
   VEMA                 // Volume-weighted Exponential Moving Average(V-EMA)
};   
extern maTypes MA_Type = SMA; // MA Method
extern int MA_Period = 8; // MA Period
//
//
//
//
extern string Notes2 = "-----------Calculation Used------------"; //-----------Calculation Used------------

enum CalMethod 
{
   OPEN=0, //CANDLE OPEN
   LOW=1, //CANDLE LOW
   HIGH=2, //CANDLE HIGH
   CLOSE=3, //CANDLE CLOSE
   VOLUME=4, //CANDLE VOLUME
   ATRVOLUME=5, //VOLUME DIVIDED BY ATR
   HL=6, //HIGH MINUS LOW
};
extern CalMethod CalculationUsed = CLOSE; //Calculation Method
//
//
//
//
extern string Notes3 = "-----------Filter Settings------------"; //-----------Filter Mode------------
enum Options2 {StandardMA=0, StandardDeviation=1};
extern Options2 FilterMode = StandardMA; // Filter Mode
extern int Volatility_Period = 10; // Filter Period
extern double Stdv_Multiplier = 5.0; //Stdv Multiplier - Applicable Only If Using Stdv Mode

enum FilterMA 
{
   FILTER_SMA=0, //Simple Moving Average
   FILTER_EMA=1, //Exponential Moving Average
   FILTER_SSMA=2, //Smoothed Moving Average
   FILTER_LWMA=3  //Linear Weighted Moving Average
};
extern FilterMA Filter_MA_Type = FILTER_SMA; // Filter MA Method

extern string Notes4 = "-----------FYI Info------------"; //-----------FYI Info------------
extern string Advertise = "https://www.mql5.com/en/market/product/52403"; //Check out my Ultimate NNFX Backtester here
extern string Advertise2 = "https://www.mql5.com/en/market/product/53243"; //Check out my NNFX History News Tool here
extern string Advertise3 = "https://discord.gg/Tug5h7E"; //Disocrd Group for this backtester
extern color HistoCol = Crimson; //Histogram Color
extern color BreakLev = Gold; //Breakout Line Color
input bool            alertsOn         = true;                // Alerts?
input bool            alertsOnCurrent  = false;               // Alerts open bar?
input bool            alertsMessage    = true;                // Alerts message?
input bool            alertsSound      = false;               // Alerts sound?
input bool            alertsNotify     = false;               // Alerts notification?
input bool            alertsEmail      = false;               // Alerts email?
input string          soundFile        = "alert2.wav";        // Alerts sound file

//
//
//
//

//--- Other Values
int MaType = 0;
int calculation = 0;
int barstocursor=0;
string UprDown = " ", ModeName=" ";
int masize;

#define pi 3.14159265358979323846

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
   MaType = MA_Type;
   calculation = CalculationUsed; 
   if(calculation == 0) ModeName = "OPEN"; 
   if(calculation == 1) ModeName = "LOW"; 
   if(calculation == 2) ModeName = "HIGH"; 
   if(calculation == 3) ModeName = "CLOSE";
   if(calculation == 4) ModeName = "VOLUME"; 
   if(calculation == 5) ModeName = "VOLUME/ATR"; 
   if(calculation == 6) ModeName = "HIGH-LOW";   
//--- indicator buffers mapping   
   IndicatorShortName("Candle Volatility Index("+(string)MA_Period+","+EnumToString(MA_Type)+")"+" MODE= "+ModeName);
   IndicatorBuffers(4);
   SetIndexBuffer(0,Volatility); 
   SetIndexLabel(0, "Volatility");
   SetIndexStyle(0,DRAW_HISTOGRAM, STYLE_SOLID, 3, HistoCol);    
     
   SetIndexBuffer(1,Filter); 
   SetIndexLabel(1, "Filter");
   SetIndexStyle(1,DRAW_LINE, STYLE_SOLID, 1, BreakLev);  
   
   SetIndexBuffer(2,Base); 
   SetIndexLabel(2, "Base");
   SetIndexStyle(2,DRAW_NONE); 
   SetIndexBuffer(3,valc);   
         
//--- BackGround Creation
   ObjectCreate("CVI", OBJ_LABEL, ChartWindowFind(0, "Candle Volatility Index("+(string)MA_Period+","+(string)MA_Type+")"+" MODE= "+ModeName), 0, 0, 0, 0);
   ObjectSetText("CVI", "ggggg", 20, "Webdings", clrBlack);   
   ObjectSet("CVI", OBJPROP_CORNER, 0);
   ObjectSet("CVI", OBJPROP_XDISTANCE, 5);
   ObjectSet("CVI", OBJPROP_YDISTANCE, 20);
   ObjectSet("CVI", OBJPROP_BACK, false);  

   masize = averageSize(MA_Type); 
   if(masize > 0) ArrayResize(tmp,masize);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---
   int ExtCountedBars=IndicatorCounted();
   if (ExtCountedBars<0) return(-1);
   int i;
   int limit=Bars-2;
   if(ExtCountedBars>2) limit=Bars-ExtCountedBars-1;
 
   for(i=limit; i>=0; i--)
   {
      Base[i] = EMPTY_VALUE;
      while (true)
      { 
         if(CalculationUsed == CLOSE) {
             Base[i] = MathAbs(Close[i]-Close[i+1]);
             break;
         }
         if(CalculationUsed == OPEN) {
             Base[i] = MathAbs(Open[i]-Open[i+1]);
             break;
         }
         if(CalculationUsed == LOW) {
             Base[i] = MathAbs(Low[i]-Low[i+1]);
             break;
         }
         if(CalculationUsed == HIGH) {
             Base[i] = MathAbs(High[i]-High[i+1]);
             break;
         }
         if(CalculationUsed == VOLUME) {
             Base[i] = (int)MathAbs(Volume[i]-Volume[i+1]);
             break;
         }
         if(CalculationUsed == ATRVOLUME) {
              double PreviousATR = MathAbs(High[i+1]-Low[i+1]);
              double CurrentATR  = MathAbs(High[i]-Low[i]);         
              Base[i] = MathAbs(    (Volume[i]/(CurrentATR/Point/10))  -  (Volume[i+1]/(PreviousATR/Point/10))    );
             break;
         }
         if(CalculationUsed == HL) {
             if(Close[i] > Open[i]) Base[i] = MathAbs(High[i]-Low[i+1]);
             if(Close[i] < Open[i]) Base[i] = MathAbs(Low[i]-High[i+1]);      
             if(Close[i] == Open[i]) Base[i] = Base[i+1]; 
             break;
         }
         Base[i] = MathAbs(Close[i]-Close[i+1]);
         break;
      }
   } 

     
   for(i=limit; i>=0; i--)
   {
      Volatility[i] = EMPTY_VALUE;
      Filter[i] = EMPTY_VALUE;
       
      if(i > Bars-MA_Period-1) continue;
         
      Volatility[i] = allAveragesOnArray(0,Base,MA_Period,(int)MA_Type,masize,Bars-MA_Period-1,i);
      if(Volatility[i]<0) Volatility[i] = 0;
         
      while (true)
      { 
         if(FilterMode == StandardMA) {
             Filter[i] = iMAOnArray(Volatility, 0, Volatility_Period, 0, (int)Filter_MA_Type, i);
             break;
         }
         if(FilterMode == StandardDeviation) {
             Filter[i] = iStdDevOnArray(Volatility, 0, Volatility_Period, 0, (int)Filter_MA_Type, i)*Stdv_Multiplier;
             break;
         }
         Filter[i] = iMAOnArray(Volatility, 0, Volatility_Period, 0, (int)Filter_MA_Type, i);
         break;
      }
      valc[i] = (i<rates_total-1) ? (Volatility[i]>Filter[i]) ? 1 : (Volatility[i]<Filter[i]) ? -1 : valc[i+1] : 0;  
      
   }
   if (alertsOn)
   {
      int whichBar = 1; if (alertsOnCurrent) whichBar = 0;
      if (valc[whichBar] != valc[whichBar+1])
      {
         if (valc[whichBar] == 1) doAlert(whichBar," volatility valid");
         if (valc[whichBar] ==-1) doAlert(whichBar," Volatility low");
      }         
   }
   return(rates_total);
}

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

          message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+" CVI "+doWhat;
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(_Symbol+" CVI ",message);
             if (alertsSound)   PlaySound(soundFile);
      }
}  

 //-------------------------------------------------------------------
//
//-------------------------------------------------------------------

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}
int timeFrameValue(int _tf)
{
   int add  = (_tf>=0) ? 0 : fabs(_tf);
   if (add != 0) _tf = _Period;
   int size = ArraySize(iTfTable); 
      int i =0; for (;i<size; i++) if (iTfTable[i]==_tf) break;
                                   if (i==size) return(_Period);
                                                return(iTfTable[(int)fmin(i+add,size-1)]);
}

       

//
//
//
//
//

int averageSize(int mode)
{   
   int arraysize;
   
   switch(mode)
   {
   case DEMA     : arraysize = 2; break;
   case T3_basic : arraysize = 6; break;
   case JSmooth  : arraysize = 5; break;
   case TEMA     : arraysize = 4; break;
   case T3       : arraysize = 6; break;
   case Laguerre : arraysize = 4; break;
   case DsEMA    : arraysize = 2; break;
   case TsEMA    : arraysize = 3; break;
   case VEMA     : arraysize = 2; break;
   default       : arraysize = 0; break;
   }
   
   return(arraysize);
}

//
//
//
//

double   tmp[][1][2], ma[1][4];
datetime prevtime[1];  

double allAveragesOnArray(int index,double& price[],int period,int mode,int arraysize,int cbars,int bar)
{
   int i;
   double MA[4];  
        
   switch(mode) 
	{
	case EMA: case Wilder: case SMMA: case ZeroLagEMA: case DEMA: case T3_basic: case ITrend: case REMA: case JSmooth: case SMA_eq: case TEMA: case T3: case Laguerre: case MD: 
	case BF2P: case BF3P: case SuperSmu: case Decycler: case eVWMA: case DsEMA: case TsEMA: case VEMA:
		
		if(prevtime[index] != Time[bar])
      {
      ma[index][3] = ma[index][2]; 
      ma[index][2] = ma[index][1]; 
      ma[index][1] = ma[index][0]; 
   
      if(arraysize > 0) for(i=0;i<arraysize;i++) tmp[i][index][1] = tmp[i][index][0];
    
      prevtime[index] = Time[bar]; 
      }
   
      if(mode == ITrend || mode == REMA || mode == SMA_eq || (mode >= BF2P && mode < eVWMA)) for(i=0;i<4;i++) MA[i] = ma[index][i]; 
	}
      
   switch(mode)
   {
   case EMA       : ma[index][0] = EMAOnArray(price[bar],ma[index][1],period,cbars,bar); break;
   case Wilder    : ma[index][0] = WilderOnArray(price[bar],ma[index][1],period,cbars,bar); break;  
   case LWMA      : ma[index][0] = LWMAOnArray(price,period,bar); break;
   case SineWMA   : ma[index][0] = SineWMAOnArray(price,period,bar); break;
   case TriMA     : ma[index][0] = TriMAOnArray(price,period,bar); break;
   case LSMA      : ma[index][0] = LSMAOnArray(price,period,bar); break;
   case SMMA      : ma[index][0] = SMMAOnArray(price,ma[index][1],period,cbars,bar); break;
   case HMA       : ma[index][0] = HMAOnArray(price,period,cbars,bar); break;
   case ZeroLagEMA: ma[index][0] = ZeroLagEMAOnArray(price,ma[index][1],period,cbars,bar); break;
   case DEMA      : ma[index][0] = DEMAOnArray(index,0,price[bar],period,1,cbars,bar); break;
   case T3_basic  : ma[index][0] = T3_basicOnArray(index,0,price[bar],period,0.7,cbars,bar); break;
   case ITrend    : ma[index][0] = ITrendOnArray(price,MA,period,cbars,bar); break;
   case Median    : ma[index][0] = MedianOnArray(price,period,cbars,bar); break;
   case GeoMean   : ma[index][0] = GeoMeanOnArray(price,period,cbars,bar); break;
   case REMA      : ma[index][0] = REMAOnArray(price[bar],MA,period,0.5,cbars,bar); break;
   case ILRS      : ma[index][0] = ILRSOnArray(price,period,cbars,bar); break;
   case IE_2      : ma[index][0] = IE2OnArray(price,period,cbars,bar); break;
   case TriMAgen  : ma[index][0] = TriMA_genOnArray(price,period,cbars,bar); break;
   case VWMA      : ma[index][0] = VWMAOnArray(price,period,bar); break;
   case JSmooth   : ma[index][0] = JSmoothOnArray(index,0,price[bar],period,1,cbars,bar); break;
   case SMA_eq    : ma[index][0] = SMA_eqOnArray(price,MA,period,cbars,bar); break;
   case ALMA      : ma[index][0] = ALMAOnArray(price,period,0.85,8,bar); break;
   case TEMA      : ma[index][0] = TEMAOnArray(index,price[bar],period,1,cbars,bar); break;
   case T3        : ma[index][0] = T3OnArray(index,0,price[bar],period,0.7,cbars,bar); break;
   case Laguerre  : ma[index][0] = LaguerreOnArray(index,price[bar],period,4,cbars,bar); break;
   case MD        : ma[index][0] = McGinleyOnArray(price[bar],ma[index][1],period,cbars,bar); break;
   case BF2P      : ma[index][0] = BF2POnArray(price,MA,period,cbars,bar); break;
   case BF3P      : ma[index][0] = BF3POnArray(price,MA,period,cbars,bar); break;
   case SuperSmu  : ma[index][0] = SuperSmuOnArray(price,MA,period,cbars,bar); break;
   case Decycler  : ma[index][0] = DecyclerOnArray(price,MA,period,cbars,bar); return(price[bar] - ma[index][0]); 
   case eVWMA     : ma[index][0] = eVWMAOnArray(price[bar],ma[index][1],period,cbars,bar); break;
   case EWMA      : ma[index][0] = EWMAOnArray(price,period,bar); break;
   case DsEMA     : ma[index][0] = DsEMAOnArray(index,price[bar],period,cbars,bar); break;
   case TsEMA     : ma[index][0] = TsEMAOnArray(index,price[bar],period,cbars,bar); break;
   case VEMA      : ma[index][0] = VEMAOnArray(index,price[bar],period,cbars,bar); break;
   default        : ma[index][0] = SMAOnArray(price,period,bar); break;
   }
   
   return(ma[index][0]);
}

// MA_Method=SMA - Simple Moving Average
double SMAOnArray(double& array[],int per,int bar)
{
   double sum = 0;
   for(int i=0;i<per;i++) sum += array[bar+i];
   
   return(sum/per);
}                
// MA_Method=EMA - Exponential Moving Average
double EMAOnArray(double price,double prev,int per,int cbars,int bar)
{
   double ema;
   
   if(bar >= cbars) ema = price;
   else 
   ema = prev + 2.0/(1 + per)*(price - prev); 
   
   return(ema);
}
// MA_Method=Wilder - Wilder Exponential Moving Average
double WilderOnArray(double price,double prev,int per,int cbars,int bar)
{
   double wilder;
   
   if(bar >= cbars) wilder = price; 
   else 
   wilder = prev + (price - prev)/per; 
   
   return(wilder);
}

// MA_Method=LWMA - Linear Weighted Moving Average 
double LWMAOnArray(double& array[],int per,int bar)
{
   double sum = 0, weight = 0;
   
      for(int i=0;i<per;i++)
      { 
      weight += (per - i);
      sum    += array[bar+i]*(per - i);
      }
   
   if(weight > 0) return(sum/weight); else return(0); 
} 

// MA_Method=SineWMA - Sine Weighted Moving Average
double SineWMAOnArray(double& array[],int per,int bar)
{
   double sum = 0, weight = 0;
  
      for(int i=0;i<per;i++)
      { 
      weight += MathSin(pi*(i + 1)/(per + 1));
      sum    += array[bar+i]*MathSin(pi*(i + 1)/(per + 1)); 
      }
   
   if(weight > 0) return(sum/weight); else return(0); 
}

// MA_Method=TriMA - Triangular Moving Average
double TriMAOnArray(double& array[],int per,int bar)
{
   int len    = (int)MathCeil((per + 1)*0.5);
   double sum = 0;
   
   for(int i=0;i<len;i++) sum += SMAOnArray(array,len,bar+i);
         
   return(sum/len);
}

// MA_Method=LSMA - Least Square Moving Average (or EPMA, Linear Regression Line)
double LSMAOnArray(double& array[],int per,int bar)
{   
   double sum = 0;
   
   for(int i=per;i>=1;i--) sum += (i - (per + 1)/3.0)*array[bar+per-i];
   
   return(sum*6/(per*(per + 1)));
}

// MA_Method=SMMA - Smoothed Moving Average
double SMMAOnArray(double& array[],double prev,int per,int cbars,int bar)
{
   double smma = 0;
   
   if(bar == cbars) smma = SMAOnArray(array,per,bar);
   else 
   if(bar  < cbars)
   {
   double sum = 0;
   for(int i=0;i<per;i++) sum += array[bar+i+1];
   smma = (sum - prev + array[bar])/per;
   }
   
   return(smma);
}                

// MA_Method=HMA - Hull Moving Average by Alan Hull
double HMAOnArray(double& array[],int per,int cbars,int bar)
{
   double hma = 0, _tmp[];
   int len = (int)MathSqrt(per);
   
   ArrayResize(_tmp,len);
   
   if(bar == cbars) hma = array[bar]; 
   else
   if(bar  < cbars)
   {
   for(int i=0;i<len;i++) _tmp[i] = 2*LWMAOnArray(array,per/2,bar+i) - LWMAOnArray(array,per,bar+i);  
   hma = LWMAOnArray(_tmp,len,0); 
   }  

   return(hma);
}

// MA_Method=ZeroLagEMA - Zero-Lag Exponential Moving Average
double ZeroLagEMAOnArray(double& price[],double prev,int per,int cbars,int bar)
{
   int lag = (int)(0.5*(per - 1)); 
   double zema, alpha = 2.0/(1 + (double)per); 
      
   if(bar >= cbars) zema = price[bar];
   else 
   zema = alpha*(2*price[bar] - price[bar+lag]) + (1 - alpha)*prev;
   
   return(zema);
}

// MA_Method=DEMA - Double Exponential Moving Average by Patrick Mulloy
double DEMAOnArray(int index,int num,double price,double per,double v,int cbars,int bar)
{
   double dema = 0, alpha = 2.0/(1 + per);
   
   if(bar == cbars) {dema = price; tmp[num][index][0] = dema; tmp[num+1][index][0] = dema;}
   else 
   if(bar <  cbars) 
   {
   tmp[num  ][index][0] = tmp[num  ][index][1] + alpha*(price              - tmp[num  ][index][1]); 
   tmp[num+1][index][0] = tmp[num+1][index][1] + alpha*(tmp[num][index][0] - tmp[num+1][index][1]); 
   dema                 = tmp[num  ][index][0]*(1+v) - tmp[num+1][index][0]*v;
   }
   
   return(dema);
}

// MA_Method=T3 by T.Tillson
double T3_basicOnArray(int index,int num,double price,int per,double v,int cbars,int bar)
{
   double dema1, dema2, T3 = 0;
   
   if(bar == cbars) 
   {
   T3 = price; 
   for(int k=0;k<6;k++) tmp[num+k][index][0] = price;
   }
   else 
   if(bar < cbars) 
   {
   dema1 = DEMAOnArray(index,num  ,price,per,v,cbars,bar); 
   dema2 = DEMAOnArray(index,num+2,dema1,per,v,cbars,bar); 
   T3    = DEMAOnArray(index,num+4,dema2,per,v,cbars,bar);
   }
   
   return(T3);
}

// MA_Method=ITrend - Instantaneous Trendline by J.Ehlers
double ITrendOnArray(double& price[],double& array[],int per,int cbars,int bar)
{
   double it = 0, alpha = 2.0/(per + 1);
   
   if(bar < cbars && array[1] > 0 && array[2] > 0) it = (alpha - 0.25*alpha*alpha)*price[bar] + 0.5*alpha*alpha*price[bar+1] 
                                                       -(alpha - 0.75*alpha*alpha)*price[bar+2] + 2*(1 - alpha)*array[1] 
                                                       -(1 - alpha)*(1 - alpha)*array[2];
   else it = (price[bar] + 2*price[bar+1] + price[bar+2])/4;
      
   return(it);
}

// MA_Method=Median - Moving Median
double MedianOnArray(double& price[],int per,int cbars,int bar)
{
   double median = 0, array[];
   ArrayResize(array,per);
   
   if(bar <= cbars)
   {
   for(int i=0;i<per;i++) array[i] = price[bar+i];
   ArraySort(array,WHOLE_ARRAY,0,MODE_DESCEND);
   
   int num = (int)MathRound((per - 1)*0.5); 
   if(MathMod(per,2) > 0) median = array[num]; else median = 0.5*(array[num] + array[num+1]);
   }
    
   return(median); 
}

// MA_Method=GeoMean - Geometric Mean
double GeoMeanOnArray(double& price[],int per,int cbars,int bar)
{
   double gmean = 0;
   
   if(bar < cbars)
   { 
   gmean = MathPow(price[bar],1.0/per); 
   for(int i=1;i<per;i++) gmean *= MathPow(price[bar+i],1.0/per); 
   }
   else 
   if(bar == cbars) gmean = SMAOnArray(price,per,bar);
   
   return(gmean);
}

// MA_Method=REMA - Regularized EMA by Chris Satchwell 
double REMAOnArray(double price,double& array[],int per,double lambda,int cbars,int bar)
{
   double rema, alpha =  2.0/(per + 1);
   
   if(bar < cbars  && array[1] > 0 && array[2] > 0) rema = (array[1]*(1 + 2*lambda) + alpha*(price - array[1]) - lambda*array[2])/(1 + lambda); 
   else rema = price; 
   
   return(rema);
}
// MA_Method=ILRS - Integral of Linear Regression Slope 
double ILRSOnArray(double& price[],int per,int cbars,int bar)
{
   double slope, sum  = per*(per - 1)*0.5;
   double ilrs = 0, sum2 = (per - 1)*per*(2*per - 1)/6.0;
   
   if(bar < cbars)
   {  
   double sum1 = 0;
   double sumy = 0;
      for(int i=0;i<per;i++)
      { 
      sum1 += i*price[bar+i];
      sumy += price[bar+i];
      }
   double num1 = per*sum1 - sum*sumy;
   double num2 = sum*sum - per*sum2;
   
   if(num2 != 0) slope = num1/num2; else slope = 0; 
   ilrs = slope + SMAOnArray(price,per,bar);
   }
   
   return(ilrs);
}
// MA_Method=IE/2 - Combination of LSMA and ILRS 
double IE2OnArray(double& price[],int per,int cbars,int bar)
{
   double ie = 0;
   
   if(bar < cbars) ie = 0.5*(ILRSOnArray(price,per,cbars,bar) + LSMAOnArray(price,per,bar));
      
   return(ie); 
}
 
// MA_Method=TriMAgen - Triangular Moving Average Generalized by J.Ehlers
double TriMA_genOnArray(double& array[],int per,int cbars,int bar)
{
   int len1 = (int)MathFloor((per + 1)*0.5);
   int len2 = (int)MathCeil ((per + 1)*0.5);
   double sum = 0;
   
   if(bar < cbars)
       for(int i = 0;i < len2;i++) sum += SMAOnArray(array,len1,bar+i);
   
   return(sum/len2);
}

// MA_Method=VWMA - Volume Weighted Moving Average 
double VWMAOnArray(double& array[],int per,int bar)
{
   double sum = 0, weight = 0, maxvol = 0, vwma = 0;
   
      for(int i=0;i<per;i++)
      { 
      weight += (double)Volume[bar+i];
      sum    += array[bar+i]*Volume[bar+i];
      }
     
   if(weight > 0) return(sum/weight); else return(0); 
} 

// MA_Method=JSmooth - Smoothing by Mark Jurik
double JSmoothOnArray(int index,int num,double price,int per,double power,int cbars,int bar)
{
   double beta  = 0.45*(per - 1)/(0.45*(per - 1) + 2);
	double alpha = MathPow(beta,power);
	
	if(bar == cbars) {tmp[num+4][index][0] = price; tmp[num+0][index][0] = price; tmp[num+2][index][0] = price;}
	else 
   if(bar <  cbars) 
   {
	tmp[num+0][index][0] = (1 - alpha)*price + alpha*tmp[num+0][index][1];
	tmp[num+1][index][0] = (price - tmp[num+0][index][0])*(1-beta) + beta*tmp[num+1][index][1];
	tmp[num+2][index][0] = tmp[num+0][index][0] + tmp[num+1][index][0];
	tmp[num+3][index][0] = (tmp[num+2][index][0] - tmp[num+4][index][1])*MathPow((1-alpha),2) + MathPow(alpha,2)*tmp[num+3][index][1];
	tmp[num+4][index][0] = tmp[num+4][index][1] + tmp[num+3][index][0]; 
   }
   return(tmp[num+4][index][0]);
}

// MA_Method=SMA_eq     - Simplified SMA
double SMA_eqOnArray(double& price[],double& array[],int per,int cbars,int bar)
{
   double sma = 0;
   
   if(bar == cbars) sma = SMAOnArray(price,per,bar);
   else 
   if(bar <  cbars) sma = (price[bar] - price[bar+per])/per + array[1]; 
   
   return(sma);
}                        		

// MA_Method=ALMA by Arnaud Legoux / Dimitris Kouzis-Loukas / Anthony Cascino
double ALMAOnArray(double& price[],int per,double offset,double sigma,int bar)
{
   double m = MathFloor(offset*(per - 1)), s = per/sigma, w, sum = 0, wsum = 0;		
	
	for(int i=0;i<per;i++) 
	{
	w     = MathExp(-((i - m)*(i - m))/(2*s*s));
   wsum += w;
   sum  += price[bar+(per-1-i)]*w; 
   }
   
   if(wsum != 0) return(sum/wsum); else return(0);
}   

// MA_Method=TEMA - Triple Exponential Moving Average by Patrick Mulloy
double TEMAOnArray(int index,double price,int per,double v,int cbars,int bar)
{
   double alpha = 2.0/(per+1);
	
	if(bar == cbars) {tmp[0][index][0] = price; tmp[1][index][0] = price; tmp[2][index][0] = price;}
	else 
   if(bar <  cbars) 
   {
	tmp[0][index][0] = tmp[0][index][1] + alpha *(price            - tmp[0][index][1]);
	tmp[1][index][0] = tmp[1][index][1] + alpha *(tmp[0][index][0] - tmp[1][index][1]);
	tmp[2][index][0] = tmp[2][index][1] + alpha *(tmp[1][index][0] - tmp[2][index][1]);
	tmp[3][index][0] = tmp[0][index][0] + v*(tmp[0][index][0] + v*(tmp[0][index][0]-tmp[1][index][0]) - tmp[1][index][0] - v*(tmp[1][index][0] - tmp[2][index][0])); 
	}
   
   return(tmp[3][index][0]);
}

// MA_Method=T3 by T.Tillson (correct version) 
double T3OnArray(int index,int num,double price,int per,double v,int cbars,int bar)
{
   double len = MathMax((per + 5.0)/3.0 - 1,1), dema1, dema2, T3 = 0;
   
   if(bar == cbars ) 
   {
   T3 = price; 
   for(int k=0;k<6;k++) tmp[num+k][index][0] = T3;
   }
   else 
   if(bar < cbars) 
   {
   dema1 = DEMAOnArray(index,num  ,price,len,v,cbars,bar); 
   dema2 = DEMAOnArray(index,num+2,dema1,len,v,cbars,bar); 
   T3    = DEMAOnArray(index,num+4,dema2,len,v,cbars,bar);
   }
      
   return(T3);
}

// MA_Method=Laguerre filter by J.Ehlers
double LaguerreOnArray(int index,double price,int per,int order,int cbars,int bar)
{
   double gamma = 1 - 10.0/(per + 9);
   double aPrice[];
   
   ArrayResize(aPrice,order);
   
   for(int i=0;i<order;i++)
   {
      if(bar >= cbars) tmp[i][index][0] = price;
      else
      {
         if(i == 0) tmp[i][index][0] = (1 - gamma)*price + gamma*tmp[i][index][1];
         else
         tmp[i][index][0] = -gamma * tmp[i-1][index][0] + tmp[i-1][index][1] + gamma * tmp[i][index][1];
      
      aPrice[i] = tmp[i][index][0];
      }
   }
   double laguerre = TriMA_genOnArray(aPrice,order,cbars,0);  

   return(laguerre);
}

// MA_Method=MD - McGinley Dynamic
double McGinleyOnArray(double price,double prev,int per,int cbars,int bar)
{
   double md = 0;
   
   if(bar == cbars) md = price;
   else 
   if(bar <  cbars) 
      if(prev != 0) md = prev + (price - prev)/(per*MathPow(price/prev,4)/2); 
      else md = price;

   return(md);
}

// MA_Method=BF2P - Two-pole modified Butterworth filter
double BF2POnArray(double& price[],double& array[],int per,int cbars,int bar)
{
   double a  = MathExp(-1.414*pi/per);
   double b  = 2*a*MathCos(1.414*1.25*pi/per);
   double c2 = b;
   double c3 = -a*a;
   double c1 = 1 - c2 - c3, bf2p;
   
   if(bar < cbars && array[1] > 0 && array[2] > 0) {bf2p = c1*(price[bar] + 2*price[bar+1] + price[bar+2])/4 + c2*array[1] + c3*array[2];
   if(bar == cbars-1) Print("bar=",bar," cbars=",cbars," bf2p=",bf2p," array[1]=",array[1]," array[2]=",array[2]);
   }
   else bf2p = (price[bar] + 2*price[bar+1] + price[bar+2])/4;
   
   return(bf2p);
}

// MA_Method=BF3P - Three-pole modified Butterworth filter
double BF3POnArray(double& price[],double& array[],int per,int cbars,int bar)
{
   double a  = MathExp(-pi/per);
   double b  = 2*a*MathCos(1.738*pi/per);
   double c  = a*a;
   double d2 = b + c;
   double d3 = -(c + b*c);
   double d4 = c*c;
   double d1 = 1 - d2 - d3 - d4, bf3p;
   
   if(bar < cbars && array[1] > 0 && array[2] > 0 && array[3] > 0) bf3p = d1*(price[bar] + 3*price[bar+1] + 3*price[bar+2] + price[bar+3])/8 + d2*array[1] + d3*array[2] + d4*array[3];
   else bf3p = (price[bar] + 3*price[bar+1] + 3*price[bar+2] + price[bar+3])/8;
   
   return(bf3p);
}

// MA_Method=SuperSmu - SuperSmoother filter
double SuperSmuOnArray(double& price[],double& array[],int per,int cbars,int bar)
{
   double a  = MathExp(-1.414*pi/per);
   double b  = 2*a*MathCos(1.414*pi/per);
   double c2 = b;
   double c3 = -a*a;
   double c1 = 1 - c2 - c3, supsm;
   
   if(bar < cbars && array[1] > 0 && array[2] > 0) supsm = c1*(price[bar] + price[bar+1])/2 + c2*array[1] + c3*array[2]; else supsm = (price[bar] + price[bar+1])/2;
   
   return(supsm);
}

// MA_Method=Decycler - Simple Decycler by J.Ehlers
double DecyclerOnArray(double& price[],double& hp[],int per,int cbars,int bar)
{
   double alpha1 = (MathCos(1.414*pi/per) + MathSin(1.414*pi/per) - 1)/MathCos(1.414*pi/per);
  
   if(bar > cbars - 4) return(0);
   
   hp[0] = (1 - alpha1/2)*(1 - alpha1/2)*(price[bar] - 2*price[bar+1] + price[bar+2]) + 2*(1 - alpha1)*hp[1] - (1 - alpha1)*(1 - alpha1)*hp[2];		
       
   return(hp[0]);
}

// MA_Method=eVWMA - Elastic Volume Weighted Moving Average by C.Fries
double eVWMAOnArray(double price,double prev,int per,int cbars,int bar)
{
   double evwma;
 
   if(bar < cbars && prev > 0)
   {
   double max = 0;
   for(int i=0;i<per;i++) max = MathMax(max,Volume[bar+i]);
      
   double diff = 3*max - Volume[bar];
          
      if(diff < 0) evwma = prev;
      else 
      evwma = (diff*prev + Volume[bar]*price)/(3*max); 
   }
   else evwma = price;
    
   return(evwma);
}

// MA_Method=EWMA - Exponential Weighted Moving Average 
double EWMAOnArray(double& array[],int per,int bar)
{
   double sum = 0, weight = 0, alpha = 2.0/(1 + per);
   
      for(int i=0;i<per;i++)
      { 
      weight += alpha*MathPow(1-alpha,i);
      sum    += array[bar+i]*alpha*MathPow(1-alpha,i);
      }
   
   if(weight > 0) return(sum/weight); else return(0); 
} 

// MA_Method=DsEMA - Double Smoothed EMA
double DsEMAOnArray(int index,double price,int per,int cbars,int bar)
{
   double alpha = 4.0/(per + 3);
   
   if(bar == cbars) 
   {
   for(int k=0;k<2;k++) tmp[k][index][0] = price;
   return(price);
   }
   else 
   if(bar < cbars) 
   {
   tmp[0][index][0] = tmp[0][index][1] + alpha*(price            - tmp[0][index][1]);
	tmp[1][index][0] = tmp[1][index][1] + alpha*(tmp[0][index][0] - tmp[1][index][1]);
   }
      
   return(tmp[1][index][0]);
}

// MA_Method=TsEMA - Triple Smoothed EMA
double TsEMAOnArray(int index,double price,int per,int cbars,int bar)
{
   double alpha = 6.0/(per + 5);
   
   if(bar == cbars) 
   {
   for(int k=0;k<3;k++) tmp[k][index][0] = price;
   return(price);
   }
   else 
   if(bar < cbars) 
   {
   tmp[0][index][0] = tmp[0][index][1] + alpha*(price            - tmp[0][index][1]);
	tmp[1][index][0] = tmp[1][index][1] + alpha*(tmp[0][index][0] - tmp[1][index][1]);
   tmp[2][index][0] = tmp[2][index][1] + alpha*(tmp[1][index][0] - tmp[2][index][1]);
   }
      
   return(tmp[2][index][0]);
}

// MA_Method=VEMA - Volume-weighted Exponential Moving Average(V-EMA)
double VEMAOnArray(int index,double price,int per,int cbars,int bar)
{
   double vema = price, alpha = 2.0/(per + 1);
   
   if(bar == cbars) 
   {
   tmp[0][index][0] = (1 - alpha)*price*Volume[bar];
   tmp[1][index][0] = (1 - alpha)*Volume[bar];
   }
   else 
   if(bar < cbars) 
   {
   tmp[0][index][0] = tmp[0][index][1] + alpha*(price*Volume[bar] - tmp[0][index][1]);
	tmp[1][index][0] = tmp[1][index][1] + alpha*(Volume[bar]       - tmp[1][index][1]);
   }
  
   if(tmp[1][index][0] > 0) vema = tmp[0][index][0]/tmp[1][index][0];
   
   return(vema);
}

//
//
//
//

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{

      if(id==CHARTEVENT_MOUSE_MOVE) 
        { 
         //--- Prepare variables 
         int      x     =(int)lparam; 
         int      y     =(int)dparam; 
         datetime dt    =0; 
         double   price =0; 
         int      window=0; 
         
         //--- Convert the X and Y coordinates in terms of date/time 
         if(ChartXYToTimePrice(0,x,y,window,dt,price)) 
           { 
               barstocursor=Bars(NULL, 0, dt, iTime(NULL, 0, 0))-1;
            
               //--- Tell Direction Text
               if(Volatility[barstocursor] > Filter[barstocursor]) UprDown = "Volatility Valid";
               if(Volatility[barstocursor] < Filter[barstocursor]) UprDown = "Volatility Low";  
            
               //--- Create Text 
               ObjectCreate("Candle Volatility Index", OBJ_LABEL, ChartWindowFind(0, "Candle Volatility Index("+(string)MA_Period+","+EnumToString(MA_Type)+")"+" MODE= "+ModeName), 0, 0, 0, 0);
               if(Volatility[barstocursor] > Filter[barstocursor]) ObjectSetText("Candle Volatility Index", UprDown, 14, "Arial", Lime);   
               if(Volatility[barstocursor] < Filter[barstocursor]) ObjectSetText("Candle Volatility Index", UprDown, 14, "Arial", Crimson);            
               ObjectSet("Candle Volatility Index", OBJPROP_CORNER, 0);
               ObjectSet("Candle Volatility Index", OBJPROP_XDISTANCE, 15);
               ObjectSet("Candle Volatility Index", OBJPROP_YDISTANCE, 20);
               ObjectSet("Candle Volatility Index", OBJPROP_BACK, false); 
            
           }     
        }
     
}