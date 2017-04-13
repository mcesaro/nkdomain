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

-ifndef(NKDOMAIN_HRL_).
-define(NKDOMAIN_HRL_, 1).

%% ===================================================================
%% Defines
%% ===================================================================

-define(ADD_TO_OBJ(Key, Val, Obj), maps:put(Key, Val, Obj)).
-define(ADD_TO_OBJ(Update, Obj), maps:merge(Obj, Update)).
-define(ADD_TO_OBJ_DEEP(Update, Obj), nklib_syntax:map_merge(Update, Obj)).
-define(REMOVE_FROM_OBJ(Key, Obj), maps:remove(Key, Obj)).

-record(obj_session, {
    type :: binary(),
    obj_id :: nkdomain:obj_id(),
    path :: nkdomain:path(),
    module :: module(),
    parent_id :: nkdomain:obj_id(),
    obj :: nkdomain:obj(),
    srv_id :: nkservice:id(),
    is_dirty :: boolean(),
    is_enabled :: boolean(),
    is_created :: boolean(),
    status :: nkdomain_obj:status(),
    meta :: map(),                      % Object load metadata
    data :: term(),                     % Type-specific metadata
    started :: nklib_util:m_timestamp(),
    childs :: #{nkdomain:type() => #{nkdomain:name() => {nkdomain:obj_id(), pid()}}},
    links :: nklib_links:links()
}).

-record(obj_id_ext, {
    srv_id :: nkservice:id(),
    type :: nkdomain:type(),
    obj_id :: nkdomain:obj_id(),
    path :: nkdomain:path(),
    pid :: pid() | undefined
}).




-define(DOMAIN_USER, <<"user">>).
-define(DOMAIN_USER_ATOM, 'user').
-define(DOMAIN_DOMAIN, <<"domain">>).
-define(DOMAIN_DOMAIN_ATOM, 'domain').
-define(DOMAIN_SESSION, <<"session">>).
-define(DOMAIN_SESSION_ATOM, 'session').
-define(DOMAIN_TOKEN, <<"token">>).
-define(DOMAIN_TOKEN_ATOM, 'token').
-define(DOMAIN_CONFIG, <<"config">>).
-define(DOMAIN_CONFIG_ATOM, 'config').

-endif.

