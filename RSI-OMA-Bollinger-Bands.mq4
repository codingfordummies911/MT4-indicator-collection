#property copyright "Matt Edmonds"
#property link      "matt.edmonds@gmail.com"

#property indicator_separate_window
#property indicator_minimum -10
#property indicator_maximum 100
#property indicator_buffers 10
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Green
#property indicator_color4 Magenta
#property indicator_color5 DodgerBlue
#property indicator_color6 White
#property indicator_color7 White
#property indicator_color8 White




//---- input parameters
extern int RSIOMA = 14;

extern int BuyTrigger = 80;
extern int SellTrigger = 20;
extern int MainTrendLong = 50;
extern int MainTrendShort = 50;
extern int BollingerPeriod=10;
extern int BollingerDeviation = 1;
extern int BollingerShift = 0;
extern int BarsToUse = 200;


//---- buffers
double RSIBuffer[];
double PosBuffer[];
double NegBuffer[];

double BollingerUpper[];
double BollingerLower[];
double BollingerMiddle[];

double bdn[],bup[];
double sdn[],sup[];



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   string short_name;
//---- 2 additional buffers are used for counting.
     
   
   IndicatorBuffers(10);
   
   SetIndexBuffer(0,RSIBuffer);
   SetIndexBuffer(2,bup);
   SetIndexBuffer(1,bdn);
   SetIndexBuffer(3,sdn);
   SetIndexBuffer(4,sup);
   SetIndexBuffer(7,BollingerUpper);
   SetIndexBuffer(8,BollingerLower);
   SetIndexBuffer(9,BollingerMiddle);
   SetIndexLabel(9,"Bollinger Middle");
   
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,3);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,1);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1);
   SetIndexStyle(3,DRAW_HISTOGRAM,STYLE_SOLID,1);
   SetIndexStyle(4,DRAW_HISTOGRAM,STYLE_SOLID,1);
   SetIndexStyle(7,DRAW_LINE,STYLE_SOLID,1);
   SetIndexStyle(8,DRAW_LINE,STYLE_SOLID,1);
   SetIndexStyle(9,DRAW_LINE,STYLE_DOT,1);

   
   SetIndexBuffer(5,PosBuffer);
   SetIndexBuffer(6,NegBuffer);
   
   short_name="RSIOMA("+RSIOMA+")";
   IndicatorShortName(short_name);

   SetIndexDrawBegin(0,RSIOMA);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
int start()
  {
  SetLevelValue(0, BuyTrigger);
   SetLevelValue(1, SellTrigger);
   SetLevelValue(2, MainTrendLong);
   SetLevelValue(3, MainTrendShort);
   
   SetLevelStyle(STYLE_DOT, 1, Yellow);
   
   int    i,counted_bars=IndicatorCounted();
   double rel,negative,positive;
//----
   if(Bars<=RSIOMA) return(0);
//---- initial zero
   if(counted_bars<1)
      for(i=1;i<=RSIOMA;i++) RSIBuffer[Bars-i]=0.0;
//----
   i=Bars-RSIOMA-1;
   if(counted_bars>=RSIOMA) i=Bars-counted_bars-1;
   while(i>=0)
     {
      double sumn=0.0,sump=0.0;
      if(i==Bars-RSIOMA-1)
        {
         int k=Bars-2;
         //---- initial accumulation
         while(k>=i)
           {
            
            double cma = iMA(Symbol(),0,RSIOMA,0,MODE_EMA,PRICE_CLOSE,k);
            double pma = iMA(Symbol(),0,RSIOMA,0,MODE_EMA,PRICE_CLOSE,k+1);
            
            rel=cma-pma;
            
            if(rel>0) sump+=rel;
            else      sumn-=rel;
            k--;
           }
         positive=sump/RSIOMA;
         negative=sumn/RSIOMA;
        }
      else
        {
         //---- smoothed moving average
         double ccma = iMA(Symbol(),0,RSIOMA,0,MODE_EMA,PRICE_CLOSE,i);
         double ppma = iMA(Symbol(),0,RSIOMA,0,MODE_EMA,PRICE_CLOSE,i+1);
            
         rel=ccma-ppma;
         
         if(rel>0) sump=rel;
         else      sumn=-rel;
         positive=(PosBuffer[i+1]*(RSIOMA-1)+sump)/RSIOMA;
         negative=(NegBuffer[i+1]*(RSIOMA-1)+sumn)/RSIOMA;
        }
      PosBuffer[i]=positive;
      NegBuffer[i]=negative;
      if(negative==0.0) RSIBuffer[i]=0.0;
      else
      {
          RSIBuffer[i]=100.0-100.0/(1+positive/negative);
          
          bdn[i] = 0;
          bup[i] = 0;
          sdn[i] = 0;
          sup[i] = 0;
          
          if(RSIBuffer[i]>MainTrendLong)
          bup[i] = -10;
          
          if(RSIBuffer[i]<MainTrendShort)
          bdn[i] = -10;
          
          if(RSIBuffer[i]<20 && RSIBuffer[i]>RSIBuffer[i+1])
          sup[i] = -10;
          
          if(RSIBuffer[i]>80 && RSIBuffer[i]<RSIBuffer[i+1])
          sdn[i] = -10;
            
          
      }    
      i--;
     }
//----
   for(i=0; i<BarsToUse; i++)
   {  
     BollingerLower[i] = iBandsOnArray(RSIBuffer,0,BollingerPeriod,BollingerDeviation,BollingerShift,MODE_LOWER,i); 
     BollingerUpper[i] = iBandsOnArray(RSIBuffer,0,BollingerPeriod,BollingerDeviation,BollingerShift,MODE_UPPER,i); 
     BollingerMiddle[i] = iBandsOnArray(RSIBuffer,0,BollingerPeriod,BollingerDeviation,BollingerShift,MODE_MAIN,i); 
   }   
   
   return(0);
  }

//+------------------------------------------------------------------+