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

%% @doc User Object Syntax

-module(nkdomain_domain_obj_syntax).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([api/3]).



%% ===================================================================
%% Syntax
%% ===================================================================


%% @doc
api('', create, Syntax) ->
    Syntax2 = Syntax#{
        obj_name => binary,
        domain => binary,
        description => binary
    },
    nklib_syntax:add_mandatory([obj_name, description], Syntax2);

api('', update, Syntax) ->
    Syntax#{
        id => binary,
        description => binary
    };

%% Sample (see nkelastic_search.erl)
%% #{
%%      from => 1,
%%      size => 10,
%%      sort => ["field1", "desc:field2"],
%%      fields => ["field1", "field2"],
%%      filters => #{
%%          field1 => ">text",
%%          field2 => "!text"
%%      }
%% }

api('', find_types, Syntax) ->
    Syntax2 = Syntax#{
        id => binary
    },
    nkdomain_obj_util:search_syntax(Syntax2);

api('', find_all_types, Syntax) ->
    api('', find_types, Syntax);

api('', find_childs, Syntax) ->
    api('', find_types, Syntax);

api('', find_all_childs, Syntax) ->
    api('', find_types, Syntax);

api(Sub, Cmd, Syntax) ->
    nkdomain_obj_syntax:syntax(Sub, Cmd, Syntax).


%% ===================================================================
%% Search syntax
%% ===================================================================



