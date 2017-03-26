-module(nkdomain_test).
-compile(export_all).

-include_lib("nkapi/include/nkapi.hrl").

-define(WS, "ws://127.0.0.1:9202/api/ws").


login() ->
    login(admin, "1234").

login(User, Pass) ->
    Fun = fun ?MODULE:api_client_fun/2,
    Login = #{
        id => nklib_util:to_binary(User),
        password=> nklib_util:to_binary(Pass),
        meta => #{a=>nklib_util:to_binary(User)}
    },
    {ok, _SessId, _Pid, _Reply} = nkapi_client:start(root, ?WS, Login, Fun, #{}).


user_get() ->
    cmd(user, get, #{}).

user_get(Id) ->
    cmd(user, get, #{id=>Id}).

user_create(Name, Surname, Email) ->
    Data = #{
        obj_name => Name,
        user => #{
            name => to_bin(Name),
            surname => to_bin(Surname),
            email => to_bin(Email)
        }
    },
    case cmd(user, create, Data) of
        {ok, #{<<"obj_id">>:=ObjId}} -> {ok, ObjId};
        {error, Error} -> {error, Error}
    end.


user_delete(Id) ->
    cmd(user, delete, #{id=>to_bin(Id)}).


user_update(Id, Name, Password, Email) ->
    Data = #{
        id => to_bin(Id),
        user => #{
            name => to_bin(Name),
            password => Password,
            email => Email
        }
    },
    cmd(user, update, Data).


user_find_referred(Id, Type) ->
    cmd(user, find_referred, #{id=>Id, type=>Type}).



domain_get() ->
    cmd(domain, get, #{}).

domain_get(Id) ->
    cmd(domain, get, #{id=>Id}).

domain_create(Path, Desc) ->
    Data = #{
        path => to_bin(Path),
        description => Desc,
        aliases => [dom1, dom2]
    },
    case cmd(domain, create, Data) of
        {ok, #{<<"obj_id">>:=ObjId}} -> {ok, ObjId};
        {error, Error} -> {error, Error}
    end.


domain_delete(Id) ->
    cmd(domain, delete, #{id=>to_bin(Id)}).


domain_update(Id, Desc, Aliases) ->
    Data = #{
        id => to_bin(Id),
        description => Desc,
        aliases => Aliases
    },
    cmd(domain, update, Data).


domain_get_types(Id) ->
    cmd(domain, get_types, #{id=>Id}).


domain_get_all_types() ->
    cmd(domain, get_all_types, #{}).


domain_get_childs(Id) ->
    cmd(domain, get_childs, #{id=>Id}).


domain_get_all_childs() ->
    cmd(domain, get_all_childs, #{}).

domain_get_all_users() ->
    cmd(domain, get_all_childs, #{type=>user}).


%% ===================================================================
%% Client fun
%% ===================================================================


api_client_fun(#nkapi_req{class=event, data=Event}, UserData) ->
    lager:notice("CLIENT event ~p", [lager:pr(Event, nkservice_events)]),
    {ok, UserData};

api_client_fun(_Req, UserData) ->
    % lager:error("API REQ: ~p", [lager:pr(_Req, ?MODULE)]),
    {error, not_implemented, UserData}.

get_client() ->
    [{_, Pid}|_] = nkapi_client:get_all(),
    Pid.


%% Test calling with class=test, cmd=op1, op2, data=#{nim=>1}
cmd(Class, Cmd, Data) ->
    Pid = get_client(),
    cmd(Pid, Class, Cmd, Data).

cmd(Pid, Class, Cmd, Data) ->
    nkapi_client:cmd(Pid, Class, <<>>, Cmd, Data).




%% ===================================================================
%% OBJECTS
%% ===================================================================

sub1_create() ->
     nkdomain_domain_obj:create(root, "sub1b", "root", "Sub 1").


sub2_create() ->
    nkdomain_domain_obj:create(root, "sub2", "/sub1b", "Sub 2").


user_create_root(Name, Email) ->
    Data = #{name=>Name, surname=>"surname", email=>Email},
    nkdomain_user_obj:create(root, Name, Data).

user_create_sub1(Name, Email) ->
    Data = #{name=>Name, surname=>"surname", email=>Email, parent=>"/sub1"},
    nkdomain_user_obj:create(root, Name, Data).



to_bin(R) -> nklib_util:to_binary(R).