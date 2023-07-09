<Query Kind="Statements" />

 // Convert the Unforth.doc.txt template into Unforth.doc.md
 // by processing the %startops ... %endops regions.
 
 var root = @"C:\Users\ralph\OneDrive\Documents\Github\Z80\Unforth";
 using var src = new StreamReader(Path.Combine(root, "Unforth.doc.txt"));
 using var tgt = new StreamWriter(Path.Combine(root, "Unforth.doc.md"));
 const int Normal = 1;
 const int Header = 2;
 const int Gloss = 3;
 const int Unforth = 4;
 const int C = 5;
 const int Z80 = 6;
 var state = Normal;
 var unforth = new List<string>{};
 var c = new List<string>{};
 var z80 = new List<string>{};
 void EmitSrcTable() {
    if (unforth.Count == 0) return;
    tgt.WriteLine();
    for (var i = 0; i < unforth.Count; i++) tgt.WriteLine($"| {(i==0?"**Unforth**":""),-20} | `{unforth[i],-40}` |");
    tgt.WriteLine("| :--- | :--- |");
    for (var i = 0; i < c.Count; i++) tgt.WriteLine($"| {(i==0?"**C**":""),-20} | `{c[i],-40}` |");
    for (var i = 0; i < z80.Count; i++) tgt.WriteLine($"| {(i==0?"**Z80**":""),-20} | `{z80[i],-40}` |");
    tgt.WriteLine();
    unforth.Clear();
    c.Clear();
    z80.Clear();
 }
 while (!src.EndOfStream) {
 	var line = src.ReadLine();
	var trim = line.Trim().ToLower();
	if (trim == "%endops") {
		state = Normal;
        EmitSrcTable();
		continue;
	}
 	switch (state) {
	case Normal:
		if (trim == "%startops") {
			state = Header;
		} else {
			tgt.WriteLine(line.Dump());
		}
		continue;
	case Header:
		if (trim != "") {
			tgt.WriteLine(("### " + line).Dump());
			state = Gloss;
		}
		continue;
	case Gloss:
		if (trim == "") {
			state = Unforth;
			//tgt.WriteLine("\n**Unforth**".Dump());
		} else {
			tgt.WriteLine(line.Dump());
		}
		continue;
	case Unforth:
		if (trim == "") {
			state = C;
			//tgt.WriteLine("\n**C**".Dump());
		} else {
		    unforth.Add(line);
			//tgt.WriteLine(("    " + line).Dump());
		}
		continue;
	case C:
		if (trim == "") {
			state = Z80;
			//tgt.WriteLine("\n**Z80**".Dump());
		} else {
			c.Add(line);
            //tgt.WriteLine(("    " + line).Dump());
		}
		continue;
	case Z80:
		if (trim == "") {
			state = Header;
			EmitSrcTable();
		} else {
			z80.Add(line);
            //tgt.WriteLine(("    " + line).Dump());
		}
		continue;
	}
 }