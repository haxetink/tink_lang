package tink.lang;

class Match {
  static public function fragments(s:String, parts:Array<String>):Array<String> {
    var pos = parts[0].length;
    if (s.substr(0, pos) != parts[0]) return [];
    var ret = [parts.shift()];
    for (p in parts) 
      switch s.indexOf(p, pos) {
        case -1: return [];
        case v: 
          ret.push(s.substring(pos, v));
          ret.push(p);
          pos = v + p.length;
    	}
    return ret; 
  }
}