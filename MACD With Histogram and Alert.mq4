

#property link      ""
#property  indicator_buffers 3
#property indicator_separate_window
#property indicator_color1 LightGray
#property indicator_color2 Red
#property indicator_color3 Blue


//---- buffers
double Buffer1[];
double Buffer2[];
double Buffer3[];
extern int Fast = 12;
extern int Slow = 26;
extern int Signal = 9;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   //IndicatorBuffers(4);
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1);
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1);
   
   SetIndexBuffer(0,Buffer3);
   SetIndexBuffer(1,Buffer2);
   SetIndexBuffer(2,Buffer1);   
    

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- TODO: add your code here
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
//---- TODO: add your code here
  
   for(int i=Bars;i>=0;i--){
      Buffer1[i]=iMACD(NULL,0,Fast,Slow,Signal,PRICE_CLOSE,MODE_MAIN,i); 
      Buffer2[i]=iMACD(NULL,0,Fast,Slow,Signal,PRICE_CLOSE,MODE_SIGNAL,i);     
      Buffer3[i]=Buffer1[i] - Buffer2[i];
      }
//----
   if(Buffer1[0]==Buffer2[0])
   Alert("MACD cross on ",Symbol()," ",Period());
   
   
   return(0);
  }
//+------------------------------------------------------------------+