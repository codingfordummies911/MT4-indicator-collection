//+------------------------------------------------------------------+
//|                                                    ATR_X_EMA.mq4 |
//|                                                            Ahmed |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Ahmed"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window

#property indicator_buffers 4
#property indicator_color1 clrSteelBlue
#property indicator_color2 clrIvory
#property indicator_color3 clrMediumOrchid
#property indicator_color4 clrOrangeRed 

extern int ATRPeriod=14;
extern int MAPeriod = 14 ;
extern int MAType = 1 ;


//---- buffers
double xxATR[];
double xxMA[];
double Buff1[];
double Buff2[];
//-----
double atrnow,atrpre,manow,mapre;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//--- indicator buffers mapping
//---- indicators
    SetIndexStyle(0, DRAW_LINE, 0, 2);
    SetIndexBuffer(0, xxATR);
//----
    SetIndexStyle(1, DRAW_LINE,0, 1);
    SetIndexBuffer(1, xxMA);
    
     SetIndexStyle(2, DRAW_ARROW, 0, 1);
    SetIndexArrow(2, 233);
    SetIndexBuffer(2, Buff1);
//----
    SetIndexStyle(3, DRAW_ARROW, 0, 1);
    SetIndexArrow(3, 234);
    SetIndexBuffer(3, Buff2);
//---- name for DataWindow and indicator subwindow label
    IndicatorShortName("ATR (" + ATRPeriod  + ") ");
    SetIndexLabel(0, " ATR ");
    SetIndexLabel(1, " ATR-MA ");  
    SetIndexLabel(2, "up");
    SetIndexLabel(3, "Dn");    
//---
    return(0);
  }
//+------------------------------------------------------------------+


  


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
  /*  int    counted_bars=IndicatorCounted() , limit ;
   //---- check for possible errors
   if(counted_bars < 0) 
        return(-1);
//---- last counted bar will be recounted
    if(counted_bars > 0) 
        counted_bars--;
    limit = Bars - counted_bars; */
//----
  for(int i = 0 ; i < Bars ; i++ ){  xxATR[i]= iATR(Symbol(),Period(),ATRPeriod,i);}
  for(int i = 0 ; i < Bars ; i++ ) { xxMA[i]= iMAOnArray(xxATR, 0 , MAPeriod , 0, MAType , i) ;}

 
  for(int i = 1 ; i < Bars-10 ; i++ ){
    atrnow = xxATR[i-1]; 
 atrpre = xxATR[i];
 manow= xxMA[i-1]  ;
 mapre= xxMA[i]; 
  if( atrnow - manow >0 && atrpre - mapre <0 ){Buff1[i] =  xxMA[i] - xxMA[i]/40 ;}
  }
    
 
  
 for(int i = 1 ; i < Bars-10 ; i++ ) {
  atrnow = xxATR[i-1]; 
 atrpre = xxATR[i];
 manow= xxMA[i-1]  ;
 mapre= xxMA[i]; 
 if( atrnow - manow <0  && atrpre - mapre >0 ){Buff2[i] =  xxMA[i] + xxMA[i]/40  ;}}
  
  
  
  
  return(0); 
   }
//----
  
//+------------------------------------------------------------------+



int deinit()
  {
//----
   
//----
   return(0);
  }
  