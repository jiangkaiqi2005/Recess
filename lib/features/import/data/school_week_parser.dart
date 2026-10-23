/// 各学校脚本共用的周次语义；无范围的单双周须由宿主提供学期周数。
const schoolWeekParserJs = r'''
  function schoolInteger(value) {
    var raw = String(value == null ? '' : value).trim();
    return /^\d+$/.test(raw) && Number.isSafeInteger(Number(raw)) ? Number(raw) : NaN;
  }
  function schoolWeekNumbers(text, sections) {
    var raw = String(text == null ? '' : text).trim();
    var odd = /单|奇/.test(raw), even = /双|偶/.test(raw);
    // 保留无效标记供 Dart 逐条统计，不让前端解析静默丢课或只接受部分数字。
    if (!raw || (odd && even) || (sections && (odd || even))) return [null];
    // 通用单元格的周次行可能还带节次和教室，后者不属于周次内容。
    if (!sections) raw = raw.replace(/\s+\d[\d,，、\s\-–~至]*节.*$/, '');
    var cleaned = raw.replace(/第|周|节|单|双|奇|偶|[()（）\[\]{}|]/g, '')
        .replace(/\s*([-–~至])\s*/g, '$1').trim()
        .replace(/^[,，、\s]+|[,，、\s]+$/g, '');
    var values = [];
    if (!cleaned && !sections && (odd || even)) {
      if (typeof recessTotalWeeks !== 'number' || recessTotalWeeks < 1) return [null];
      for (var n = 1; n <= recessTotalWeeks; n++) values.push(n);
    } else {
      if (!cleaned) return [null];
      var parts = cleaned.split(/[,，、\s]+/);
      for (var i = 0; i < parts.length; i++) {
        var match = parts[i].match(/^(\d+)(?:[-–~至](\d+))?$/);
        if (!match) return [null];
        var a = Number(match[1]), b = match[2] ? Number(match[2]) : a;
        if (!Number.isSafeInteger(a) || !Number.isSafeInteger(b) || a < 1) return [null];
        if (b < a) return sections ? [a, b] : [null];
        for (var n = a; n <= b; n++) values.push(n);
      }
    }
    return values.filter(function(v, i, all) {
      return all.indexOf(v) === i && (!odd || v % 2 === 1) && (!even || v % 2 === 0);
    }).sort(function(a, b) { return a - b; });
  }
''';
