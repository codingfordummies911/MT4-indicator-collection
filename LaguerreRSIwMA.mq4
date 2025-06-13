//+------------------------------------------------------------------+
//|                                               LaguerreRSIwMA.mq4 |
//|                                Copyright © 2005, David W. Thomas |
//|                 Moving Average added by Philip Harrison Aug 2008 |
//|                                           mailto:davidwt@usa.net |
//+------------------------------------------------------------------+
// based on http://www.mesasoftware.com/TimeWarp.doc.
#property copyright "Copyright © 2005, David W. Thomas"
#property link      "mailto:davidwt@usa.net"

#property indicator_separate_window
#property indicator_level2 0.85
#property indicator_level3 0.5
#property indicator_level4 0.15
#property indicator_minimum 0
#property indicator_maximum 1
#property indicator_buffers 1
#property indicator_color1 Blue
#property indicator_width1 2

//---- input parameters
extern double    gamma=0.6;
extern int       ma=2; // 1 means no averaging

//---- buffers
double RSIwMA[];
double L0[];
double L1[];
double L2[];
double L3[];
double RSI[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   IndicatorBuffers(6);
//---- indicators
   SetIndexDrawBegin(0, 1);
	SetIndexLabel(0, "Laguerre RSI with Moving Average");
	SetIndexEmptyValue(0, -0.01);
   SetIndexStyle(0, DRAW_LINE);
   SetIndexBuffer(0, RSIwMA);
   SetIndexBuffer(1, L0);
   SetIndexBuffer(2, L1);
   SetIndexBuffer(3, L2);
   SetIndexBuffer(4, L3);
   SetIndexBuffer(5, RSI);

//----
   string short_name="LaguerreRSIwMA(gamma:" + DoubleToStr(gamma, 2) + ")(ma:" + ma + ")";
   IndicatorShortName(short_name);
   return(0);
}

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
	int    limit;
	int    counted_bars = IndicatorCounted();
	double CU, CD;
	//---- last counted bar will be recounted
	if (counted_bars>0)
		counted_bars--;
	else
		counted_bars = 1;
	limit = Bars - counted_bars;
	//---- computations for RSI
	for (int i=limit; i>=0; i--)
	{
		L0[i] = (1.0 - gamma)*Close[i] + gamma*L0[i+1];
		L1[i] = -gamma*L0[i] + L0[i+1] + gamma*L1[i+1];
		L2[i] = -gamma*L1[i] + L1[i+1] + gamma*L2[i+1];
		L3[i] = -gamma*L2[i] + L2[i+1] + gamma*L3[i+1];
		//Print(i," Close[i]=",Close[i],", (1.0 - gamma)*Close[i]=",(1.0 - gamma)*Close[i],", gamma*L0[i+1]=",gamma*L0[i+1]);
		//Print(i," L0=",L0[i],",L1=",L1[i],",L2=",L2[i],",L3=",L3[i]);

		CU = 0;
		CD = 0;
		if (L0[i] >= L1[i])
			CU = L0[i] - L1[i];
		else
			CD = L1[i] - L0[i];
		if (L1[i] >= L2[i])
			CU = CU + L1[i] - L2[i];
		else
			CD = CD + L2[i] - L1[i];
		if (L2[i] >= L3[i])
			CU = CU + L2[i] - L3[i];
		else
			CD = CD + L3[i] - L2[i];

		if (CU + CD != 0)
			RSI[i] = CU / (CU + CD);
			
      // Apply the Simple Moving Average to the LaGuerre data
      RSIwMA[i] = 0;
      
      for(int j = 0; j < ma; j++)
      {
         RSIwMA[i] = RSIwMA[i] + RSI[i+j];
	   }
	   RSIwMA[i] = RSIwMA[i] / ma;
	   			
	}
   return(0);
}
//+------------------------------------------------------------------+