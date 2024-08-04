//+------------------------------------------------------------------+
//|                                                DS-StatScript.mq5 |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#property script_show_inputs

enum ENUM_PRESET {
  PRESET_ZZ             = 1, // Комментарий: DSZZ
  PRESET_BO             = 2, // Комментарий: DSBOP
  PRESET_ATR            = 3, // Комментарий: DSATR
  PRESET_TPO            = 4, // Комментарий: DSTPO
  PRESET_CUSTOM_COMMENT = 5, // Другой комментарий
  PRESET_CUSTOM_MAGIC   = 6  // Другой MAGIC
};


input     ENUM_PRESET        InpPreset          = PRESET_ZZ;              // Тип фильтра позиций
input     string             InpCustom          = "";                     // Другой комментарий/MAGIC
input     datetime           InpTimeFrom        = 0;                      // Период ОТ
input     datetime           InpTimeTo          = 0;                      // Период ДО (01.01.1970 - сегодня)


#include <Arrays\ArrayString.mqh>
#include "Include\DKStdLib\History\DKHistory.mqh"

struct ReportRow {
  //string                       Name;
  string                       Symbol;
  ulong                        Count;
  
  double                       Volume;
  double                       Profit;
  
  ulong                        DurationSec;
};

string EnumPresetToString(const ENUM_PRESET _preset) {
  if(_preset == PRESET_ZZ) return "DSZZ";
  if(_preset == PRESET_BO) return "DSBOP";
  if(_preset == PRESET_ATR) return "DSATR";
  if(_preset == PRESET_TPO) return "DSTPO";
  if(_preset == PRESET_CUSTOM_COMMENT) return InpCustom;
  if(_preset == PRESET_CUSTOM_MAGIC) return InpCustom;

  return "";
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
  ulong magic = 0;
  string comment_substring = EnumPresetToString(InpPreset);
  if(InpPreset == PRESET_CUSTOM_MAGIC) magic = StringToInteger(comment_substring);
  datetime dt_from = InpTimeFrom;
  datetime dt_to = (InpTimeTo == 0) ? TimeCurrent() : InpTimeTo;

  CDKHistoryPositionList pos_list;
  DKHistoryPos hpos;
  DKHistoryPos hpos_arr[];
  
  pos_list.Load(dt_from, dt_to); // Load historical poses
  
  // Filter pos by comment and fill symbol list
  CArrayString sym_arr;
  for(int i=0;i<pos_list.Total();i++) {
    if(!pos_list.GetSummaryByIndex(i, hpos)) continue;
    
    // Filter pos
    if(magic == 0 && StringFind(hpos.Comment, comment_substring) < 0) continue;
    if(magic != 0 && hpos.Magic != magic) continue;
    
    ArrayResize(hpos_arr, ArraySize(hpos_arr)+1);
    hpos_arr[ArraySize(hpos_arr)-1] = hpos;
    if(sym_arr.SearchLinear(hpos.Symbol) < 0) sym_arr.Add(hpos.Symbol);
  }  
  
  // Group by symbol
  sym_arr.Sort();
  ReportRow rrow_arr[];
  for(int i=0;i<sym_arr.Total();i++) {
    ReportRow rrow;
    rrow.Count = 0;
    rrow.DurationSec = 0;
    //rrow.Name = comment_substring;
    rrow.Profit = 0;
    rrow.Symbol = sym_arr.At(i);
    rrow.Volume = 0;
    for(int j=0;j<ArraySize(hpos_arr);j++) {
      rrow.Count++; 
      rrow.DurationSec += hpos_arr[j].DurationSec;
      rrow.Profit += hpos_arr[j].Profit;
      rrow.Volume += hpos_arr[j].VolumeIn;  
    }
    
    ArrayResize(rrow_arr, ArraySize(rrow_arr)+1);
    rrow_arr[ArraySize(rrow_arr)-1] = rrow;
  }
  
  // Totals
  ReportRow total;
  total.Count = 0;
  total.DurationSec = 0;
  //total.Name = comment_substring;
  total.Profit = 0;
  total.Symbol = StringFormat("ИТОГО %s:", comment_substring);
  total.Volume = 0;
  for(int i=0;i<ArraySize(rrow_arr);i++) {
    total.Count += rrow_arr[i].Count;
    total.DurationSec += rrow_arr[i].DurationSec;
    total.Profit += rrow_arr[i].Profit;
    total.Volume += rrow_arr[i].Volume;
  }
  ArrayResize(rrow_arr, ArraySize(rrow_arr)+1);
  rrow_arr[ArraySize(rrow_arr)-1] = total;
  
  Print("");
  PrintFormat(StringFormat("Отчет за %s-%s по %s=%s",
                           TimeToString(dt_from, TIME_DATE),
                           TimeToString(dt_to, TIME_DATE),
                           (magic == 0) ? "COMMENT" : "MAGIC",
                           comment_substring));
  ArrayPrint(rrow_arr, 2);
}  