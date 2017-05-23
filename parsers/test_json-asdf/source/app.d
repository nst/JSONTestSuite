
import std.stdio;
import std.exception;

import asdf;

int main(string[] args)
{
	if(args.length < 2)
	{
		writeln("Usage: test_json-asdf <input_filname>.");
		return -1;
	}
	auto filename = args[1];
	try
	{
		auto asdf = File(filename)
			.byChunk(4096)
			.parseJson();
	}
	catch(Exception e)
	{
		return 1;
	}
	return 0;
}
