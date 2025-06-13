//+------------------------------------------------------------------+
//|                                               rsi chart bars.mq4 |
//|                                   Copyright © 2008, thestellaman |
//|                            thestellamanrulestheworld@yahoo.co.uk |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, thestellaman"
#property link      "http://www.thestellamanrulestheworld.com"

#property indicator_chart_window
#property indicator_buffers 12
#property indicator_color1 Aqua     //LimeGreen //White    //wick
#property indicator_color2 Yellow      //Orange //DimGray  //wick
#property indicator_color3 Aqua     //LimeGreen //White    //candle
#property indicator_color4 Yellow //Orange //DimGray  //candle

#property indicator_color5 White    //Aqua     //wick
#property indicator_color6 DimGray     //Yellow       //wick
#property indicator_color7 White    //Aqua     //candle
#property indicator_color8 DimGray     //Yellow       //candle

#property indicator_color9  LimeGreen  //Aqua    //LimeGreen      //wick
#property indicator_color10 Orange  //Yellow      //Orange      //wick
#property indicator_color11 LimeGreen  //Aqua     //LimeGreen      //candle
#property indicator_color12 Orange  //Yellow      //Orange      //candle



//---- stoch settings
extern string TimeFrame    = "H4";
extern int	  RSI_Period	= 15;
extern int    RSI_Price    = 0;
extern int	  Overbought	= 50;
extern int	  Oversold		= 50;
extern int	  Overbought1	= 55;
extern int	  Oversold1		= 45;
extern int	  Overbought2	= 65;
extern int	  Oversold2		= 35;


//---- input parameters
extern int	BarWidth			= 1,
				CandleWidth		= 2;

//---- buffers
double Bar1[],
		 Bar2[],
		 Candle1[],
		 Candle2[];
string indicatorFileName;
bool   returnBars;
int    timeFrame;






//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
//---- indicators
	IndicatorShortName("RSI Candles:("+	RSI_Period+")");
	IndicatorBuffers(12);
	SetIndexBuffer(0,Bar1);
	SetIndexBuffer(1,Bar2);				
	SetIndexBuffer(2,Candle1);
	SetIndexBuffer(3,Candle2);
	SetIndexBuffer(4,Bar1);
	SetIndexBuffer(5,Bar2);				
	SetIndexBuffer(6,Candle1);
	SetIndexBuffer(7,Candle2);
	SetIndexBuffer(8,Bar1);
	SetIndexBuffer(9,Bar2);				
	SetIndexBuffer(10,Candle1);
	SetIndexBuffer(11,Candle2);
	SetIndexStyle(0,DRAW_HISTOGRAM,0,BarWidth);
	SetIndexStyle(1,DRAW_HISTOGRAM,0,BarWidth);
	SetIndexStyle(2,DRAW_HISTOGRAM,0,CandleWidth);
	SetIndexStyle(3,DRAW_HISTOGRAM,0,CandleWidth);
	SetIndexStyle(4,DRAW_HISTOGRAM,0,BarWidth);
	SetIndexStyle(5,DRAW_HISTOGRAM,0,BarWidth);
	SetIndexStyle(6,DRAW_HISTOGRAM,0,CandleWidth);
	SetIndexStyle(7,DRAW_HISTOGRAM,0,CandleWidth);
	SetIndexStyle(8,DRAW_HISTOGRAM,0,BarWidth);
	SetIndexStyle(9,DRAW_HISTOGRAM,0,BarWidth);
	SetIndexStyle(10,DRAW_HISTOGRAM,0,CandleWidth);
	SetIndexStyle(11,DRAW_HISTOGRAM,0,CandleWidth);
         indicatorFileName = WindowExpertName();
         returnBars        = TimeFrame=="returnBars";     if (returnBars)     { return(0); }
         timeFrame         = stringToTimeFrame(TimeFrame);

	return(0);
}

//+------------------------------------------------------------------+
double RSI (int i = 0)	{ int y = iBarShift(NULL,timeFrame,Time[i]); return(iRSI(NULL,timeFrame,RSI_Period,RSI_Price,y));}



//+------------------------------------------------------------------+
void SetCandleColor(int col, int i)
{
	double high,low,bodyHigh,bodyLow;


	{
		bodyHigh = MathMax(Open[i],Close[i]);
		bodyLow  = MathMin(Open[i],Close[i]);
		high		= High[i];
		low		= Low[i];
	}

	Bar1[i] = low;	Candle1[i] = bodyLow;
	Bar2[i] = low;	Candle2[i] = bodyLow;
	

	switch(col)
	{
		case 1: 	Bar1[i] = high;	Candle1[i] = bodyHigh;	break;
		case 2: 	Bar2[i] = high;	Candle2[i] = bodyHigh;	break;
	
	}
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
           int limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { Bar1[0] = MathMin(limit+1,Bars-1); return(0); }
           if (timeFrame!=Period()) limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));

	for(int i = limit; i>=0; i--)
	{
		double	rsi	= RSI(i);
		if(rsi > Overbought)	SetCandleColor(1,i);
		if(rsi < Oversold)		SetCandleColor(2,i);
		if(rsi > Overbought1)	SetCandleColor(3,i);
		if(rsi < Oversold1)		SetCandleColor(4,i);
		if(rsi > Overbought1)		SetCandleColor(5,i);
		if(rsi < Oversold1)		SetCandleColor(6,i);
	}
	

	return(0);
}
//+------------------------------------------------------------------+

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
      int chara = StringGetChar(s, length);
         if((chara > 96 && chara < 123) || (chara > 223 && chara < 256))
                     s = StringSetChar(s, length, chara - 32);
         else if(chara > -33 && chara < 0)
                     s = StringSetChar(s, length, chara + 224);
   }
   return(0);
   }