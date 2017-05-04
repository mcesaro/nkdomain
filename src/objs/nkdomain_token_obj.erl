%% -------------------------------------------------------------------
%%
%% Copyright (c) 2017 Carlos Gonzalez Florido.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc User Object

-module(nkdomain_token_obj).
-behavior(nkdomain_obj).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([create/4]).
-export([object_get_info/0, object_mapping/0, object_syntax/1,
         object_api_syntax/3, object_api_allow/4, object_api_cmd/4, object_send_event/2,
         object_sync_op/3, object_async_op/2]).

-include("nkdomain.hrl").
-include("nkdomain_debug.hrl").

-define(LLOG(Type, Txt, Args),
    lager:Type("NkDOMAIN Token "++Txt, Args)).


%% ===================================================================
%% Types
%% ===================================================================




%% ===================================================================
%% API
%% ===================================================================

%% @doc
%% Data must follow object's syntax
-spec create(nkservice:id(), nkdomain:id(), integer(), map()) ->
    {ok, nkdomain:obj_id(), nkdomain:path(), pid()} | {error, term()}.

create(Srv, Parent, SecsTTL, Data) when is_integer(SecsTTL), SecsTTL >= 1 ->
    case nkdomain_obj_lib:load(Srv, Parent, #{}) of
        #obj_id_ext{obj_id=ReferredId, type=SubType} ->
            Opts = #{
                referred_id => ReferredId,
                subtype => SubType,
                expires_time => nklib_util:m_timestamp() + 1000*SecsTTL,
                type_obj => Data
            },
            nkdomain_obj_lib:make_and_create(Srv, Parent, ?DOMAIN_TOKEN, Opts);
        {error, object_not_found} ->
            {error, referred_not_found};
        {error, Error} ->
            {error, Error}
    end.






%% ===================================================================
%% nkdomain_obj behaviour
%% ===================================================================


%% @private
object_get_info() ->
    #{
        type => ?DOMAIN_TOKEN,
        remove_after_stop => true
    }.


%% @private
object_mapping() ->
    disabled.

%% @private
object_syntax(_) ->
    any.


%% @private
object_api_syntax(_Sub, _Cmd, _Syntax) ->
    continue.


%% @private
object_api_allow(_Sub, _Cmd, _Data, State) ->
    {true, State}.


%% @private
object_send_event(_Event, Session) ->
    {ok, Session}.


%% @private
object_api_cmd(_Sub, _Cmd, _Req, _State) ->
    continue.


%% @private
object_sync_op(_Op, _From, _Session) ->
    continue.


%% @private
object_async_op(_Op, _Session) ->
    continue.


%% ===================================================================
%% Internal
%% ===================================================================