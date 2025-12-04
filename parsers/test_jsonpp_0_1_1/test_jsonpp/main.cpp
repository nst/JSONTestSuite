#include "jsonpp.hpp"

#include <string>
#include <fstream>
#include <iterator>

std::string readFile(std::string_view filename) {
    std::ifstream file(filename.data());
    if (!file.is_open()) {
        throw std::runtime_error("Could not open file");
    }
    std::string content(
        (std::istreambuf_iterator<char>(file)),
        (std::istreambuf_iterator<char>())
    );
    file.close();
    return content;
}

int main(int argc, const char **argv)
{
    using namespace JSONpp;
    char const* path = argv[1];
    auto data = readFile(path);
    try
    {
        auto j = json::parse(data);
        if (j.empty())
            return 1;
        return 0;
    } catch (const JsonException& e)
    {
        return 1;
    }
}