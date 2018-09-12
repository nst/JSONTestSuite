// Copyright (c) 2014-2018 Dr. Colin Hirsch and Daniel Frey
// Please see LICENSE for license or visit https://github.com/taocpp/PEGTL/

#ifndef TAO_PEGTL_INTERNAL_NOT_AT_HPP
#define TAO_PEGTL_INTERNAL_NOT_AT_HPP

#include "../config.hpp"

#include "rule_conjunction.hpp"
#include "skip_control.hpp"
#include "trivial.hpp"

#include "../apply_mode.hpp"
#include "../rewind_mode.hpp"

#include "../analysis/generic.hpp"

namespace tao
{
   namespace TAO_PEGTL_NAMESPACE
   {
      namespace internal
      {
         template< typename... Rules >
         struct not_at;

         template<>
         struct not_at<>
            : trivial< false >
         {
         };

         template< typename... Rules >
         struct not_at
         {
            using analyze_t = analysis::generic< analysis::rule_type::OPT, Rules... >;

            template< apply_mode,
                      rewind_mode,
                      template< typename... > class Action,
                      template< typename... > class Control,
                      typename Input,
                      typename... States >
            static bool match( Input& in, States&&... st )
            {
               const auto m = in.template mark< rewind_mode::REQUIRED >();
               return !rule_conjunction< Rules... >::template match< apply_mode::NOTHING, rewind_mode::ACTIVE, Action, Control >( in, st... );
            }
         };

         template< typename... Rules >
         struct skip_control< not_at< Rules... > > : std::true_type
         {
         };

      }  // namespace internal

   }  // namespace TAO_PEGTL_NAMESPACE

}  // namespace tao

#endif
