// Copyright (c) 2014-2018 Dr. Colin Hirsch and Daniel Frey
// Please see LICENSE for license or visit https://github.com/taocpp/PEGTL/

#ifndef TAO_PEGTL_INTERNAL_RULE_CONJUNCTION_HPP
#define TAO_PEGTL_INTERNAL_RULE_CONJUNCTION_HPP

#include "../apply_mode.hpp"
#include "../config.hpp"
#include "../rewind_mode.hpp"

namespace tao
{
   namespace TAO_PEGTL_NAMESPACE
   {
      namespace internal
      {
         template< typename... Rules >
         struct rule_conjunction;

         template<>
         struct rule_conjunction<>
         {
            template< apply_mode A,
                      rewind_mode M,
                      template< typename... > class Action,
                      template< typename... > class Control,
                      typename Input,
                      typename... States >
            static bool match( Input& /*unused*/, States&&... /*unused*/ ) noexcept
            {
               return true;
            }
         };

         template< typename... Rules >
         struct rule_conjunction
         {
            template< apply_mode A,
                      rewind_mode M,
                      template< typename... > class Action,
                      template< typename... > class Control,
                      typename Input,
                      typename... States >
            static bool match( Input& in, States&&... st )
            {
#ifdef __cpp_fold_expressions
               return ( Control< Rules >::template match< A, M, Action, Control >( in, st... ) && ... );
#else
               bool result = true;
               using swallow = bool[];
               (void)swallow{ result = result && Control< Rules >::template match< A, M, Action, Control >( in, st... )... };
               return result;
#endif
            }
         };

      }  // namespace internal

   }  // namespace TAO_PEGTL_NAMESPACE

}  // namespace tao

#endif
