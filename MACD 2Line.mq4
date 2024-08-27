#property copyright "Copyright © 2013"
#property link      "http://www.google.com"

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Green
#property indicator_color4 Red

extern int FastEMA = 12;
extern int SlowEMA = 26;
extern int SignalEMA = 9;
double g_ibuf_88[];
double g_ibuf_92[];
double g_ibuf_96[];
double g_ibuf_100[];

int init() {
   IndicatorDigits(MarketInfo(Symbol(), MODE_DIGITS) + 1.0);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID);
   SetIndexBuffer(0, g_ibuf_88);
   SetIndexDrawBegin(0, SlowEMA);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID);
   SetIndexBuffer(1, g_ibuf_92);
   SetIndexDrawBegin(1, SignalEMA);
   SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID);
   SetIndexBuffer(2, g_ibuf_96);
   SetIndexStyle(3, DRAW_HISTOGRAM, STYLE_SOLID);
   SetIndexBuffer(3, g_ibuf_100);
   IndicatorShortName("MACD(" + FastEMA + "," + SlowEMA + "," + SignalEMA + ")");
   SetIndexLabel(0, "MACD");
   SetIndexLabel(1, "Signal");
   SetIndexLabel(2, "HistogramUP");
   SetIndexLabel(3, "HistogramDOWN");
   return (0);
}

int start() {
   double ld_4;
   int li_12 = IndicatorCounted();
   if (li_12 < 0) return (-1);
   if (li_12 > 0) li_12--;
   int li_0 = Bars - li_12;
   for (int li_16 = 0; li_16 < li_0; li_16++) g_ibuf_88[li_16] = iMA(NULL, 0, FastEMA, 0, MODE_EMA, PRICE_CLOSE, li_16) - iMA(NULL, 0, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, li_16);
   for (li_16 = 0; li_16 < li_0; li_16++) g_ibuf_92[li_16] = iMAOnArray(g_ibuf_88, Bars, SignalEMA, 0, MODE_EMA, li_16);
   for (li_16 = 0; li_16 < li_0; li_16++) {
      g_ibuf_96[li_16] = 0;
      g_ibuf_100[li_16] = 0;
      ld_4 = g_ibuf_88[li_16] - g_ibuf_92[li_16];
      if (ld_4 >= 0.0) g_ibuf_96[li_16] = ld_4;
      else g_ibuf_100[li_16] = ld_4;
   }
   return (0);
}