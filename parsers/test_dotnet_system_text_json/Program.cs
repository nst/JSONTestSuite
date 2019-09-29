using System;
using System.IO;
using System.Text.Json;

internal class Program
{
    private static readonly JsonDocumentOptions s_options =
        new JsonDocumentOptions
        {
            CommentHandling = JsonCommentHandling.Disallow,
            MaxDepth = 500
        };

    private static bool IsValidJsonFile(string path)
    {
        try
        {
            using var stream = File.Open(path, FileMode.Open, FileAccess.Read);
            JsonDocument.Parse(stream, s_options);
            return true;
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
        }

        return false;
    }

    public static int Main(string[] args)
    {
        if (args.Length == 0)
        {
            Console.WriteLine("Usage: app path/to/file.json");
            return 2;
        }

        if (!File.Exists(args[0]))
        {
            Console.WriteLine("File '{0}' was not found.", args[0]);
            return 2;
        }

        if (!IsValidJsonFile(args[0]))
        {
            Console.WriteLine("invalid");
            return 1;
        }

        Console.WriteLine("valid");
        return 0;
    }
}
