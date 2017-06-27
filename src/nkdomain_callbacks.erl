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
-export([error/1]).
-export([object_apply/3]).

-export([nkservice_rest_http/5]).
-export([admin_tree_categories/2, admin_tree_get_category/2, admin_event/3,
         admin_element_action/5, admin_get_data/3]).
-export([object_admin_info/1, object_get_counter/3]).
-export([object_create/5, object_check_active/3, object_do_expired/2]).
-export([object_syntax/1, object_parse/3]).
-export([object_init/1, object_terminate/2, object_stop/2,
         object_event/2, object_reg_event/3, object_sync_op/3, object_async_op/2,
         object_save/1, object_delete/1, object_archive/1, object_link_down/2,
         object_handle_call/3, object_handle_cast/2, object_handle_info/2]).
-export([object_db_init/1, object_db_read/2, object_db_save/2, object_db_delete/2]).
-export([object_db_find_obj/2, object_db_search/2, object_db_search_alias/2,
         object_db_search_types/3, object_db_search_all_types/3,
         object_db_search_childs/3, object_db_search_all_childs/3,
         object_db_delete_all_childs/3, object_db_clean/1]).
-export([plugin_deps/0, plugin_syntax/0, plugin_config/2]).
-export([service_api_syntax/2, service_api_allow/2, service_api_cmd/2]).
-export([api_server_http_auth/2, api_server_reg_down/3]).
-export([service_init/2, service_handle_cast/2, service_handle_info/2]).


-define(LLOG(Type, Txt, Args), lager:Type("NkDOMAIN Callbacks: "++Txt, Args)).

-include("nkdomain.hrl").
-include_lib("nkapi/include/nkapi.hrl").
-include_lib("nkevent/include/nkevent.hrl").
-include_lib("nkservice/include/nkservice.hrl").


%% ===================================================================
%% Types
%% ===================================================================

-type obj_id() :: nkdomain:obj_id().
-type type() :: nkdomain:type().
-type path() :: nkdomain:path().
-type srv_id() :: nkservice:id().
-type continue() :: continue | {continue, list()}.
-type state() :: #?STATE{}.


%% ===================================================================
%% Errors
%% ===================================================================

%% @doc
error({body_too_large, Size, Max})      -> {"Body too large (size is ~p, max is ~p)", [Size, Max]};
error({could_not_load_parent, Id})      -> {"Object could not load parent '~s'", [Id]};
error({could_not_load_domain, Id})      -> {"Object could not load domain '~s'", [Id]};
error(domain_unknown)                   -> "Unknown domain";
error({domain_unknown, D})              -> {"Unknown domain '~s'", [D]};
error({email_duplicated, E})            -> {"Duplicated email '~s'", [E]};
error({file_not_found, F})              -> {"File '~s' not found", [F]};
error(invalid_content_type)             -> "Invalid Content-Type";
error({invalid_name, N})                -> {"Invalid name '~s'", [N]};
error(invalid_object_id)                -> "Invalid object id";
error(invalid_object_type)              -> "Invalid object type";
error(invalid_object_path)              -> "Invalid object path";
error({invalid_object_path, P})         -> {"Invalid object path '~s'", [P]};
error(invalid_sessionn)                 -> "Invalid session";
error({invalid_type, T})                -> {"Invalid type '~s'", [T]};
error(invalid_token)                    -> "Invalid token";
error(invalid_token_ttl)                -> "Invalid token TTL";
error(member_already_present)           -> "Member is already present";
error(member_not_found)                 -> "Member not found";
error(member_invalid)                   -> "Invalid member";
error(missing_auth_header)              -> "Missing authentication header";
error({module_failed, Module})          -> {"Module '~s' failed", [Module]};
error(object_already_exists)            -> "Object already exists";
error(object_clean_process)             -> "Object cleaned (process stopped)";
error(object_clean_expire)              -> "Object cleaned (expired)";
error(object_deleted) 		            -> "Object removed";
error(object_expired) 		            -> "Object expired";
error(object_has_childs) 		        -> "Object has childs";
error({object_load_error, Error}) 		-> {"Object load error: '~p'", [Error]};
error(object_is_already_loaded)         -> "Object is already loaded";
error(object_is_disabled) 		        -> "Object is disabled";
error(object_is_stopped) 		        -> "Object is stopped";
error(object_not_found) 		        -> "Object not found";
error(object_not_started) 		        -> "Object is not started";
error(object_parent_conflict) 	        -> "Object has conflicting parent";
error(object_stopped) 		            -> "Object stopped";
error(parent_not_found) 		        -> "Parent not found";
error(parent_stopped) 		            -> "Parent stopped";
error(parse_error)   		            -> "Object parse error";
error(service_down)                     -> "Service is down";
error(session_already_present)          -> "Session is already present";
error(session_not_found)                -> "Session not found";
error(session_is_disabled)              -> "Session is disabled";
error(session_type_unsupported)         -> "Session type not supported";
error(store_id_invalid)                 -> "Invalid Store Id";
error(store_id_missing)                 -> "Missing Store Id";
error(user_is_disabled) 		        -> "User is disabled";
error(user_unknown)                     -> "Unknown user";

error(db_not_defined)                   -> "Object database not defined";


error(_)   		                        -> continue.




%% ===================================================================
%% Admin
%% ===================================================================


%% @private
admin_tree_categories(Data, Session) ->
    nkdomain_admin_tree:categories(Data, Session).


%% @doc
admin_tree_get_category(Category, Session) ->
    nkdomain_admin_tree:get_category(Category, Session).


%% @doc
admin_event(#nkevent{class = ?DOMAIN_EVENT_CLASS}=Event, Updates, Session) ->
    nkdomain_admin_tree:event(Event, Updates, Session);

admin_event(_Event, _Updates, _Session) ->
    continue.


%% @doc
admin_element_action(ElementId, Action, Value, Updates, Session) ->
    nkdomain_admin_tree:element_action(ElementId, Action, Value, Updates, Session).


%% @doc
admin_get_data(ElementId, Spec, Session) ->
    nkdomain_admin_detail:get_data(ElementId, Spec, Session).


%% ===================================================================
%% REST
%% ===================================================================


%% @doc
nkservice_rest_http(SrvId, get, [<<"_file">>, FileId], Req, State) ->
    case nkdomain_file_obj:http_get(SrvId, FileId, Req) of
        {ok, CT, Bin} ->
            {http, 200, [{<<"Content-Type">>, CT}], Bin, State};
        {error, Error} ->
            nkservice_rest_http:reply_json({error, Error}, Req, State)
    end;

nkservice_rest_http(SrvId, post, File, Req, State) ->
    case lists:reverse(File) of
        [<<"_file">>|Rest] ->
            Domain = nklib_util:bjoin(lists:reverse(Rest), <<"/">>),
            case nkdomain_file_obj:http_post(SrvId, Domain, Req) of
                {ok, #obj_id_ext{obj_id=ObjId, path=Path}, _Unknown} ->
                    Reply = #{obj_id=>ObjId, path=>Path},
                    nkservice_rest_http:reply_json({ok, Reply}, Req, State);
                {error, Error} ->
                    nkservice_rest_http:reply_json({error, Error}, Req, State)
            end;
        _ ->
            continue
    end;

nkservice_rest_http(_SrvId, _Method, _Path, _Req, _State) ->
    continue.



%% ===================================================================
%% Offered Object Callbacks
%% ===================================================================


%% @doc Object syntax
-spec object_syntax(load|update) -> nklib_syntax:syntax().

object_syntax(load) ->
    #{
        obj_id => binary,
        type => binary,
        path => binary,
        domain_id => binary,
        parent_id => binary,
        subtype => {list, binary},
        created_by => binary,
        created_time => integer,
        updated_by => binary,
        updated_time => integer,
        enabled => boolean,
        active => boolean,                    % Must be loaded to exist
        expires_time => integer,
        destroyed => boolean,
        destroyed_time => integer,
        destroyed_code => binary,
        destroyed_reason => binary,
        name => binary,
        description => binary,
        tags => {list, binary},
        aliases => {list, binary},
        icon_id => binary,
        icon_content_type => binary,
        '_store_vsn' => any,
        '__mandatory' => [type, obj_id, domain_id, path, created_time]
    };

object_syntax(update) ->
    #{
        type => ignore,             % Do not count as unknown is updates
        enabled => boolean,
        name => binary,
        description => binary,
        tags => {list, binary},
        aliases => {list, binary},
        icon_id => binary,
        icon_content_type => binary
    };

object_syntax(create) ->
    Base = (object_syntax(load))#{'__mandatory':=[]},
    Base#{obj_name => binary}.


%% ===================================================================
%% External module calling and utilities
%% ===================================================================

%% @doc Calls an object's function
-spec object_apply(nkdomain:type()|module(), atom(), list()) ->
    not_exported | term().

object_apply(Module, Fun, Args) when is_atom(Module) ->
    case erlang:function_exported(Module, Fun, length(Args)) of
        true ->
            apply(Module, Fun, Args);
        false ->
            not_exported
    end;

object_apply(Type, Fun, Args) ->
    Module = nkdomain_all_types:get_module(Type),
    true = is_atom(Module),
    object_apply(Module, Fun, Args).


%% @doc Creates a new object (called from API)
-spec object_create(nkservice:id(), nkdomain:id(), nkdomain:type(), nkdomain:id(), map()) ->
    {ok, #obj_id_ext{}, [Unknown::binary()]} | {error, term()}.

object_create(SrvId, DomainId, Type, UserId, Obj) ->
    case nkdomain_all_types:get_module(Type) of
        undefined ->
            {error, unknown_type};
        Module ->
            Obj2 = Obj#{
                type => Type,
                created_by => UserId,
                domain_id => DomainId
            },
            case erlang:function_exported(Module, object_create, 2) of
                true ->
                    case SrvId:object_parse(SrvId, create, Obj2) of
                        {ok, Obj3, _} ->
                            Module:object_create(SrvId, Obj3);
                        {error, Error} ->
                            {error, Error}
                    end;
                false ->
                    nkdomain_obj_make:create(SrvId, Obj2)
            end
    end.


%% @doc Called to parse an object's syntax from a map
-spec object_parse(srv_id(), load|update, map()) ->
    {ok, nkdomain:obj(), Unknown::[binary()]} | {error, term()}.

object_parse(SrvId, Mode, Map) ->
    Type = case Map of
        #{<<"type">>:=Type0} -> Type0;
        #{type:=Type0} -> Type0;
        _ -> <<>>
    end,
    SynOpts = #{domain_srv_id=>SrvId, domain_mode=> Mode},
    case nkdomain_all_types:get_module(Type) of
        undefined ->
            {error, {invalid_type, Type}};
        Module ->
            UserMode = case Mode of
                create -> load;
                load -> load;
                update -> update
            end,
            case Module:object_parse(SrvId, UserMode, Map) of
                {ok, Obj2, UnknownFields} ->
                    {ok, Obj2, UnknownFields};
                {error, Error} ->
                    {error, Error};
                {type_obj, TypeObj, UnknownFields1} ->
                    BaseSyn = SrvId:object_syntax(Mode),
                    case nklib_syntax:parse(Map, BaseSyn#{Type=>ignore}, SynOpts) of
                        {ok, Obj, UnknownFields2} ->
                            {ok, Obj#{Type=>TypeObj}, UnknownFields1++UnknownFields2};
                        {error, Error} ->
                            {error, Error}
                    end;
                Syntax when Syntax==any; is_map(Syntax) ->
                    BaseSyn = SrvId:object_syntax(Mode),
                    nklib_syntax:parse(Map, BaseSyn#{Type=>Syntax}, SynOpts)
            end
    end.


%% @doc Called if an active object is detected on storage
%% If 'true' is returned, the object is ok
%% If 'false' is returned, it only means that the object has been processed
-spec object_check_active(srv_id(), type(), obj_id()) ->
    boolean().

object_check_active(SrvId, Type, ObjId) ->
    case nkdomain_obj_util:call_type(object_check_active, [SrvId, ObjId], Type) of
        ok -> true;
        true -> true;
        false -> false
    end.


%% @doc Called if an object is over its expired time
-spec object_do_expired(srv_id(), obj_id()) ->
    any().

object_do_expired(_SrvId, ObjId) ->
    lager:notice("NkDOMAIN: removing expired object ~s", [ObjId]),
    ok.
%%    nkdomain:archive(SrvId, ObjId, object_clean_expire).


%% @doc
-spec object_admin_info(nkdomain:type()) ->
    nkdomain_admin:object_admin_info().

object_admin_info(Type) ->
    Module = nkdomain_all_types:get_module(Type),
    case erlang:function_exported(Module, object_admin_info, 0) of
        true ->
            Module:object_admin_info();
        false ->
            #{}
    end.


%% @doc
-spec object_get_counter(nkservice:id(), nkdomain:type(), nkdomain:path()) ->
    {ok, integer()}.

object_get_counter(SrvId, Type, DomainPath) ->
    Module = nkdomain_all_types:get_module(Type),
    nkdomain_type:get_counter(SrvId, Module, DomainPath).


%% ===================================================================
%% Object-process related callbacks
%% ===================================================================


%% @doc Called when a new session starts
-spec object_init(state()) ->
    {ok, state()} | {stop, Reason::term()}.

object_init(State) ->
    call_module(object_init, [], State).


%% @doc Called when the session stops
-spec object_terminate(Reason::term(), state()) ->
    {ok, state()}.

object_terminate(Reason, State) ->
    call_module(object_terminate, [Reason], State).


%%%% @private
%%-spec object_start(state()) ->
%%    {ok, state()} | continue().
%%
%%object_start(State) ->
%%    call_module(object_start, [], State).


%% @private
-spec object_stop(nkservice:error(), state()) ->
    {ok, state()} | continue().

object_stop(Reason, State) ->
    call_module(object_stop, [Reason], State).


%%  @doc Called to send an event
-spec object_event(nkdomain_obj:event(), state()) ->
    {ok, state()} | continue().

object_event(Event, State) ->
    % The object module can use this callback to detect core events or its own events
    {ok, State2} = call_module(object_event, [Event], State),
    % Use this callback to generate the right external Event
    case call_module(object_send_event, [Event], State2) of
        {ok, State3} ->
            case nkdomain_obj_events:event(Event, State3) of
                {ok, State4} ->
                    {ok, State4};
                {event, Type, Body, State4} ->
                    nkdomain_obj_util:send_event(Type, Body, State4);
                {event, Type, ObjId, Body, State4} ->
                    nkdomain_obj_util:send_event(Type, ObjId, Body, State4);
                {event, Type, ObjId, Path, Body, State4} ->
                    nkdomain_obj_util:send_event(Type, ObjId, Path, Body, State4)
            end;
        {event, Type, Body, State3} ->
            nkdomain_obj_util:send_event(Type, Body, State3);
        {event, Type, ObjId, Body, State3} ->
            nkdomain_obj_util:send_event(Type, ObjId, Body, State3);
        {event, Type, ObjId, Path, Body, State3} ->
            nkdomain_obj_util:send_event(Type, ObjId, Path, Body, State3);
        {ignore, State3} ->
            {ok, State3}
    end.


%% @doc Called when an event is sent, for each registered process to the session
-spec object_reg_event(nklib:link(), nkdomain_obj:event(), state()) ->
    {ok, state()} | continue().

object_reg_event(Link, Event, State) ->
    call_module(object_reg_event, [Link, Event], State).


%% @doc
-spec object_sync_op(term(), {pid(), reference()}, state()) ->
    {reply, Reply::term(), session} | {reply_and_save, Reply::term(), session} |
    {noreply, state()} | {noreply_and_save, session} |
    {stop, Reason::term(), Reply::term(), state()} |
    {stop, Reason::term(), state()} |
    continue().

object_sync_op(Op, From, State) ->
    case call_module(object_sync_op, [Op, From], State) of
        {ok, State2} ->
            % It is probably not exported
            {continue, [Op, From, State2]};
        Other ->
            Other
    end.


%% @doc
-spec object_async_op(term(), state()) ->
    {noreply, state()} | {noreply_and_save, session} |
    {stop, Reason::term(), state()} |
    continue().

object_async_op(Op, State) ->
    case call_module(object_async_op, [Op], State) of
        {ok, State2} ->
            % It is probably not exported
            {continue, [Op, State2]};
        Other ->
            Other
    end.



%% @doc Called to save the object to disk
-spec object_save(state()) ->
    {ok, state(), Meta::map()} | {error, term(), state()}.

object_save(#?STATE{is_dirty=false}=State) ->
    {ok, State};

object_save(#?STATE{srv_id=SrvId}=State) ->
    %{ok, State2} = call_module(object_restore, [], State),
    case call_module(object_save, [], State) of
        {ok, #?STATE{obj=Obj2}=State2} ->
            case SrvId:object_db_save(SrvId, Obj2) of
                {ok, Meta} ->
                    {ok, State2#?STATE{is_dirty=false}, Meta};
                {error, Error} ->
                    {error, Error, State2}
            end;
        {error, Error} ->
            {error, Error, State}
    end.


%% @doc Called to save the remove the object from disk
-spec object_delete(state()) ->
    {ok, state(), Meta::map()} | {error, term(), state()}.

object_delete(#?STATE{srv_id=SrvId, id=#obj_id_ext{obj_id=ObjId}}=State) ->
    case call_module(object_delete, [], State) of
        {ok, State2} ->
            case SrvId:object_db_delete(SrvId, ObjId) of
                {ok, Meta} ->
                    {ok, State2, Meta};
                {error, Error} ->
                    {error, Error, State2}
            end;
        {error, Error} ->
            {error, Error, State}
    end.


%% @doc Called to save the archived version to disk
-spec object_archive(state()) ->
    {ok, state()} | {error, term(), state()}.

object_archive(#?STATE{srv_id=_SrvId}=State) ->
    {ok, State}.

%%    {ok, State2} = call_module(object_restore, [], State),
%%    case call_module(object_archive, [], State2) of
%%        {ok, State3} ->
%%            Map = SrvId:object_unparse(State3#?STATE{obj=Obj}),
%%            case nkdomain_store:archive(SrvId, ObjId, Map) of
%%                ok ->
%%                    {ok, State3};
%%                {error, Error} ->
%%                    {error, Error, State3}
%%            end;
%%        {error, Error} ->
%%            {error, Error, State2}
%%    end.

%% @doc Called when a linked process goes down
-spec object_link_down(event|{child, nkdomain:obj_id()}|{usage, nklib_links:link()}, state()) ->
    {ok, state()}.

object_link_down(Link, State) ->
    call_module(object_link_down, [Link], State).


%% @doc
-spec object_handle_call(term(), {pid(), term()}, state()) ->
    {reply, term(), state()} | {noreply, state()} |
    {stop, term(), term(), state()} | {stop, term(), state()} | continue.

object_handle_call(Msg, From, State) ->
    case call_module(object_handle_call, [Msg, From], State) of
        {ok, State2} ->
            lager:error("Module nkdomain_obj received unexpected call: ~p", [Msg]),
            {noreply, State2};
        Other ->
            Other
    end.


%% @doc
-spec object_handle_cast(term(), state()) ->
    {noreply, state()} | {stop, term(), state()} | continue.

object_handle_cast(Msg, State) ->
    case call_module(object_handle_cast, [Msg], State) of
        {ok, State2} ->
            lager:error("Module nkdomain_obj received unexpected cast: ~p", [Msg]),
            {noreply, State2};
        Other ->
            Other
    end.


%% @doc
-spec object_handle_info(term(), state()) ->
    {noreply, state()} | {stop, term(), state()} | continue.

object_handle_info(Msg, State) ->
    case call_module(object_handle_info, [Msg], State) of
        {ok, State2} ->
            lager:warning("Module nkdomain_obj received unexpected info: ~p", [Msg]),
            {noreply, State2};
        Other ->
            Other
    end.



%% ===================================================================
%% DB Management
%% ===================================================================


%% @doc Called to initialize the database
-spec object_db_init(nkservice:service()) ->
    {ok, nkservice:service()}| {error, term()}.

object_db_init(_State) ->
    {error, db_not_defined}.


%% @doc Reads and parses object from database, using ObjId
-spec object_db_read(srv_id(), obj_id()) ->
    {ok, nkdomain:obj(), Meta::map()} | {error, term()}.

object_db_read(_SrvId, _ObjId) ->
    {error, db_not_defined}.


%% @doc Saves an object to database
-spec object_db_save(nkservice:id(), nkdomain:obj()) ->
    {ok, Meta::map()} | {error, term()}.

object_db_save(_SrvId, _Obj) ->
    {error, db_not_defined}.


%% @doc Deletes an object from database
-spec object_db_delete(nkservice:id(), nkdomain:obj_id()) ->
    {ok, Meta::map()} | {error, term()}.

object_db_delete(_SrvId, _ObjId) ->
    {error, db_not_defined}.



%% @doc Finds an object from its ID or Path
-spec object_db_find_obj(nkservice:id(), nkdomain:id()) ->
    {ok, nkdomain:type(), nkdomain:obj_id(), nkdomain:path()} | {error, object_not_found|term()}.

object_db_find_obj(_SrvId, _ObjId) ->
    {error, db_not_defined}.


%% @doc
-spec object_db_search_types(srv_id(), obj_id(), nkdomain:search_spec()) ->
    {ok, Total::integer(), [{type(), integer()}]} | {error, term()}.

object_db_search_types(_SrvId, _ObjId, _Spec) ->
    {error, db_not_defined}.


%% @doc
-spec object_db_search_all_types(srv_id(), path(), nkdomain:search_spec()) ->
    {ok, Total::integer(), [{type(), integer()}]} | {error, term()}.

object_db_search_all_types(_SrvId, _ObjId, _Spec) ->
    {error, db_not_defined}.


%% @doc
-spec object_db_search_childs(srv_id(), obj_id(), nkdomain:search_spec()) ->
    {ok, Total::integer(), [{type(), obj_id(), path()}]} |
    {error, term()}.

object_db_search_childs(_SrvId, _ObjId, _Spec) ->
    {error, db_not_defined}.


%% @doc
-spec object_db_search_all_childs(srv_id(), path(), nkdomain:search_spec()) ->
    {ok, Total::integer(), [{type(), obj_id(), path()}]} |
    {error, term()}.

object_db_search_all_childs(_SrvId, _Path, _Spec) ->
    {error, db_not_defined}.


%% @doc
-spec object_db_search_alias(srv_id(), nkdomain:alias()) ->
    {ok, Total::integer(), [{type(), obj_id(), path()}]} |
    {error, term()}.

object_db_search_alias(_SrvId, _Alias) ->
    {error, db_not_defined}.


%% @doc
-spec object_db_search(srv_id(), nkdomain:search_spec()) ->
    {ok, Total::integer(), Objs::[map()], map(), Meta::map()} |
    {error, term()}.

object_db_search(_SrvId, _Spec) ->
    {error, db_not_defined}.


%% @doc Must stop loaded objects
-spec object_db_delete_all_childs(srv_id(), path(), nkdomain:search_spec()) ->
    {ok, Total::integer()} | {error, term()}.

object_db_delete_all_childs(_SrvId, _Path, _Spec) ->
    {error, db_not_defined}.


%% @doc Called to perform a cleanup of the store (expired objects, etc.)
%% Should call object_check_active/3 for each 'active' object found
-spec object_db_clean(srv_id()) ->
    ok | {error, term()}.

object_db_clean(_SrvId) ->
    {error, db_not_defined}.




%% ===================================================================
%% API Server
%% ===================================================================


%% @doc
service_api_syntax(Syntax, #nkreq{cmd = <<"objects/", Rest/binary>>}=Req) ->
    case binary:split(Rest, <<"/">>) of
        [] ->
            continue;
        [Type, Cmd] ->
            case nkdomain_all_types:get_module(Type) of
                undefined ->
                    continue;
                Module ->
                    Syntax2 = case erlang:function_exported(Module, object_api_syntax, 2) of
                        true ->
                            apply(Module, object_api_syntax, [Cmd, Syntax]);
                        false ->
                            nkdomain_obj_syntax:syntax(Cmd, Type, Syntax)
                    end,
                    {continue, [Syntax2, Req#nkreq{req_state={Type, Module, Cmd}}]}
            end
    end;

service_api_syntax(_Syntax, _Req) ->
    continue.


%% @doc
service_api_allow(#nkreq{cmd = <<"objects/session/start">>, user_id = <<>>}, State) ->
    {true, State};

service_api_allow(#nkreq{cmd = <<"objects/user/get_token">>, user_id = <<>>}, State) ->
    {true, State};

service_api_allow(#nkreq{cmd = <<"objects/", _/binary>>, user_id = <<>>}, State) ->
    {false, State};

service_api_allow(#nkreq{cmd = <<"objects/", _/binary>>, req_state={_Type, Module, Cmd}}=Req, State) ->
    case nklib_util:apply(Module, object_api_allow, [Cmd, Req, State]) of
        not_exported ->
            {true, State};
        Other ->
            Other
    end;

service_api_allow(#nkreq{cmd = <<"session", _/binary>>}, State) ->
    {true, State};

service_api_allow(#nkreq{cmd = <<"event", _/binary>>}, State) ->
    {true, State};

service_api_allow(#nkreq{cmd = <<"nkadmin", _/binary>>}, State) ->
    {true, State};

service_api_allow(_Req, _State) ->
    continue.


%% @doc
service_api_cmd(#nkreq{cmd = <<"objects/", _/binary>>, req_state={Type, Module, Cmd}}=Req, State) ->
    #nkreq{session_module=Mod, tid=TId} = Req,
    Self = self(),
    Pid = spawn_link(
        fun() ->
            Reply = case erlang:function_exported(Module, object_api_cmd, 2) of
                true ->
                    apply(Module, object_api_cmd, [Cmd, Req]);
                false ->
                    nkdomain_obj_api:api(Cmd, Type, Req)
            end,
            Mod:reply(Self, TId, Reply)
        end),
    {ack, Pid, State};

%%service_api_cmd(#nkreq{cmd = <<"objects/", _/binary>>, req_state={Type, Module, Cmd}}=Req, State) ->
%%    #nkreq{session_module=Mod, tid=TId} = Req,
%%    Reply = case erlang:function_exported(Module, object_api_cmd, 2) of
%%        true ->
%%            apply(Module, object_api_cmd, [Cmd, Req]);
%%        false ->
%%            nkdomain_obj_api:api(Cmd, Type, Req)
%%    end,
%%    case Reply of
%%        {login, R, U, M} ->
%%            {login, R, U, M, State};
%%        {ok, R} ->
%%            {ok, R, State};
%%        {ok, R, S} ->
%%            {ok, R, S, State};
%%        {error, E} ->
%%            {error, E, State}
%%    end;


service_api_cmd(_Req, _State) ->
    continue.


%% @private
api_server_reg_down({nkdomain_stop, Module, _Pid}, _Reason, State) ->
    {stop, {module_failed, Module}, State};

api_server_reg_down(_Link, _Reason, _State) ->
    continue.

%% @doc
api_server_http_auth(#nkreq{cmd = <<"objects/user/get_token">>}, _HttpReq) ->
    {true, <<>>, #{}, #{}};

api_server_http_auth(#nkreq{srv_id=SrvId}, HttpReq) ->
    Headers = nkapi_server_http:get_headers(HttpReq),
    Token = nklib_util:get_value(<<"x-netcomposer-auth">>, Headers, <<>>),
    case nkdomain_user_obj:check_token(SrvId, Token) of
        {ok, UserId, Meta} ->
            {true, UserId, Meta, #{}};
        {error, Error} ->
            {error, Error}
    end.

%%%% @doc
%%api_server_handle_info({nkdist, {sent_link_down, Link}}, State) ->
%%    nkapi_server:stop(self(), {sent_link_down, Link}),
%%    {ok, State};
%%
%%api_server_handle_info(_Info, _State) ->
%%    continue.


%% ===================================================================
%% Plugin callbacks
%% ===================================================================

%% @private
plugin_deps() ->
    [nkapi, nkadmin, nkmail, nkmail_smtp_client, nkfile_filesystem, nkfile_s3, nkservice_rest, nkservice_webserver].


%% @private
plugin_syntax() ->
    #{
        nkdomain => nkdomain_service:syntax()
    }.


%% @private
plugin_config(#{nkdomain:=DomCfg}=Config, _Service) ->
    nkdomain_service:config(DomCfg, Config);

plugin_config(Config, _Service) ->
    {ok, Config}.


%% @private
service_init(_Service, State) ->
    nkdomain_service:init(State).


%% @private
service_handle_cast(nkdomain_load_domain, State) ->
    #{id:=SrvId} = State,
    #{domain:=Domain} = SrvId:config(),
    case nkdomain_lib:load(SrvId, Domain) of
        #obj_id_ext{type = ?DOMAIN_DOMAIN, obj_id=ObjId, path=Path, pid=Pid} ->
            lager:info("Service loaded domain ~s (~s)", [Path, ObjId]),
            monitor(process, Pid),
            DomainData = #{
                domain_obj_id => ObjId,
                domain_path => Path,
                domain_pid => Pid
            },
            nkservice_srv:put(SrvId, nkdomain_data, DomainData),
            State2 = State#{nkdomain => DomainData},
            {noreply, State2};
        {error, Error} ->
            ?LLOG(warning, "could not load domain ~s: ~p", [Domain, Error]),
            {noreply, State}
    end;

service_handle_cast(_Msg, _State) ->
    continue.


%% @private
service_handle_info({'DOWN', _Ref, process, Pid, _Reason}, State) ->
    case State of
        #{nkdomain:=#{domain_pid:=Pid, domain_path:=Path}} ->
            lager:info("Service received domain '~s' down", [Path]),
            {noreply, State};
        _ ->
            {noreply, State}
    end;
service_handle_info(_Msg, _State) ->
    continue.


%% ===================================================================
%% Internal
%% ===================================================================


%% @private
call_module(Fun, Args, #?STATE{module=Module}=State) ->
    case erlang:function_exported(Module, Fun, length(Args)+1) of
        true ->
            case apply(Module, Fun, Args++[State]) of
                continue ->
                    {ok, State};
                Other ->
                    Other
            end;
        false ->
            {ok, State}
    end.


%%%% @private
%%call_parent_store(root, _Fun, _Args) ->
%%    {error, store_not_implemented};
%%
%%call_parent_store(SrvId, Fun, Args) ->
%%    ?LLOG(warning, "calling root store", []),
%%    apply(root, Fun, [SrvId|Args]).

