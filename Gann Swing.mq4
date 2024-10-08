//+------------------------------------------------------------------+
//|                                                   Gann Swing.mq4 |
//|                                     Copyright 2020, Danil Makov. |
//|                                       https://vk.com/danil_makov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Danil Makov."
#property link      "https://vk.com/danil_makov"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot GannSwing
#property indicator_label1  "Gann Swing"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrDarkOrange
#property indicator_width1  2
//--- plot SignalBar
#property indicator_label2  "Signal Bar"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrOrangeRed
#property indicator_width2  4
//--- input parameters
input bool Alerts=true;
input int  SignalGap=5;
//--- indicator buffers
double   GannSwingBuffer[];
double   SignalBarBuffer[];
//--- global variables
bool     swing;          // true = bull swing / false = bear swing
double   highest,lowest; // prices high & low
datetime timebar;        // bar open time
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // sets precision format
   IndicatorDigits(Digits);
   // indicator buffers mapping
   SetIndexBuffer(0,GannSwingBuffer);
   SetIndexBuffer(1,SignalBarBuffer);
   // symbol code from wingdings font
   SetIndexArrow(1,158);
   // 0 value will not be displayed
   SetIndexEmptyValue(0,0.0);
   SetIndexEmptyValue(1,0.0);
   //---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   // the last counted bar will be recounted
   int counted_bars=IndicatorCounted();
   if(counted_bars>0)counted_bars--;
   int bars=Bars-counted_bars-2;
   //---
   for(int i=bars; i>0; i--)
     {
      if(swing==true) // bull swing
        {
         // highest high & low
         if(High[i+1]>highest)
           {
            highest=High[i+1];
            lowest=Low[i+1];
            timebar=Time[i+1];
           }
         // high and low or close below the previous
         if((Low[i]<lowest && High[i]<=highest) || Close[i]<lowest)
           {
            GannSwingBuffer[iBarShift(NULL,0,timebar)]=highest;
            SignalBarBuffer[i]=High[i]+SignalGap*Point;
            if(Alerts==true && i==1 && swing==true)
              Alert(Symbol(),": New bull swing!");
            swing=false;
           }
        }
      else // bear swing
        {
         // lowest low & high
         if(Low[i+1]<lowest)
           {
            highest=High[i+1];
            lowest=Low[i+1];
            timebar=Time[i+1];
           }
         // high and low or close above the previous
         if((High[i]>highest && Low[i]>=lowest) || Close[i]>highest)
           {
            GannSwingBuffer[iBarShift(NULL,0,timebar)]=lowest;
            SignalBarBuffer[i]=Low[i]-SignalGap*Point;
            if(Alerts==true && i==1 && swing==false)
              Alert(Symbol(),": New bear swing!");
            swing=true;
           }
        }
     }
   //---
   return(NULL);
  }
//+------------------------------------------------------------------+
