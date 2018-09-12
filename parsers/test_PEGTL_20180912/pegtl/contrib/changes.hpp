// Copyright (c) 2015-2018 Dr. Colin Hirsch and Daniel Frey
// Please see LICENSE for license or visit https://github.com/taocpp/PEGTL/

#ifndef TAO_PEGTL_CONTRIB_CHANGES_HPP
#define TAO_PEGTL_CONTRIB_CHANGES_HPP

#include "../config.hpp"
#include "../normal.hpp"

#include "../internal/conditional.hpp"

namespace tao
{
   namespace TAO_PEGTL_NAMESPACE
   {
      namespace internal
      {
         struct dummy_disabled_state
         {
            template< typename... Ts >
            void success( Ts&&... /*unused*/ ) const noexcept
            {
            }
         };

         template< apply_mode A, typename State >
         using state_disable_helper = typename conditional< A == apply_mode::ACTION >::template type< State, dummy_disabled_state >;

      }  // namespace internal

      template< typename Rule, typename State, template< typename... > class Base = normal >
      struct change_state
         : public Base< Rule >
      {
         template< apply_mode A,
                   rewind_mode M,
                   template< typename... > class Action,
                   template< typename... > class Control,
                   typename Input,
                   typename... States >
         static bool match( Input& in, States&&... st )
         {
            internal::state_disable_helper< A, State > s;

            if( Base< Rule >::template match< A, M, Action, Control >( in, s ) ) {
               s.success( st... );
               return true;
            }
            return false;
         }
      };

      template< typename Rule, template< typename... > class Action, template< typename... > class Base = normal >
      struct change_action
         : public Base< Rule >
      {
         template< apply_mode A,
                   rewind_mode M,
                   template< typename... > class,
                   template< typename... > class Control,
                   typename Input,
                   typename... States >
         static bool match( Input& in, States&&... st )
         {
            return Base< Rule >::template match< A, M, Action, Control >( in, st... );
         }
      };

      template< template< typename... > class Action, template< typename... > class Base >
      struct change_both_helper
      {
         template< typename T >
         using change_action = change_action< T, Action, Base >;
      };

      template< typename Rule, typename State, template< typename... > class Action, template< typename... > class Base = normal >
      struct change_state_and_action
         : public change_state< Rule, State, change_both_helper< Action, Base >::template change_action >
      {
      };

   }  // namespace TAO_PEGTL_NAMESPACE

}  // namespace tao

#endif
