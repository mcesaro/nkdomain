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

%% @doc Domain Object

-module(nkdomain_domain_obj_view).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([view/3, update/3, create/2]).

-include("nkdomain.hrl").
-include("nkdomain_admin.hrl").
-include_lib("nkadmin/include/nkadmin.hrl").

-define(CHAT_CONVERSATION, <<"conversation">>).

-define(LLOG(Type, Txt, Args),
    lager:Type("NkDOMAIN Admin Domain " ++ Txt, Args)).




%% @private
view(Obj, IsNew, #admin_session{user_id=UserId, domain_id=DefDomain, srv_id=SrvId}=Session) ->
    ObjId = maps:get(obj_id, Obj, <<>>),
    DomainId = maps:get(domain_id, Obj, DefDomain),
    {ok, <<"domain">>, _, DomainPath, _} = nkdomain:find(DomainId),
    ObjName = maps:get(obj_name, Obj, <<>>),
    Name = maps:get(name, Obj, <<>>),
    Description = maps:get(description, Obj, <<>>),
    Enabled = maps:get(enabled, Obj, true),
    Tags = maps:get(tags, Obj, []),
    IconId = maps:get(icon_id, Obj, <<>>),
    IconUrl = case IconId of
        <<>> ->
            <<"img/question_mark.png">>;
        IconId ->
            nkdomain_admin_util:get_file_url(IconId, Session)
    end,
    IconImage = <<"<img class='photo' style='padding: 0px 10% 0 10%; width:80%; height:auto;' src='", IconUrl/binary, "'/>">>,
    ClientId = nkdomain_admin_util:get_client_id(Session),
    Domain = maps:get(?DOMAIN_DOMAIN, Obj, #{}),
    Configs = maps:get(configs, Domain, #{}),
    DefConvMap = maps:get(<<"default_conversations_", ClientId/binary>>, Configs, #{<<"list">> => []}),
    #{<<"list">> := DefaultConvs} = DefConvMap,
    DefaultConvsBin = lists:join(<<",">>, DefaultConvs),
    DefaultConvsOpts = get_convs_opts(DefaultConvs),
    FormId = nkdomain_admin_util:make_obj_view_id(?DOMAIN_DOMAIN, ObjId),
    HasAlerts = case DomainPath of
        <<"/sipstorm/c4", _/binary>> -> %% TODO: Change to client specific domain
            true;
        _ ->
            false
    end,
    AlertList = maps:get(<<"alerts_", ClientId/binary>>, Configs, #{<<"list">> => []}),
    #{<<"list">> := Alerts} = AlertList,
    {FinalPos, AlertFields} = lists:foldl(fun(M, {Pos, Acc}) ->
        PosBin = nklib_util:to_binary(Pos),
        Button = get_alert_button(FormId, PosBin, <<"Delete alert ", PosBin/binary>>, <<"trash">>, <<"Undo">>, <<"undo">>, false),
        Check = #{
            id => <<"alert_checkbox_", PosBin/binary>>,
            type => checkbox,
            label => <<"Is enabled?">>,
            value => maps:get(<<"enabled">>, M, true),
            editable => true
        },
        Convs = maps:get(<<"conversations">>, M, []),
        ConvsBin = lists:join(<<",">>, Convs),
        ConvsOpts = get_convs_opts(Convs),
        Chan = #{
            id => <<"alert_convs_", PosBin/binary>>,
            type => multicombo,
            label => <<"Send to channels">>,
            value => ConvsBin,
            suggest_type => ?CHAT_CONVERSATION,
            suggest_field => <<"name">>,
            suggest_filters => #{
                conversation_type => <<"channel">>
            },
            suggest_template => <<"#name#">>,
            options => ConvsOpts,
            required => true,
            editable => true
        },
        Msg = #{
            id => <<"alert_message_", PosBin/binary>>,
            type => text,
            label => <<"Alert message ", PosBin/binary>>,
            value => maps:get(<<"text">>, M, <<>>),
            required => true,
            editable => true
        },
        {Pos+1, [Button, Check, Chan, Msg | Acc]}
    end,
        {1, []},
        Alerts
    ),
    FinalPosBin = nklib_util:to_binary(FinalPos),
    NewAlertField = [
        get_alert_button(FormId, FinalPosBin, <<"Cancel">>, <<"times">>, <<"Define new alert">>, <<"plus">>, true),
        #{
            id => <<"alert_message_", FinalPosBin/binary>>,
            type => text,
            label => <<"New alert message">>,
            value => <<>>,
            required => true,
            hidden => true,
            editable => true
        },
        #{
            id => <<"alert_convs_", FinalPosBin/binary>>,
            type => multicombo,
            label => <<"Send to channels">>,
            value => <<>>,
            suggest_type => ?CHAT_CONVERSATION,
            suggest_field => <<"name">>,
            suggest_filters => #{
                conversation_type => <<"channel">>
            },
            suggest_template => <<"#name#">>,
            options => [],
            required => true,
            hidden => true,
            editable => true
        },
        #{
            id => <<"alert_checkbox_", FinalPosBin/binary>>,
            type => checkbox,
            label => <<"Is enabled?">>,
            value => true,
            hidden => true,
            editable => true
        }
    ],
    AlertFields2 = lists:reverse(AlertFields) ++ NewAlertField,
    Base = case IsNew of
        true ->
            #{};
        false ->
            #{with_image => IconImage, with_css => <<"photo">>, with_file_types => ["png", "jpg", "jpeg"]}
    end,
    Spec = Base#{
        form_id => FormId,
        buttons => [
            #{type => case Enabled of true -> disable; _ -> enable end, disabled => IsNew},
            #{type => delete, disabled => IsNew},
            #{type => save}
        ],
        groups => [
            #{
                header => ?DOMAIN_DOMAIN,
                values => [
                    case IsNew of
                        true ->
                            {ok, Domains} = nkdomain_admin_util:get_domains("/", Session),
                            Opts = [
                                #{id=>Id, value=>Value} ||
                                {Id, Value} <- [{<<"root">>, <<"/">>}|Domains]
                            ],
                            #{
                                id => <<"domain">>,
                                type => combo,
                                label => <<"Domain">>,
                                value => DomainId,
                                editable => true,
                                options => Opts
                            };
                        false ->
                            DomainPath = case nkdomain_db:find(DomainId) of
                                #obj_id_ext{path=DP} -> DP;
                                _ -> <<>>
                            end,
                            #{
                                id => <<"domain">>,
                                type => text,
                                label => <<"Domain">>,
                                value => DomainPath,
                                editable => false
                            }
                    end,
                    #{
                        id => <<"obj_name">>,
                        type => text,
                        label => <<"Object name">>,
                        value => ObjName,
                        required => IsNew,
                        editable => IsNew
                    },
                    #{
                        id => <<"name">>,
                        type => text,
                        label => <<"Name">>,
                        value => Name,
                        required => true,
                        editable => true
                    },
                    #{
                        id => <<"description">>,
                        type => text,
                        label => <<"Description">>,
                        value => Description,
                        editable => true
                    }
                ]
            },
            #{
                header => <<"CONFIGURATION">>,
                hidden => IsNew,
                values => [
                    #{
                        id => <<"default_convs">>,
                        type => multicombo,
                        label => <<"Default channels">>,
                        value => DefaultConvsBin,
                        suggest_type => ?CHAT_CONVERSATION,
                        suggest_field => <<"name">>,
                        suggest_filters => #{
                            conversation_type => <<"channel">>
                        },
                        suggest_template => <<"#name#">>,
                        options => DefaultConvsOpts,
                        hidden => IsNew,
                        editable => true
                    }
                ]
            },
            #{
                header => <<"ALERTS">>,
                hidden => IsNew or (not HasAlerts),
                values => AlertFields2
            },
            nkadmin_webix_form:creation_fields(Obj, IsNew)
        ]
    },
    Data = #{
        id => FormId,
        class => webix_ui,
        value => nkadmin_webix_form:form(Spec, ?DOMAIN_DOMAIN, Session)
    },
    {ok, Data, Session}.





update(ObjId, Data, #admin_session{user_id=UserId}=Session) ->
    ?LLOG(info, "NKLOG UPDATE ~p ~p", [ObjId, Data]),
    Base = maps:with([<<"name">>, <<"description">>, <<"icon_id">>], Data),
    DefaultConvs = maps:get(<<"default_convs">>, Data, []),
    DefaultConvsList = case binary:split(DefaultConvs, <<",">>, [global]) of
        [<<>>] ->
            [];
        Other ->
            Other
    end,
    DefConvMap = #{<<"list">> => DefaultConvsList},
    AlertIds = filter_by_prefix(<<"alert_message_">>, maps:keys(Data)),
    Alerts = get_alerts(AlertIds, Data),
    AlertsMap = #{<<"list">> => Alerts},
    ClientId = nkdomain_admin_util:get_client_id(Session),
    case nkdomain:update(ObjId, Base) of
        {ok, _} ->
            ?LLOG(notice, "domain ~s updated", [ObjId]),
            case nkdomain_domain:set_config(ObjId, <<"default_conversations_", ClientId/binary>>, DefConvMap) of
                ok ->
                    case nkdomain_domain:set_config(ObjId, <<"alerts_", ClientId/binary>>, AlertsMap) of
                        ok ->
                            ok;
                        {error, Error} ->
                            ?LLOG(notice, "could not update domain ~s: ~p", [ObjId, Error]),
                            {error, Error}
                    end;
                {error, Error} ->
                    ?LLOG(notice, "could not update domain ~s: ~p", [ObjId, Error]),
                    {error, Error}
            end;
        {error, Error} ->
            ?LLOG(notice, "could not update domain ~s: ~p", [ObjId, Error]),
            {error, Error}
    end.


create(Data, _Session) ->
    ?LLOG(info, "NKLOG CREATE ~p", [Data]),
    #{
        <<"domain">> := DomainId,
        <<"obj_name">> := ObjName,
        <<"name">> := Name,
        <<"description">> := Description
    } = Data,
    DomainCreate = #{
        type => ?DOMAIN_DOMAIN,
        domain_id => DomainId,
        obj_name => ObjName,
        name => Name,
        description => Description,
        ?DOMAIN_DOMAIN => #{}
    },
    case nkdomain_obj_make:create(DomainCreate) of
        {ok, #obj_id_ext{obj_id=ObjId}, [<<"domain.config">>]} ->
            {ok, ObjId};
        {error, Error} ->
            {error, Error}
    end.


get_convs_opts(Ids) ->
    get_convs_opts(Ids, []).

%% @private
get_convs_opts([], Acc) ->
    lists:reverse(Acc);

get_convs_opts([Id|Ids], Acc) ->
    case nkdomain:get_name(Id) of
        {ok, #{obj_id:=ObjId, name:=Name}} ->
            get_convs_opts(Ids, [#{id => ObjId, name => Name} | Acc]);
        {error, _Error} ->
            ?LLOG(warning, "Unknown ID found: ~p", [Id]),
            get_convs_opts(Ids, [#{id => Id, name => Id} | Acc])
    end.


%% @private
filter_by_prefix(Prefix, List) when is_list(List) ->
    PrefixBin = nklib_util:to_binary(Prefix),
    filter_by_prefix(PrefixBin, List, []).

%% @private
filter_by_prefix(_, [], Acc) ->
    lists:reverse(Acc);

filter_by_prefix(Prefix, [L | List], Acc) ->
    Size = size(Prefix),
    case L of
        <<Prefix:Size/binary, Rest/binary>> ->
            filter_by_prefix(Prefix, List, [Rest| Acc]);
        _ ->
            filter_by_prefix(Prefix, List, Acc)
    end.

%% @private
get_alerts(Ids, Data) ->
    get_alerts(Ids, Data, []).

%% @private
get_alerts([], _, Acc) ->
    lists:reverse(Acc);

get_alerts([Id|Ids], Data, Acc) ->
    ButtonKey = <<"alert_button_", Id/binary>>,
    case Data of
        #{ButtonKey := true} ->
            get_alerts(Ids, Data, Acc);
        _ ->
            Msg = maps:get(<<"alert_message_", Id/binary>>, Data, <<>>),
            Convs = maps:get(<<"alert_convs_", Id/binary>>, Data, []),
            ConvsList = case binary:split(Convs, <<",">>, [global]) of
                [<<>>] ->
                    [];
                Other ->
                    lists:filter(fun(L) -> L =/= <<>> end, Other)
            end,
            Check = maps:get(<<"alert_checkbox_", Id/binary>>, Data, false),
            case {Msg, ConvsList} of
                {<<>>, _} ->
                    get_alerts(Ids, Data, Acc);
                {_, []} ->
                    get_alerts(Ids, Data, Acc);
                _ ->
                    Alert = #{
                        <<"text">> => Msg,
                        <<"conversations">> => ConvsList,
                        <<"enabled">> => Check
                    },
                    get_alerts(Ids, Data, [Alert|Acc])
            end
    end.


%% @private
get_alert_button(FormId, Pos, DisabledLabel, DisabledIcon, EnabledLabel, EnabledIcon, State) ->
    PosBin = nklib_util:to_binary(Pos),
    {DefaultLabel, DefaultIcon} = case State of
        false ->
            {DisabledLabel, DisabledIcon};
        true ->
            {EnabledLabel, EnabledIcon}
    end,
    #{
        id => <<"alert_button_", PosBin/binary>>,
        type => button,
        button_type => <<"iconButton">>,
        button_icon => DefaultIcon,
        value => State,
        label => <<DefaultLabel/binary>>,
        onClick => <<"
            function() {
                var form = $$('", FormId/binary, "');
                if (form && form.elements) {
                    var alert_check = form.elements.alert_checkbox_", PosBin/binary, ";
                    var alert_msg = form.elements.alert_message_", PosBin/binary, ";
                    var alert_chan = form.elements.alert_convs_", PosBin/binary, ";
                    if (!this.getValue()) {
                        alert_check.hide();
                        alert_msg.hide();
                        alert_chan.hide();
                        this.setValue(true);
                        this.data.label = '", EnabledLabel/binary, "';
                        this.data.icon = '", EnabledIcon/binary, "';
                        this.refresh();
                    } else {
                        alert_check.show();
                        alert_msg.show();
                        alert_chan.show();
                        this.setValue(false);
                        this.data.label = '", DisabledLabel/binary, "';
                        this.data.icon = '", DisabledIcon/binary, "';
                        this.refresh();
                    }
                }
            }
        ">>
    }.