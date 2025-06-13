//+------------------------------------------------------------------+
//|                                                 RSI+MA+LABEL.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//|                                           Modified LHC 28.01.2009|
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"

#property indicator_separate_window

#property indicator_buffers 2
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_style2 STYLE_SOLID
#property indicator_level1 30
#property indicator_level2 50
#property indicator_level3 70
#property indicator_levelcolor DimGray



//--- input parameters
extern int RSIPeriod = 14;
extern int MAofRSI   = 8; 
extern int MA_method = 1; //Mode EMA

//--- buffers
double RSIBuffer[];
double MAofRSIBuffer[];


color tColor;
color tColor1;
color tColor3;
color tColor4;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   
//--- 2 buffers used for counting.
   IndicatorBuffers(2);
   SetIndexBuffer(0,RSIBuffer);
   SetIndexBuffer(1,MAofRSIBuffer);
  
//--- indicator line
   SetIndexDrawBegin(0,RSIPeriod);
   SetIndexDrawBegin(1,RSIPeriod);
  
//--- name for DataWindow and indicator subwindow label
   IndicatorShortName("RSI("+RSIPeriod+")");
   SetIndexLabel(0,"RSI("+RSIPeriod+")");
   SetIndexLabel(1,"MA("+MAofRSI+")");
   return(0);
  }
  
//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
int start()
  {
   int i;
   int limit;
   int counted_bars=IndicatorCounted();
   
   //---- check for possible errors
   if(counted_bars<0) return(-1);
   
   //---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;

   //--- main loops 1 and 2
   for(i=0; i < limit; i++)
      {
        RSIBuffer[i]=iRSI(Symbol(),0,RSIPeriod,PRICE_CLOSE,i);
      }
  
   for(i=0; i < limit; i++)
      {
        MAofRSIBuffer[i]=iMAOnArray(RSIBuffer,0,MAofRSI,0,MA_method,i);
      }
 
 
 
  //--- Set Object label (_____)
  ObjectCreate("RSI_line", OBJ_LABEL, WindowFind("RSI("+RSIPeriod+")"), 0, 0);
     ObjectSet("RSI_line", OBJPROP_CORNER,1);
     ObjectSet("RSI_line", OBJPROP_XDISTANCE, 66);
     ObjectSet("RSI_line", OBJPROP_YDISTANCE, 0);
     ObjectSetText("RSI_line","_____", 12, "Calibri", Blue);
  ObjectCreate("MA_rsi_line", OBJ_LABEL, WindowFind("RSI("+RSIPeriod+")"), 0, 0);
     ObjectSet("MA_rsi_line", OBJPROP_CORNER,1);
     ObjectSet("MA_rsi_line", OBJPROP_XDISTANCE, 66);
     ObjectSet("MA_rsi_line", OBJPROP_YDISTANCE, 15);
     ObjectSetText("MA_rsi_line","_____", 12, "Calibri", Red);      
     
     
   //--- Set Label RSI value
   ObjectCreate("RSI_value", OBJ_LABEL, WindowFind("RSI("+RSIPeriod+")"), 0, 0);
     ObjectSet("RSI_value", OBJPROP_CORNER,1);
     ObjectSet("RSI_value", OBJPROP_XDISTANCE, 26);
     ObjectSet("RSI_value", OBJPROP_YDISTANCE, 7);
   ObjectCreate("MArsi_value", OBJ_LABEL, WindowFind("RSI("+RSIPeriod+")"), 0, 0);
     ObjectSet("MArsi_value", OBJPROP_CORNER,1);
     ObjectSet("MArsi_value", OBJPROP_XDISTANCE, 26);
     ObjectSet("MArsi_value", OBJPROP_YDISTANCE, 23);
   ObjectCreate("RSI_phase", OBJ_LABEL,  WindowFind("RSI("+RSIPeriod+")"), 0, 0);
     ObjectSet("RSI_phase", OBJPROP_CORNER, 1);
     ObjectSet("RSI_phase", OBJPROP_XDISTANCE, 8);
     ObjectSet("RSI_phase", OBJPROP_YDISTANCE,9);
   ObjectCreate("MArsi_phase", OBJ_LABEL,  WindowFind("RSI("+RSIPeriod+")"), 0, 0);
     ObjectSet("MArsi_phase", OBJPROP_CORNER, 1);
     ObjectSet("MArsi_phase", OBJPROP_XDISTANCE, 8);
     ObjectSet("MArsi_phase", OBJPROP_YDISTANCE,25);
     
     
     //--- Set Label RSI phase
    if(RSIBuffer[0] > 50 )tColor=Green;
         else tColor=Red;
         ObjectSetText("RSI_value",DoubleToStr(RSIBuffer[0],2), 11, "Calibri", tColor);
         
      //--- 
    if(MAofRSIBuffer[0] > 50 )tColor1=Green;
         else tColor1=Red;
         ObjectSetText("MArsi_value",DoubleToStr(MAofRSIBuffer[0],2), 11, "Calibri", tColor1);
         
      //---   
    if(RSIBuffer[0] > RSIBuffer[1])
           {
            tColor3=Green;
            ObjectSetText("RSI_phase","p",10,"Wingdings 3", tColor3);
           }
    else
           { 
            tColor3=Red; 
            ObjectSetText("RSI_phase","q",10,"Wingdings 3", tColor3);
           }
           
    //---     
    if(MAofRSIBuffer[0] > MAofRSIBuffer[1])
           {
            tColor4=Green;
            ObjectSetText("MArsi_phase","p",10,"Wingdings 3", tColor4);
           }
    else
           { 
            tColor4=Red; 
            ObjectSetText("MArsi_phase","q",10,"Wingdings 3", tColor4);
           }
           
           
    return(0);
  }
//+------------------------------------------------------------------+