<Query Kind="Program" />

void Main(string[] args)
{
	args = new [] { 
		@"C:\Users\ralph\OneDrive\Documents\GitHub\Z80\Unforth\Builtins.txt",
		@"C:\Users\ralph\OneDrive\Documents\GitHub\Z80\Unforth\Builtins.z80" 
	};
	if (2 < args.Length) {
		Console.Error.WriteLine("Supply one file path as input or nothing for pipeline processing.");
		Console.Error.WriteLine("A second argument indicates an output file.");
		Environment.ExitCode = 1;
		return;
	}
	var tr = (args.Length == 0 ? Console.In : new StreamReader(args[0]));
	var tw = (args.Length < 2 ? Console.Out : new StreamWriter(args[1]));
	var opSymbol = new Dictionary<string, string> { };
	var opHash = new Dictionary<string, int> { };
	var opTemplate = new Dictionary<string, string> { };
	var opKind = new Dictionary<string, string> { };
	int hash(string s) => s.Aggregate(0, (a, c) => 0xff & ((a << 1) + (a >> 7) + c));
	try {
		while (true) {
			var rawline = tr.ReadLine();
			var line = rawline.Trim();
			if (line == "" || line[0] == '#') continue;
			var parts = line.Split().Where(x => x != "").ToArray();
			if (parts.Length < 4) {
				Console.Error.WriteLine($"Bad line: {rawline}");
				Environment.ExitCode = 1;
				return;
			}
			var name = parts[0];
			var sym = parts[1];
			var kind = "Sym" + parts[2];
			var tplt = string.Join(" ", parts.Skip(3));
			opSymbol[name] = sym;
			opHash[name] = hash(sym);
			opKind[name] = kind;
			opTemplate[name] = tplt;
		}
	}
	catch {
		// End of file.
	}
	//opSymbol.Dump();
	//opKind.Dump();
	//opTemplate.Dump();
	
	// Write out the builtins symbol table.
	// Each entry is <hash> <length> <string addr> <kind> <template addr>.
	var ops = opSymbol.Keys.OrderBy(x => opHash[x]).ToArray();
	tw.WriteLine($"NumBuiltins equ {ops.Length}");
	tw.WriteLine($"BuiltinsHashList: db {string.Join(", ", ops.Select(x => "$" + opHash[x].ToString("x2")))}");
	tw.WriteLine($"Builtins: ; Built-ins symbol table.");
	foreach (var op in ops) {
		var sym = opSymbol[op];
		if (sym == "HEAP") tw.WriteLine("HEAPSymEntry:");
		tw.WriteLine($"    db ${hash(sym):x2}, {sym.Length} : dw Name{op,-16} : db {opKind[op],-10} : dw Tplt{op}");
	}
	tw.WriteLine($"BuiltinsTop:");
	tw.WriteLine($"    db 0 ; End of built-ins symbol table.");
	foreach (var op in ops) tw.WriteLine($"Name{op+":",-16}db \"{opSymbol[op].Replace("\\", "\\\\")}\"");
	foreach (var op in ops) tw.WriteLine($"Tplt{op+":",-16}CodeGenTemplate({{{opTemplate[op]}}})");
	tw.Flush();
}

// You can define other methods, fields, classes and namespaces here