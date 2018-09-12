#include <tao/pegtl.hpp>
#include <tao/pegtl/contrib/json.hpp>

    int
main (int argc, char** argv)
{
    try 
    {
            tao::pegtl::file_input 
        input (argv[1]);
        tao::pegtl::parse <tao::pegtl::json::text> (input);
        return 1;
    } catch (...)
    {
        return 0;
    }
}
