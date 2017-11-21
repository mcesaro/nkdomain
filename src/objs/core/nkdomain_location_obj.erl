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

%% @doc Location Object

-module(nkdomain_location_obj).
-behavior(nkdomain_obj).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-include("nkdomain.hrl").

-export([object_info/0, object_admin_info/0, object_parse/2, object_api_syntax/2,
         object_api_cmd/2, object_send_event/2]).
-export([object_execute/5, object_schema/1, object_query/3, object_mutation/3]).
-export_type([events/0]).

-define(LLOG(Type, Txt, Args),
    lager:Type("NkDOMAIN Location "++Txt, Args)).


%% ===================================================================
%% Types
%% ===================================================================


-type events() ::
    {}.


%% ===================================================================
%% API
%% ===================================================================


%% ===================================================================
%% nkdomain_obj behaviour
%% ===================================================================


%% @private
object_info() ->
    #{
        schema_type => 'Location',
        type => ?DOMAIN_LOCATION
    }.


%% @doc
object_admin_info() ->
    #{
        class => session,
        weight => 100
    }.

%% @doc
object_schema(Type) ->
    nkdomain_location_obj_schema:object_schema(Type).


%% @doc
object_execute(Field, ObjIdExt, #{?DOMAIN_USER:=User}, Args, _Ctx) ->
    nkdomain_location_obj_schema:object_execute(Field, ObjIdExt, User, Args).


%% @doc
object_query(QueryName, Params, Ctx) ->
    nkdomain_location_obj_schema:object_query(QueryName, Params, Ctx).


%% @doc
object_mutation(MutationName, Params, Ctx) ->
    nkdomain_location_obj_schema:object_mutation(MutationName, Params, Ctx).





object_parse(_Type, _Obj) ->
    #{}.


% @private
object_api_syntax(Cmd, Syntax) ->
    nkdomain_location_obj_syntax:syntax(Cmd, Syntax).


%% @private
object_send_event(Event, State) ->
    nkdomain_location_obj_events:event(Event, State).


%% @private
object_api_cmd(Cmd, Req) ->
    nkdomain_location_obj_cmd:cmd(Cmd, Req).





%% ===================================================================
%% Internal
%% ===================================================================
