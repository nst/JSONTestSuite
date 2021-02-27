using System;
using System.IO;
using Newtonsoft.Json;

if (args.Length != 1)
{
    Console.Error.WriteLine($"Usage: {Path.GetFileName(Environment.GetCommandLineArgs()[0])} file.json");
    return 1;
}

try
{
    using var fileStream = new FileStream(args[0], FileMode.Open);
    using var streamReader = new StreamReader(fileStream);
    using var jsonReader = new JsonTextReader(streamReader);
    try
    {
        var serializer = JsonSerializer.Create(new JsonSerializerSettings { MaxDepth = 512 });
        var result = serializer.Deserialize(jsonReader);
        Console.WriteLine(result);
        return 0;
    }
    catch (Exception e)
    {
        Console.Error.WriteLine(e);
        return 1;
    }
}
catch (Exception e)
{
    Console.Error.WriteLine(e);
    return 2;
}
