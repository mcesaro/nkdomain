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

%% @doc NkDomain service callback module
-module(nkdomain_callbacks).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').
-export([plugin_deps/0, service_init/2, service_handle_cast/2]).
-export([object_base_mapping/0, object_base_syntax/0]).
-export([object_load/2, object_save/2, object_remove/2, object_parse/3, object_store/2,
         object_updated/3, object_enabled/3]).
-export([object_init/2, object_terminate/3, object_event/3, object_reg_event/4,
         object_reg_down/4, object_start/2, object_stop/3,
         object_handle_call/4, object_handle_cast/3, object_handle_info/3]).
-export([object_store_reload_types/1, object_store_read_raw/2, object_store_save_raw/3,
         object_store_remove_raw/2, object_store_find_path/2, object_store_find_childs/3]).

-define(LLOG(Type, Txt, Args), lager:Type("NkDOMAIN Callbacks: "++Txt, Args)).

-include("nkdomain.hrl").


%% ===================================================================
%% Types
%% ===================================================================

-type continue() :: continue | {continue, list()}.


%% ===================================================================
%% Offered Object Callbacks
%% ===================================================================

-type type() :: nkdomain:type().
-type session() :: nkdomain_obj:session().


%% @doc In-store base mapping
-spec object_base_mapping() -> map().

object_base_mapping() ->
    #{
        type => #{type => keyword},
        obj_id => #{type => keyword},
        path => #{type => keyword},
        parent_id => #{type => keyword},
        subtype => #{type => keyword},
        description => #{
            type => text,
            fields => #{keyword => #{type=>keyword}}
        },
        created_by => #{type => keyword},
        created_time => #{type => date},
        enabled => #{type => boolean},
        expires_time => #{type => date},
        destroyed_time => #{type => date},
        destroyed_reason => #{type => keyword},
        aliases => #{type => keyword},
        icon_id => #{type => keyword}
    }.


%% @doc Base syntax
-spec object_base_syntax() -> nklib_syntax:syntax().

object_base_syntax() ->
    #{
        type => atom,
        obj_id => binary,
        path => binary,
        parent_id => binary,
        subtype => binary,
        description => binary,
        created_by => binary,
        created_time => integer,
        parent_id => binary,
        enabled => boolean,
        expires_time => integer,
        destroyed_time => integer,
        destroyed_reason => binary,
        aliases => {list, binary},
        icon_id => binary,
        '_store_vsn' => any,
        '__mandatory' => [type, obj_id, path, parent_id, created_time]
    }.



%% @doc Called to parse an object's syntax
-spec object_load(nkdomain:obj_id(), session()) ->
    {ok, nkdomain:obj()} | {error, term()}.

object_load(ObjId, #{srv_id:=SrvId}=Session) ->
    case SrvId:object_store_read_raw(SrvId, ObjId) of
        {ok, Type, Store} ->
            SrvId:object_parse(Type, Store, Session);
        {error, Error} ->
            {error, Error}
    end.


%% @doc Called to save the object to disk
-spec object_save(type(), session()) ->
    {ok, session()} | {error, term(), session()}.

object_save(Type, #{srv_id:=SrvId, obj_id:=ObjId, obj:=Obj}=Session) ->
    BaseKeys = maps:keys(SrvId:object_base_mapping()),
    Store1 = maps:with(BaseKeys, Obj),
    Store2 = SrvId:object_store(Type, Session),
    Store3 = maps:merge(Store1, Store2),
    case SrvId:object_store_save_raw(SrvId, ObjId, Store3) of
        {ok, _Vsn} ->
            {ok, ?ADD_TO_SESSION(is_dirty, false, Session)};
        {error, Error} ->
            {error, Error, Session}
    end.


%% @doc Called to save the object to disk
-spec object_remove(type(), session()) ->
    {ok, session()} | {error, term(), session()}.

object_remove(_Type, #{srv_id:=SrvId, obj_id:=ObjId}=Session) ->
    case SrvId:object_store_remove_raw(SrvId, ObjId) of
        ok ->
            {ok, Session};
        {error, Error} ->
            {error, Error, Session}
    end.


%% @doc Called to parse an object's syntax
-spec object_parse(nkdomain:type(), map(), session()) ->
    {ok, nkdomain:obj()} | {error, term()}.

object_parse(Type, Obj, #{srv_id:=SrvId}) ->
    Base = SrvId:object_base_syntax(),
    Syntax = Type:object_get_syntax(),
    case nklib_syntax:parse(Obj, maps:merge(Base, Syntax), #{}) of
        {ok, #{type:=Type}=Obj2, _Exp, []} ->
            {ok, Obj2};
        {ok, #{type:=Type, obj_id:=ObjId}=Obj2, _Exp, Missing} ->
            ?LLOG(notice, "Object ~s (~s) has unknown fields: ~p", [Type, ObjId, Missing]),
            {ok, Obj2};
        {error, Error} ->
            {error, Error}
    end.


%% @doc Called to get a "storable" version of the object
-spec object_store(type(), nkdomain:obj()) -> map().

object_store(Type, #{obj:=Obj}) ->
    Type:object_store(Obj);

object_store(_Type, _Session) ->
    #{}.


%% @doc Called when an object is modified
-spec object_updated(map(), type(), session()) ->
    {ok, session()}.

object_updated(_Update, _Type, Session) ->
    {ok, Session}.


%% @doc Called when an object is enabled or disabled
-spec object_enabled(boolean(), type(), session()) ->
    {ok, session()}.

object_enabled(_Enabled, _Type, Session) ->
    {ok, Session}.


%% @doc Called when a new session starts
-spec object_init(type(), session()) ->
    {ok, session()} | {stop, Reason::term()}.

object_init(_Type, Session) ->
    {ok, Session}.


%% @doc Called when the session stops
-spec object_terminate(type(), Reason::term(), session()) ->
    {ok, session()}.

object_terminate(_Type, _Reason, Session) ->
    {ok, Session}.


%% @private
-spec object_start(type(), session()) ->
    {ok, session()} | continue().

object_start(_Type, Session) ->
    {ok, Session}.


%% @private
-spec object_stop(type(), nkservice:error(), session()) ->
    {ok, session()} | continue().

object_stop(_Type, _Reason, Session) ->
    {ok, Session}.


%%  @doc Called when an event is sent
-spec object_event(type(), nkdomain_obj:event(), session()) ->
    {ok, session()} | continue().

object_event(_Type, _Event, Session) ->
    {ok, Session}.


%% @doc Called when an event is sent, for each registered process to the session
-spec object_reg_event(type(), nklib:link(), nkdomain_obj:event(), session()) ->
    {ok, session()} | continue().

object_reg_event(_Type, _Link, _Event, Session) ->
    {ok, Session}.


%% @doc Called when a registered process fails
-spec object_reg_down(type(), nklib:link(), term(), session()) ->
    {ok, session()} | {stop, Reason::term(), session()} | continue().

object_reg_down(_Type, _Link, _Reason, Session) ->
    {stop, registered_down, Session}.


%% @doc
-spec object_handle_call(type(), term(), {pid(), term()}, session()) ->
    {reply, term(), session()} | {noreply, session()} | continue().

object_handle_call(_Type, Msg, _From, Session) ->
    lager:error("Module nkdomain_obj received unexpected call: ~p", [Msg]),
    {noreply, Session}.


%% @doc
-spec object_handle_cast(type(), term(), session()) ->
    {noreply, session()} | continue().

object_handle_cast(_Type, Msg, Session) ->
    lager:error("Module nkdomain_obj received unexpected cast: ~p", [Msg]),
    {noreply, Session}.


%% @doc
-spec object_handle_info(type(), term(), session()) ->
    {noreply, session()} | continue().

object_handle_info(_Type, Msg, Session) ->
    lager:warning("Module nkdomain_obj received unexpected info: ~p", [Msg]),
    {noreply, Session}.


%% ===================================================================
%% Offered Object Store Callbacks
%% ===================================================================


%% @doc
-spec object_store_reload_types(nkservice:id()) ->
    ok | {error, term()}.

object_store_reload_types(_SrvId) ->
    {error, store_not_implemented}.


%% @doc
-spec object_store_read_raw(nkservice:id(), nkdomain:obj_id()) ->
    {ok, nkdomain:type(), map()} | {error, term()}.

object_store_read_raw(_SrvId, _ObjId) ->
    {error, store_not_implemented}.


%% @doc
-spec object_store_save_raw(nkservice:id(), nkdomain:obj_id(), map()) ->
    {ok, Vsn::term()} | {error, term()}.

object_store_save_raw(_SrvId, _ObjId, _Map) ->
    {error, store_not_implemented}.


%% @doc
-spec object_store_remove_raw(nkservice:id(), nkdomain:obj_id()) ->
    ok | {error, term()}.

object_store_remove_raw(_SrvId, _ObjId) ->
    {error, store_not_implemented}.


%% @doc
-spec object_store_find_path(nkservice:id(), nkdomain:path()) ->
    {ok, nkdomain:type(), nkdomain:obj_id()} | {error, term()}.

object_store_find_path(_SrvId, _Path) ->
    {error, store_not_implemented}.


%% @doc
-spec object_store_find_childs(nkservice:id(), nkdomain:path(), Spec::map()) ->
    {ok, Total::integer(), [{nkdomain:type(), nkdomain:obj_id()}]} |
    {error, term()}.

object_store_find_childs(_SrvId, _Path, _Spec) ->
    {error, store_not_implemented}.




%% ===================================================================
%% Plugin callbacks
%% ===================================================================

%% @private
plugin_deps() ->
    [nkelastic].


%% @private
service_init(_Service, State) ->
    gen_server:cast(self(), nkdomain_load_domain),
    {ok, State}.


%% @private
service_handle_cast(nkdomain_load_domain, State) ->
    {noreply, State};

service_handle_cast(_Msg, _State) ->
    continue.

