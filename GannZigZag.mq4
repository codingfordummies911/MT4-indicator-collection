//+------------------------------------------------------------------+
//|                                                   GannZIGZAG.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 DeepSkyBlue
#property indicator_color2 Black
//---- input parameters
extern int GSv_range=3;
//---- buffers
double GSv_sl[];
double GSv_m[];
//----
bool draw_up=0,draw_dn=0,initfl=0;
int  fPoint_i,sPoint_i,s_up,s_dn,drawf,lb,idFile;
double h,l;
bool cur_h=0,cur_l=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_SECTION,STYLE_SOLID);
   //SetIndexStyle(1,DRAW_SECTION);
   SetIndexBuffer(0,GSv_sl);
   //SetIndexBuffer(1,GSv_m);
   SetIndexEmptyValue(0,0.0);
   //SetIndexEmptyValue(1,0.0);
   FileDelete("Gann.txt");
   idFile=FileOpen("Gann.txt",FILE_READ|FILE_WRITE,"  ");
//----
   return(0);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int counted_bars=IndicatorCounted();
   int cb,limit,i;
//---- 
   if( GSv_range<1 )
   {
      Alert("Индикатор рассчитывает значения /n при параметре GSv_range не меньше 1!!!");
      return(-1);
   }
   if( counted_bars<0 )
   {
      return(-1);
   }
   else
   {
      if( Bars-1-counted_bars<=0 )
      {
         limit=0;
      }
      else
      {
         limit=Bars-1-counted_bars;
      }
   }
   //первоначальная инициализация
   if( initfl!=1 )
   {
      myInit();
   }
   //FileWrite(idFile,"  0. Баров на графике "+Bars);
   //цикл по барам
   for( cb=limit;cb>=0;cb--)
   {
      if( cb==0 ) FileWrite(idFile,"---- индекс текущего бара "+cb+" "+(Bars-1-cb)+" время "+TimeToStr(Time[cb])+" баров на графике "+Bars);
      //если на предыдущем баре был отрисован экстремум
      if( GSv_sl[cb+1]>0 && lb!=Bars-1-cb )
      {
         if( draw_up!=0 )
         {
            s_dn=0;
            if( cb==0 ) FileWrite(idFile,"  1. Был отрисован максимум, счетчик минимумов обнулен");
         }
         else
         {
            if( draw_dn!=0 )
            {
               s_up=0;
               if( cb==0 ) FileWrite(idFile,"  2. Был отрисован минимум, счетчик максимумов обнулен");
            }
         }
      }
      if( lb!=Bars-1-cb )
      {
         cur_h=0;
         cur_l=0;
         if( cb==0 ) FileWrite(idFile,"  2.1 новый бар флаги наличия максимума и минимума сброшены");
      }
      if( cb>Bars-2-drawf || (High[cb]<=High[cb+1] && Low[cb]>=Low[cb+1]) )
      {
         if( cb==0 ) FileWrite(idFile,"  3. Бар либо 'внутренний', либо до первого экстремума");
         continue;
      }
      if( draw_up!=0 )
      {
         if( cb==0 ) FileWrite(idFile,"  4. Индикатор направлен вверх");
         //если линия направлена вверх
         if( High[cb]>h )
         {
            //если достигнут новый максимум
            h=High[cb];
            cur_h=1;
            if( cb==0 ) FileWrite(idFile,"  5. Достигнут новый максимум = "+h+" cur_h "+cur_h);
         }
         if( Low[cb]<l )
         {
            //если достигнут новый минимум
            l=Low[cb];
            if( cb==0 ) FileWrite(idFile,"  6. Достигнут новый минимум = "+l);
            //если это не тот же самый бар
            if( lb!=Bars-1-cb || cur_l!=1 ) s_dn++;
            cur_l=1;
            if( cb==0 ) FileWrite(idFile,"  7. Бар новый, счетчик минимумов увеличен "+s_dn+" cur_l "+cur_l);
         }
         //если счетчики равны
         if( s_up==s_dn )
         {
            if( cb==0 ) FileWrite(idFile,"  8. Счетчики равны");
            //если последний бар одновременно новый максимум и минимум
            if( cur_h==cur_l && cur_l==1 )
            {
               if( cb==0 ) FileWrite(idFile,"  9. Есть два экстремума");
               //если свеча медвежья
               if( Close[cb]<=Open[cb] )
               {
                  draw_up=0;
                  draw_dn=1;
                  fPoint_i=sPoint_i;
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=l;
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  10. Свеча медвежья, линия вверх = "+draw_up+", линия вниз,"+draw_dn+" fPoint_i = "+fPoint_i+" sPoint_i "+sPoint_i+" индикатор = "+GSv_sl[cb]);
               }
               else
               {
                  //если свеча бычья
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=h;
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  11. Свеча бычья, линия вверх = "+draw_up+", линия вниз,"+draw_dn+" fPoint_i = "+fPoint_i+" sPoint_i "+sPoint_i+" индикатор = "+GSv_sl[cb]);
               }
            }
            else
            {
               //если последний бар только новый максимум
               if( cur_h==1 )
               {
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=h;
                  l=Low[cb];
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  12. Только максимум, индикатор = "+GSv_sl[cb]+" sPoint_i "+sPoint_i+" l "+l);
               }
               else
               {
                  if( cur_l==1 )
                  {
                     //если последний бар только новый минимум
                     draw_up=0;
                     draw_dn=1;
                     fPoint_i=sPoint_i;
                     sPoint_i=Bars-1-cb;
                     GSv_sl[cb]=l;
                     h=High[cb];
                     for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                     {
                        GSv_sl[i]=0;
                     }
                     if( cb==0 ) FileWrite(idFile,"  13. Только минимум, индикатор = "+GSv_sl[cb]+" fPoint_i "+fPoint_i+" sPoint_i "+sPoint_i+" draw_up "+draw_up+" draw_dn "+draw_dn+" h "+h);
                  }
               }
            }
         }
         else
         {
            //иначе если смены направления нет явно (счетчик Dn свечей не равен GSv_range)
            if( cb==0 ) FileWrite(idFile,"  14. Счетчики не равны");
            //если достигнут новый максимум
            if( cur_h==1 )
            {
               sPoint_i=Bars-1-cb;
               GSv_sl[cb]=h;
               for( i=cb+1;i<Bars-1-fPoint_i;i++ )
               {
                  GSv_sl[i]=0;
               }
               l=Low[cb];
               if( cb==0 ) FileWrite(idFile,"  15. Есть новый максимум, индикатор "+GSv_sl[cb]+" sPoint_i "+sPoint_i+" l "+l);
            }
         }
      }
      else
      {
         //если линия направлена вниз
         if( cb==0 ) FileWrite(idFile,"  16. Индикатор направлен вниз");
         if( High[cb]>h )
         {
            //если достигнут новый максимум
            h=High[cb];
            if( cb==0 ) FileWrite(idFile,"  17. Достигнут новый максимум "+h);
            if( lb!=Bars-1-cb || cur_h!=1 ) s_up++;
            cur_h=1;
            //если это не тот же самый бар
            if( cb==0 ) FileWrite(idFile,"  18. Новый бар, счетчик максимумов увеличен "+s_up+" cur_h "+cur_h+" h "+h);
         }
         if( Low[cb]<l )
         {
            //если достигнут новый минимум
            l=Low[cb];
            cur_l=1;
            if( cb==0 ) FileWrite(idFile,"  19. Достигнут новый минимум "+l+" cur_l "+cur_l);
         }
         //если счетчики равны 
         if( s_up==s_dn )
         {
            if( cb==0 ) FileWrite(idFile,"  20. Счетчики равны");
            //если последний бар одновременно новый максимум и минимум
            if( cur_h==cur_l && cur_l==1 )
            {
               if( cb==0 ) FileWrite(idFile,"  21. Есть два экстремума");
               //если свеча медвежья
               if( Close[cb]<=Open[cb] )
               {
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=l;
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  22. Свеча медвежья, индикатор "+GSv_sl[cb]+" sPoint_i "+sPoint_i);
               }
               else
               {
                  //если свеча бычья
                  draw_up=1;
                  draw_dn=0;
                  fPoint_i=sPoint_i;
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=h;
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  23. Свеча бычья, индикатор "+GSv_sl[cb]+" draw_up "+draw_up+" draw_dn "+draw_dn+" sPoint_i "+sPoint_i+" fPoint_i "+fPoint_i);
               }
            }
            else
            {
               //если последний бар только новый максимум
               if( cur_h==1 )
               {
                  draw_up=1;
                  draw_dn=0;
                  fPoint_i=sPoint_i;
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=h;
                  l=Low[cb];
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  24. Только максимум, индикатор "+GSv_sl[cb]+" draw_up "+draw_up+" draw_dn "+draw_dn+" sPoint_i "+sPoint_i+" fPoint_i "+fPoint_i+" l "+l);
               }
               else
               {
                  if( cur_l==1 )
                  {
                     //если последний бар только новый минимум
                     sPoint_i=Bars-1-cb;
                     GSv_sl[cb]=l;
                     h=High[cb];
                     for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                     {
                        GSv_sl[i]=0;
                     }
                     if( cb==0 ) FileWrite(idFile,"  25. Только минимум, индикатор "+GSv_sl[cb]+" sPoint_i "+sPoint_i+" h "+h);
                  }
               }
            }
         }
         else
         {
            //иначе если смены направления нет явно (счетчик Up свечей не равен GSv_range)
            if( cb==0 ) FileWrite(idFile,"  26. Счетчики не равны");
            //если достигнут новый минимум
            if( cur_l==1 )
            {
               sPoint_i=Bars-1-cb;
               GSv_sl[cb]=l;
               for( i=cb+1;i<Bars-1-fPoint_i;i++ )
               {
                  GSv_sl[i]=0;
               }
               h=High[cb];
               if( cb==0 ) FileWrite(idFile,"  27. Достигнут новый минимум, индикатор "+GSv_sl[cb]+" sPoint_i "+sPoint_i+" h "+h);
            }
         }
      }
      if( lb!=Bars-1-cb ) lb=Bars-1-cb;
   }

//----
   return(0);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   FileClose(idFile);
//----
   return(0);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// Функция начальной инициализации индикатора                        |
//+------------------------------------------------------------------+
void myInit()
  {
//---- 
   int cb;
   fPoint_i=0;
   h=High[Bars-1];
   l=Low[Bars-1];
   for( cb=Bars-2;cb>=0;cb--)
   {
      if( High[cb]>High[cb+1] || Low[cb]<Low[cb+1] )
      {
         if( High[cb]>h && High[cb]>High[cb+1] )
         {
            s_up++;
         }
         if( Low[cb]<l && Low[cb]<Low[cb+1] )
         {
            s_dn++;
         }
      }
      else
      {
         continue;
      }
      if( s_up==s_dn && s_up==GSv_range )
      {
         h=High[cb];
         l=Low[cb];
         sPoint_i=Bars-1-cb;
         if( Close[cb]>=Open[cb] )
         {
            s_dn=0;
            GSv_sl[Bars-1]=Low[Bars-1];
            GSv_sl[cb]=High[cb];
            draw_up=1;
            break;
         }
         else
         {
            s_up=0;
            GSv_sl[Bars-1]=High[Bars-1];
            GSv_sl[cb]=Low[cb];
            draw_dn=1;
            break;
         }
      }
      else
      {
         h=High[cb];
         l=Low[cb];
         sPoint_i=Bars-1-cb;
         if( s_up==GSv_range )
         {
            s_dn=0;
            GSv_sl[Bars-1]=Low[Bars-1];
            GSv_sl[cb]=High[cb];
            draw_up=1;
            break;
         }
         else
         {
            if( s_dn==GSv_range )
            {
               s_up=0;
               GSv_sl[Bars-1]=High[Bars-1];
               GSv_sl[cb]=Low[cb];
               draw_dn=1;
               break;
            }
         }
      }
   }
   initfl=1;
   drawf=sPoint_i;
//----
   return(0);
  }
//+------------------------------------------------------------------+

