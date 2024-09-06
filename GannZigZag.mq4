//+------------------------------------------------------------------+
//|                                                   GannZIGZAG.mq4 |
//|                      Copyright � 2005, MetaQuotes Software Corp. |
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
      Alert("��������� ������������ �������� /n ��� ��������� GSv_range �� ������ 1!!!");
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
   //�������������� �������������
   if( initfl!=1 )
   {
      myInit();
   }
   //FileWrite(idFile,"  0. ����� �� ������� "+Bars);
   //���� �� �����
   for( cb=limit;cb>=0;cb--)
   {
      if( cb==0 ) FileWrite(idFile,"---- ������ �������� ���� "+cb+" "+(Bars-1-cb)+" ����� "+TimeToStr(Time[cb])+" ����� �� ������� "+Bars);
      //���� �� ���������� ���� ��� ��������� ���������
      if( GSv_sl[cb+1]>0 && lb!=Bars-1-cb )
      {
         if( draw_up!=0 )
         {
            s_dn=0;
            if( cb==0 ) FileWrite(idFile,"  1. ��� ��������� ��������, ������� ��������� �������");
         }
         else
         {
            if( draw_dn!=0 )
            {
               s_up=0;
               if( cb==0 ) FileWrite(idFile,"  2. ��� ��������� �������, ������� ���������� �������");
            }
         }
      }
      if( lb!=Bars-1-cb )
      {
         cur_h=0;
         cur_l=0;
         if( cb==0 ) FileWrite(idFile,"  2.1 ����� ��� ����� ������� ��������� � �������� ��������");
      }
      if( cb>Bars-2-drawf || (High[cb]<=High[cb+1] && Low[cb]>=Low[cb+1]) )
      {
         if( cb==0 ) FileWrite(idFile,"  3. ��� ���� '����������', ���� �� ������� ����������");
         continue;
      }
      if( draw_up!=0 )
      {
         if( cb==0 ) FileWrite(idFile,"  4. ��������� ��������� �����");
         //���� ����� ���������� �����
         if( High[cb]>h )
         {
            //���� ��������� ����� ��������
            h=High[cb];
            cur_h=1;
            if( cb==0 ) FileWrite(idFile,"  5. ��������� ����� �������� = "+h+" cur_h "+cur_h);
         }
         if( Low[cb]<l )
         {
            //���� ��������� ����� �������
            l=Low[cb];
            if( cb==0 ) FileWrite(idFile,"  6. ��������� ����� ������� = "+l);
            //���� ��� �� ��� �� ����� ���
            if( lb!=Bars-1-cb || cur_l!=1 ) s_dn++;
            cur_l=1;
            if( cb==0 ) FileWrite(idFile,"  7. ��� �����, ������� ��������� �������� "+s_dn+" cur_l "+cur_l);
         }
         //���� �������� �����
         if( s_up==s_dn )
         {
            if( cb==0 ) FileWrite(idFile,"  8. �������� �����");
            //���� ��������� ��� ������������ ����� �������� � �������
            if( cur_h==cur_l && cur_l==1 )
            {
               if( cb==0 ) FileWrite(idFile,"  9. ���� ��� ����������");
               //���� ����� ��������
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
                  if( cb==0 ) FileWrite(idFile,"  10. ����� ��������, ����� ����� = "+draw_up+", ����� ����,"+draw_dn+" fPoint_i = "+fPoint_i+" sPoint_i "+sPoint_i+" ��������� = "+GSv_sl[cb]);
               }
               else
               {
                  //���� ����� �����
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=h;
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  11. ����� �����, ����� ����� = "+draw_up+", ����� ����,"+draw_dn+" fPoint_i = "+fPoint_i+" sPoint_i "+sPoint_i+" ��������� = "+GSv_sl[cb]);
               }
            }
            else
            {
               //���� ��������� ��� ������ ����� ��������
               if( cur_h==1 )
               {
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=h;
                  l=Low[cb];
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  12. ������ ��������, ��������� = "+GSv_sl[cb]+" sPoint_i "+sPoint_i+" l "+l);
               }
               else
               {
                  if( cur_l==1 )
                  {
                     //���� ��������� ��� ������ ����� �������
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
                     if( cb==0 ) FileWrite(idFile,"  13. ������ �������, ��������� = "+GSv_sl[cb]+" fPoint_i "+fPoint_i+" sPoint_i "+sPoint_i+" draw_up "+draw_up+" draw_dn "+draw_dn+" h "+h);
                  }
               }
            }
         }
         else
         {
            //����� ���� ����� ����������� ��� ���� (������� Dn ������ �� ����� GSv_range)
            if( cb==0 ) FileWrite(idFile,"  14. �������� �� �����");
            //���� ��������� ����� ��������
            if( cur_h==1 )
            {
               sPoint_i=Bars-1-cb;
               GSv_sl[cb]=h;
               for( i=cb+1;i<Bars-1-fPoint_i;i++ )
               {
                  GSv_sl[i]=0;
               }
               l=Low[cb];
               if( cb==0 ) FileWrite(idFile,"  15. ���� ����� ��������, ��������� "+GSv_sl[cb]+" sPoint_i "+sPoint_i+" l "+l);
            }
         }
      }
      else
      {
         //���� ����� ���������� ����
         if( cb==0 ) FileWrite(idFile,"  16. ��������� ��������� ����");
         if( High[cb]>h )
         {
            //���� ��������� ����� ��������
            h=High[cb];
            if( cb==0 ) FileWrite(idFile,"  17. ��������� ����� �������� "+h);
            if( lb!=Bars-1-cb || cur_h!=1 ) s_up++;
            cur_h=1;
            //���� ��� �� ��� �� ����� ���
            if( cb==0 ) FileWrite(idFile,"  18. ����� ���, ������� ���������� �������� "+s_up+" cur_h "+cur_h+" h "+h);
         }
         if( Low[cb]<l )
         {
            //���� ��������� ����� �������
            l=Low[cb];
            cur_l=1;
            if( cb==0 ) FileWrite(idFile,"  19. ��������� ����� ������� "+l+" cur_l "+cur_l);
         }
         //���� �������� ����� 
         if( s_up==s_dn )
         {
            if( cb==0 ) FileWrite(idFile,"  20. �������� �����");
            //���� ��������� ��� ������������ ����� �������� � �������
            if( cur_h==cur_l && cur_l==1 )
            {
               if( cb==0 ) FileWrite(idFile,"  21. ���� ��� ����������");
               //���� ����� ��������
               if( Close[cb]<=Open[cb] )
               {
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=l;
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  22. ����� ��������, ��������� "+GSv_sl[cb]+" sPoint_i "+sPoint_i);
               }
               else
               {
                  //���� ����� �����
                  draw_up=1;
                  draw_dn=0;
                  fPoint_i=sPoint_i;
                  sPoint_i=Bars-1-cb;
                  GSv_sl[cb]=h;
                  for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                  {
                     GSv_sl[i]=0;
                  }
                  if( cb==0 ) FileWrite(idFile,"  23. ����� �����, ��������� "+GSv_sl[cb]+" draw_up "+draw_up+" draw_dn "+draw_dn+" sPoint_i "+sPoint_i+" fPoint_i "+fPoint_i);
               }
            }
            else
            {
               //���� ��������� ��� ������ ����� ��������
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
                  if( cb==0 ) FileWrite(idFile,"  24. ������ ��������, ��������� "+GSv_sl[cb]+" draw_up "+draw_up+" draw_dn "+draw_dn+" sPoint_i "+sPoint_i+" fPoint_i "+fPoint_i+" l "+l);
               }
               else
               {
                  if( cur_l==1 )
                  {
                     //���� ��������� ��� ������ ����� �������
                     sPoint_i=Bars-1-cb;
                     GSv_sl[cb]=l;
                     h=High[cb];
                     for( i=cb+1;i<Bars-1-fPoint_i;i++ )
                     {
                        GSv_sl[i]=0;
                     }
                     if( cb==0 ) FileWrite(idFile,"  25. ������ �������, ��������� "+GSv_sl[cb]+" sPoint_i "+sPoint_i+" h "+h);
                  }
               }
            }
         }
         else
         {
            //����� ���� ����� ����������� ��� ���� (������� Up ������ �� ����� GSv_range)
            if( cb==0 ) FileWrite(idFile,"  26. �������� �� �����");
            //���� ��������� ����� �������
            if( cur_l==1 )
            {
               sPoint_i=Bars-1-cb;
               GSv_sl[cb]=l;
               for( i=cb+1;i<Bars-1-fPoint_i;i++ )
               {
                  GSv_sl[i]=0;
               }
               h=High[cb];
               if( cb==0 ) FileWrite(idFile,"  27. ��������� ����� �������, ��������� "+GSv_sl[cb]+" sPoint_i "+sPoint_i+" h "+h);
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
// ������� ��������� ������������� ����������                        |
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

