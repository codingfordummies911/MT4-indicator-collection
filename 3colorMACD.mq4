//+------------------------------------------------------------------+
//|                                            Three Colour MACD.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//|                                              Nikolay Kositsin    |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2004, MetaQuotes Software Corp."
#property  link      "http://www.metaquotes.net/"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 5
#property  indicator_color1  Lime
#property  indicator_color2  Red
#property  indicator_color3  Gray
#property  indicator_color4  Red
#property  indicator_color5  Silver
//---- indicator parameters
extern int FastEMA=12;
extern int SlowEMA=26;
extern int SignalSMA=4;   //9;
extern int CountBars=300;
extern int Line=2;
extern double  Zero_level=0.0;
//---- indicator buffers
double     ind_buffer1[];
double     ind_buffer2[];
double     ind_buffer3[];
double     ind_buffer4[];
double     ind_buffer5[];
double     ind_buffer6[];

double minuse;
double Vol;
double Zml;
double Color1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
  
//---- indicator buffers mapping
   IndicatorBuffers(6);
   if(!SetIndexBuffer(0,ind_buffer1) &&
      !SetIndexBuffer(1,ind_buffer2) &&
      !SetIndexBuffer(2,ind_buffer3) &&
      !SetIndexBuffer(3,ind_buffer4) &&
      !SetIndexBuffer(4,ind_buffer5) &&
      !SetIndexBuffer(5,ind_buffer6))
       Print("cannot set indicator buffers!");
//---- drawing settings
    
   Color1= Lime;                                            
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID, Line, Color1); 
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID, Line);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID, Line);
   SetIndexStyle(3,DRAW_LINE,0,2);   
   SetIndexStyle(4,DRAW_LINE,2,1); 

   SetIndexDrawBegin(0,Bars-CountBars);
   SetIndexDrawBegin(1,Bars-CountBars);
   SetIndexDrawBegin(2,Bars-CountBars);
   SetIndexDrawBegin(3,Bars-CountBars+SignalSMA); 
   SetIndexDrawBegin(4,Bars-CountBars-100); 
   SetIndexShift(4,100);
     
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+1);

//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("MACD("+FastEMA+","+SlowEMA+","+SignalSMA+")");
   SetIndexLabel(0,"MACD+");
   SetIndexLabel(1,"MACD-");
   SetIndexLabel(2,"MACD0");
   SetIndexLabel(3,"Signal");
   SetIndexLabel(4,"Zero");
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int start()   
   {
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM, STYLE_SOLID,Line); 
   SetIndexStyle(1,DRAW_HISTOGRAM, STYLE_SOLID,Line);
   SetIndexStyle(2,DRAW_HISTOGRAM, STYLE_SOLID,Line);
   SetIndexStyle(3,DRAW_LINE, 0,2);
   SetIndexStyle(4,DRAW_LINE, 2,1);
   
   int limit;  
   int counted_bars=IndicatorCounted(); 
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
//---- macd counted in the 1-st buffer
   
   for(int i=0; i<limit; i++)      
   
      ind_buffer6[i]=iMA(NULL,0,FastEMA,0,MODE_EMA,PRICE_CLOSE,i)-iMA(NULL,0,SlowEMA,0,MODE_EMA,PRICE_CLOSE,i);      
      
//---- Three Colour MACD mapping 
     for(i=0; i<limit; i++)
   {   
       ind_buffer5[i]=Zero_level;
       
       Vol = ind_buffer6[i];     minuse = Vol - ind_buffer6[i+1];  
     
           if(minuse>0.0){ind_buffer1[i]=Vol; ind_buffer2[i]=0.0; ind_buffer3[i]=0.0;} 
     else {if(minuse<0.0){ind_buffer1[i]=0.0; ind_buffer2[i]=Vol; ind_buffer3[i]=0.0;}
     else                {ind_buffer1[i]=0.0; ind_buffer2[i]=0.0; ind_buffer3[i]=Vol;}} 
 //---- 
   } 
        
//---- signal line counted in the 2-nd buffer
   for(i=0; i<limit; i++)
      ind_buffer4[i]=iMAOnArray(ind_buffer6,Bars,SignalSMA,0,MODE_SMA,i);
//---- done
   return(0);
  }