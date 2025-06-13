//+------------------------------------------------------------------+
//|                              Inverse fisher transform of RSI.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property  copyright "mladen"
#property  link      "mladenfx@gmail.com"

#property  indicator_separate_window
#property  indicator_buffers   5
#property  indicator_color1    Green
#property  indicator_color2    Green
#property  indicator_color3    Red
#property  indicator_color4    Red
#property  indicator_color5    DimGray
#property  indicator_width1    2
#property  indicator_width3    2
#property  indicator_width5    2
#property  indicator_maximum   1
#property  indicator_minimum  -1
#property  indicator_level1    0

//
//
//
//
//

extern string TimeFrame     = "Current time frame";
extern int    RSIPeriod     =  5;
extern int    RSIPrice      =  PRICE_CLOSE;
extern int    MAPeriod      =  9;
extern int    MAMode        =  MODE_LWMA;
extern bool   ShowHistogram =  true;
extern bool   ShowLevels    =  true; 
extern double Level1        =  0.5;
extern double Level2        =  0.0;
extern double Level3        = -0.5;
extern color  ZoneColor     = C'30,33,36';
extern string UniqueID      = " IFTofRSI1";

//
//
//
//
//

double   buffer1[];
double   buffer2[];
double   buffer3[];
double   buffer4[];
double   buffer5[];
double   buffer6[];
double   buffer7[];

//
//
//
//
//

string ShortName;
string indicatorFileName;
bool   returnBars;
bool   calculateValue;
int    timeFrame;

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
   SetIndexBuffer(0,buffer1);
   SetIndexBuffer(1,buffer2);
   SetIndexBuffer(2,buffer3);
   SetIndexBuffer(3,buffer4);
   SetIndexBuffer(4,buffer5);
   SetIndexBuffer(5,buffer6);
   SetIndexBuffer(6,buffer7);
      SetIndexStyle(0,DRAW_HISTOGRAM);
      SetIndexStyle(1,DRAW_HISTOGRAM);
      SetIndexStyle(2,DRAW_HISTOGRAM);
      SetIndexStyle(3,DRAW_HISTOGRAM);
   
   
   //
   //
   //
   //
   //
      
      timeFrame         = stringToTimeFrame(TimeFrame); 
      ShortName         = timeFrameToString(timeFrame)+ UniqueID+" Inverse fisher RSI ("+RSIPeriod+","+MAPeriod+")";
      indicatorFileName = WindowExpertName();
      returnBars        = TimeFrame == "returnBars";     if (returnBars)     return(0);
      calculateValue    = TimeFrame == "calculateValue"; if (calculateValue) return(0);
           
   //
   //
   //
   //
   //
   
   IndicatorShortName(ShortName);
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
//
//
//
//
//

int start()
{
   int i,counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
           int limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { buffer1[0] = limit+1; return(0); }

   //
   //
   //
   //
   //
   
   if (calculateValue || timeFrame == Period())
   {
   for(i=limit; i>=0; i--) buffer7[i] = 0.1*(iRSI(NULL,0,RSIPeriod,RSIPrice,i)-50);
   for(i=limit; i>=0; i--)
   {
      buffer6[i] = iMAOnArray(buffer7,0,MAPeriod,0,MAMode,i);
      buffer5[i] = (MathExp(2*buffer6[i])-1)/(MathExp(2*buffer6[i])+1);

      //
      //
      //
      //
      //
      
      if(ShowHistogram)
      {
         if(buffer5[i]==buffer5[i+1])
         {
            buffer1[i]=buffer1[i+1];
            buffer2[i]=buffer2[i+1];
            buffer3[i]=buffer3[i+1];
            buffer4[i]=buffer4[i+1];
               continue;
         }                        

         //
         //
         //
         //
         //
      
            buffer1[i]=EMPTY_VALUE;
            buffer2[i]=EMPTY_VALUE;
            buffer3[i]=EMPTY_VALUE;
            buffer4[i]=EMPTY_VALUE;
            if(ShowLevels)
               if((buffer5[i]<Level1) && (buffer5[i]>Level3))
                  continue;
      
            //
            //
            //
            //
            //
            
            if(buffer5[i]<0)
            {
               if (buffer5[i]<buffer5[i+1]) buffer3[i]=buffer5[i];
               if (buffer5[i]>buffer5[i+1]) buffer4[i]=buffer5[i];
            }
            if(buffer5[i]>0)
            {
               if (buffer5[i]<buffer5[i+1]) buffer2[i]=buffer5[i];
               if (buffer5[i]>buffer5[i+1]) buffer1[i]=buffer5[i];
            }
      }
   }

   //
   //
   //
   //
   //
   
   if (ShowLevels) UpdateBounds();
   return(0);
   }
   
   //
   //
   //
   //
   //
   
   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
   for (i=limit; i>=0; i--)
   {
       int y = iBarShift(NULL,timeFrame,Time[i]);               
          buffer1[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,MAPeriod,MAMode,ShowHistogram,ShowLevels,Level1,Level2,Level3,ZoneColor,UniqueID,0,y);
          buffer2[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,MAPeriod,MAMode,ShowHistogram,ShowLevels,Level1,Level2,Level3,ZoneColor,UniqueID,1,y);
          buffer3[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,MAPeriod,MAMode,ShowHistogram,ShowLevels,Level1,Level2,Level3,ZoneColor,UniqueID,2,y);
          buffer4[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,MAPeriod,MAMode,ShowHistogram,ShowLevels,Level1,Level2,Level3,ZoneColor,UniqueID,3,y);
          buffer5[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,MAPeriod,MAMode,ShowHistogram,ShowLevels,Level1,Level2,Level3,ZoneColor,UniqueID,4,y);
   }
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

void DeleteBounds()
{
   ObjectDelete(ShortName+"-1");
   ObjectDelete(ShortName+"-2");
   ObjectDelete(ShortName+"-3");
}
void UpdateBounds()
{
   SetUpBound(ShortName+"-1",1          ,Level1);
   SetUpBound(ShortName+"-2",Level2*1.01,Level2*0.99);
   SetUpBound(ShortName+"-3",Level3     ,      -1.00);
}
void SetUpBound(string name, double up, double down)
{
   if (ObjectFind(name) == -1)
      {
         ObjectCreate(name,OBJ_RECTANGLE,WindowFind(ShortName),0,0);
         ObjectSet(name,OBJPROP_PRICE1,up);
         ObjectSet(name,OBJPROP_PRICE2,down);
         ObjectSet(name,OBJPROP_COLOR,ZoneColor);
         ObjectSet(name,OBJPROP_BACK,true);
         ObjectSet(name,OBJPROP_TIME1,iTime(NULL,0,Bars-1));
      }
   if (ObjectGet(name,OBJPROP_TIME2) != iTime(NULL,0,0))
       ObjectSet(name,OBJPROP_TIME2,    iTime(NULL,0,0));
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
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