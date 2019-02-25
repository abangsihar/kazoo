%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2010-2019, 2600Hz
%%% @doc
%%% @author James Aimonetti
%%% @end
%%%-----------------------------------------------------------------------------
-module(pqc_cb_ips).

-export([init/0
        ,api_calls/1
        ,update_model/3
        ,check_response/3
        ]).

-export([cleanup/0, cleanup/1
        ,seq/0
        ]).

%% API Shims
-export([list_ips/1
        ,assign_ips/3
        ,remove_ip/3
        ,fetch_ip/3
        ,assign_ip/3
        ,fetch_hosts/1
        ,fetch_zones/1
        ,fetch_assigned/2
        ,create_ip/2
        ,delete_ip/2
        ]).

-export_type([dedicated/0]).

-include_lib("proper/include/proper.hrl").
-include("kazoo_proper.hrl").

-record('dedicated', {ip :: kz_term:api_ne_binary()
                     ,host :: kz_term:api_ne_binary()
                     ,zone :: kz_term:api_ne_binary()
                     }).
-define(DEDICATED(IP, Host, Zone)
       ,#dedicated{ip=IP, host=Host, zone=Zone}
       ).
-type dedicated() :: #dedicated{}.

-spec list_ips(pqc_cb_api:state() | pqc_kazoo_model:model()) ->
                      {'ok', kz_json:objects()} |
                      {'error', 'not_found'}.
list_ips(#{}=API) ->
    case pqc_api_ips:list(API) of
        {'error', _Code, _E} ->
            ?DEBUG("listing IPs errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            ?DEBUG("listing IPs: ~s", [Response]),
            {'ok', kz_json:get_list_value(<<"data">>, kz_json:decode(Response))}
    end;
list_ips(Model) ->
    list_ips(pqc_kazoo_model:api(Model)).

-spec assign_ips(pqc_kazoo_model:model() | pqc_cb_api:state(), kz_term:api_ne_binary(), [dedicated()]) ->
                        {'ok', kz_json:objects()} |
                        {'error', 'not_found'}.
assign_ips(_API, 'undefined', _Dedicateds) ->
    {'error', 'not_found'};
assign_ips(#{}=API, AccountId, Dedicateds) ->
    IPs = [IP || ?DEDICATED(IP, _, _) <- Dedicateds],

    case pqc_api_ips:assign_ips(API, AccountId, IPs) of
        {'error', _Code, _E} ->
            ?DEBUG("assigning IPs errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            {'ok', kz_json:get_list_value(<<"data">>, kz_json:decode(Response))}
    end;
assign_ips(Model, AccountName, Dedicateds) ->
    assign_ips(pqc_kazoo_model:api(Model)
              ,pqc_kazoo_model:account_id_by_name(Model, AccountName)
              ,Dedicateds
              ).

-spec remove_ip(pqc_kazoo_model:model() | pqc_cb_api:state(), kz_term:ne_binary(), dedicated()) ->
                       {'ok', kz_json:object()} |
                       {'error', 'not_found'}.
remove_ip(_API, 'undefined', _Dedicated) ->
    {'error', 'not_found'};
remove_ip(#{}=API, AccountId, ?DEDICATED(IP, _, _)) ->
    case pqc_api_ips:remove(API, AccountId, IP) of
        {'error', _Code, _E} ->
            ?DEBUG("removing IP errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            {'ok', kz_json:get_json_value(<<"data">>, kz_json:decode(Response))}
    end;
remove_ip(Model, AccountName, Dedicated) ->
    remove_ip(pqc_kazoo_model:api(Model)
             ,pqc_kazoo_model:account_id_by_name(Model, AccountName)
             ,Dedicated
             ).

-spec fetch_ip(pqc_kazoo_model:model() | pqc_cb_api:state(), kz_term:ne_binary(), dedicated()) ->
                      {'ok', kz_json:object()} |
                      {'error', 'not_found'}.
fetch_ip(_API, 'undefined', _Dedicated) ->
    {'error', 'not_found'};
fetch_ip(#{}=API, AccountId, ?DEDICATED(IP, _, _)) ->
    case pqc_api_ips:fetch(API, AccountId, IP) of
        {'error', _Code, _E} ->
            ?DEBUG("fetching IP errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            {'ok', kz_json:get_json_value(<<"data">>, kz_json:decode(Response))}
    end;
fetch_ip(Model, AccountName, Dedicated) ->
    fetch_ip(pqc_kazoo_model:api(Model)
            ,pqc_kazoo_model:account_id_by_name(Model, AccountName)
            ,Dedicated
            ).

-spec assign_ip(pqc_cb_api:state(), pqc_cb_accounts:account_id(), dedicated()) ->
                       {'ok', kz_json:object()} |
                       {'error', 'not_found'}.
assign_ip(_API, 'undefined', _Dedicated) ->
    {'error', 'not_found'};
assign_ip(#{}=API, AccountId, ?DEDICATED(IP, _, _)) ->
    case pqc_api_ips:assign_ip(API, AccountId, IP) of
        {'error', _Code, _E} ->
            ?DEBUG("assigning IP errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            {'ok', kz_json:get_json_value([<<"data">>, <<"success">>, IP], kz_json:decode(Response))}
    end;
assign_ip(Model, AccountName, Dedicated) ->
    assign_ip(pqc_kazoo_model:api(Model)
             ,pqc_kazoo_model:account_id_by_name(Model, AccountName)
             ,Dedicated
             ).

-spec fetch_hosts(pqc_cb_api:state()) ->
                         {'ok', kz_term:ne_binaries()} |
                         {'error', 'not_found'}.
fetch_hosts(#{}=API) ->
    case pqc_api_ips:fetch_hosts(API) of
        {'error', _Code, _E} ->
            ?DEBUG("fetch hosts errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            {'ok', kz_json:get_list_value(<<"data">>, kz_json:decode(Response))}
    end;
fetch_hosts(Model) ->
    fetch_hosts(pqc_kazoo_model:api(Model)).

-spec fetch_zones(pqc_cb_api:state()) ->
                         {'ok', kz_term:ne_binaries()} |
                         {'error', 'not_found'}.
fetch_zones(#{}=API) ->
    case pqc_api_ips:fetch_zones(API) of
        {'error', _Code, _E} ->
            ?DEBUG("fetch zones errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            {'ok', kz_json:get_list_value(<<"data">>, kz_json:decode(Response))}
    end;
fetch_zones(Model) ->
    fetch_zones(pqc_kazoo_model:api(Model)).

-spec fetch_assigned(pqc_cb_api:state(), pqc_cb_accounts:account_id()) ->
                            {'ok', kz_json:objects()} |
                            {'error', 'not_found'}.
fetch_assigned(_API, 'undefined') ->
    {'error', 'not_found'};
fetch_assigned(#{}=API, AccountId) ->
    case pqc_api_ips:fetch_assigned(API, AccountId) of
        {'error', _Code, _E} ->
            ?DEBUG("fetch zones errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            lager:info("fetch_assigned: ~s", [Response]),
            {'ok', kz_json:get_list_value(<<"data">>, kz_json:decode(Response))}
    end;
fetch_assigned(Model, AccountName) ->
    fetch_assigned(pqc_kazoo_model:api(Model)
                  ,pqc_kazoo_model:account_id_by_name(Model, AccountName)
                  ).

-spec create_ip(pqc_cb_api:state(), dedicated()) ->
                       {'ok', kz_json:object()} |
                       {'error', 'not_found' | 'conflict'}.
create_ip(#{}=API, ?DEDICATED(IP, Host, Zone)) ->
    Data = kz_json:from_list([{<<"ip">>, IP}
                             ,{<<"host">>, Host}
                             ,{<<"zone">>, Zone}
                             ]),

    case pqc_api_ips:create(API, Data) of
        {'error', _Code, _E} ->
            ?DEBUG("create ip errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            JObj = kz_json:decode(Response),
            case kz_json:get_integer_value(<<"error">>, JObj) of
                'undefined' ->
                    {'ok', kz_json:get_value([<<"data">>, <<"_read_only">>], JObj)};
                409 ->
                    {'error', 'conflict'}
            end
    end;
create_ip(Model, Dedicated) ->
    create_ip(pqc_kazoo_model:api(Model), Dedicated).

-spec delete_ip(pqc_cb_api:state(), dedicated()) ->
                       {'ok', kz_json:object()} |
                       {'error', 'not_found'}.
delete_ip(#{}=API, ?DEDICATED(IP, _Host, _Zone)) ->
    case pqc_api_ips:delete(API, IP) of
        {'error', _Code, _E} ->
            ?DEBUG("delete ip errored: ~p: ~p", [_Code, _E]),
            {'error', 'not_found'};
        Response ->
            JObj = kz_json:decode(Response),
            case kz_json:get_integer_value(<<"error">>, JObj) of
                404 -> {'error', 'not_found'};
                _ -> {'ok', kz_json:get_list_value(<<"data">>, JObj)}
            end
    end;
delete_ip(Model, Dedicated) ->
    delete_ip(pqc_kazoo_model:api(Model), Dedicated).

-define(ACCOUNT_NAMES, [<<?MODULE_STRING>>]).
-define(DEDICATED_IPS, [?DEDICATED(<<"1.2.3.4">>, <<"a.host.com">>, <<"zone-1">>)]).

-spec cleanup() -> any().
cleanup() ->
    ?INFO("CLEANUP ALL THE THINGS"),
    kz_data_tracing:clear_all_traces(),

    cleanup(pqc_cb_api:authenticate()).

-spec cleanup(pqc_cb_api:state()) -> any().
cleanup(#{}=API) ->
    ?INFO("CLEANUP TIME, EVERYBODY HELPS"),
    _ = pqc_cb_accounts:cleanup_accounts(API, ?ACCOUNT_NAMES),
    _ = [delete_ip(IP) || ?DEDICATED(IP, _, _) <- ?DEDICATED_IPS],

    kt_cleanup:cleanup_soft_deletes(?KZ_DEDICATED_IP_DB),

    pqc_cb_api:cleanup(API).

delete_ip(IP) ->
    case kz_datamgr:del_doc(?KZ_DEDICATED_IP_DB, IP) of
        {'ok', _} -> ?INFO("deleted ip ~s from db", [IP]);
        {'error', 'not_found'} -> 'ok';
        {'error', _E} -> ?INFO("failed to delete ip ~s: ~p", [_E])
    end.

-spec init() -> 'ok'.
init() ->
    _ = [crossbar_maintenance:start_module(Mod) ||
            Mod <- ['cb_ips', 'cb_accounts']
        ],
    ?INFO("INIT FINISHED").

init_system() ->
    _ = kz_data_tracing:clear_all_traces(),
    kapps_controller:start_app('crossbar'),
    'ok'.

-spec seq() -> 'ok'.
seq() ->
    init_system(),
    _ = init(),

    Model = pqc_runner:initial_state(),
    API = pqc_kazoo_model:api(Model),

    IP = ?DEDICATED(<<"1.2.3.4">>, <<"a.host.com">>, <<"zone-1">>),

    _ = try
            {'ok', Created} = create_ip(API, IP),
            ?INFO("created ip ~p", [Created]),

            AccountResp = pqc_cb_accounts:create_account(Model, hd(?ACCOUNT_NAMES)),
            AccountId = kz_json:get_value([<<"data">>, <<"id">>], kz_json:decode(AccountResp)),
            ?INFO("created account ~s", [AccountId]),

            {'ok', IPs} = list_ips(API),
            ?INFO("ips available: ~p", [IPs]),

            {'ok', Assigned} = assign_ip(API, AccountId, IP),
            ?INFO("assigned ~p: ~p", [IP, Assigned]),

            {'ok', Fetched} = fetch_ip(API, AccountId, IP),
            ?INFO("fetched ~p: ~p", [IP, Fetched]),

            {'ok', Hosts} = fetch_hosts(API),
            ?INFO("hosts: ~p", [Hosts]),

            {'ok', Zones} = fetch_zones(API),
            ?INFO("zones: ~p", [Zones]),

            {'ok', AssignedIPs} = fetch_assigned(API, AccountId),
            ?INFO("assigned ips: ~p", [AssignedIPs]),
            lager:info("finished running IPs test")

        catch
            _E:_R ->
                ST = erlang:get_stacktrace(),
                ?INFO("failed ~s: ~p", [_E, _R]),
                _ = [?INFO("st: ~p", [S]) || S <- ST],
                lager:info("failed ~s: ~p", [_E, _R]),
                [lager:info("st: ~p", [S]) || S <- ST]
        after
            pqc_cb_accounts:cleanup_accounts(API, ?ACCOUNT_NAMES),
            _ = delete_ip(API, IP),
            pqc_cb_api:cleanup(API)
        end,
    ?INFO("seq finished running: ~p", [API]),
    io:format("seq finished running: ~p~n", [API]).

-spec api_calls(pqc_kazoo_model:model()) -> api_calls().
api_calls(Model) ->
    AccountName = account_name(),

    [pqc_cb_accounts:command(Model, AccountName)
    ,{'call', ?MODULE, 'list_ips', [Model]}
    ,{'call', ?MODULE, 'assign_ips', [Model, AccountName, ips()]}
    ,{'call', ?MODULE, 'remove_ip', [Model, AccountName, ip()]}
    ,{'call', ?MODULE, 'fetch_ip', [Model, AccountName, ip()]}
    ,{'call', ?MODULE, 'assign_ip', [Model, AccountName, ip()]}
    ,{'call', ?MODULE, 'fetch_hosts', [Model]}
    ,{'call', ?MODULE, 'fetch_zones', [Model]}
    ,{'call', ?MODULE, 'fetch_assigned', [Model, AccountName]}
    ,{'call', ?MODULE, 'create_ip', [Model, ip()]}
    ,{'call', ?MODULE, 'delete_ip', [Model, ip()]}
    ].

account_name() ->
    oneof(?ACCOUNT_NAMES).

ip() ->
    oneof(?DEDICATED_IPS).

ips() ->
    [ip()].

-spec update_model(pqc_kazoo_model:model(), pqc_cb_api:response(), api_call()) ->
                          pqc_kazoo_model:model().
update_model(Model, _MResp, {'call', ?MODULE, 'list_ips', [_M]}) ->
    Model;
update_model(Model, _MResp, {'call', ?MODULE, 'assign_ips', [_M, AccountName, Dedicateds]}) ->
    lager:info("dedicated IPs: ~p", [Dedicateds]),
    pqc_util:transition_if(Model
                          ,[{fun pqc_kazoo_model:does_account_exist/2, [AccountName]}
                           ,{fun do_dedicated_ips_exist/2, [Dedicateds]}
                           ,{fun are_dedicated_ips_unassigned/2, [Dedicateds]}
                           ,{fun assign_dedicated_ips/3, [AccountName, Dedicateds]}
                           ]
                          );
update_model(Model, _MResp, {'call', ?MODULE, 'remove_ip', [_M, AccountName, ?DEDICATED(IP, _, _)]}) ->
    pqc_util:transition_if(Model
                          ,[{fun pqc_kazoo_model:does_account_exist/2, [AccountName]}
                           ,{fun pqc_kazoo_model:does_ip_exist/2, [IP]}
                           ,{fun pqc_kazoo_model:is_ip_assigned/3, [AccountName, IP]}
                           ,{fun pqc_kazoo_model:unassign_dedicated_ip/2, [IP]}
                           ]
                          );
update_model(Model, _MResp, {'call', ?MODULE, 'fetch_ip', [_M, _AccountName, _Dedicated]}) ->
    Model;
update_model(Model, _MResp, {'call', ?MODULE, 'assign_ip', [_M, AccountName, ?DEDICATED(IP, _, _)]}) ->
    pqc_util:transition_if(Model
                          ,[{fun pqc_kazoo_model:does_account_exist/2, [AccountName]}
                           ,{fun pqc_kazoo_model:does_ip_exist/2, [IP]}
                           ,{fun pqc_kazoo_model:is_ip_unassigned/2, [IP]}
                           ,{fun pqc_kazoo_model:assign_dedicated_ip/3, [AccountName, IP]}
                           ]
                          );
update_model(Model, _MResp, {'call', ?MODULE, 'fetch_hosts', [_M]}) ->
    Model;
update_model(Model, _MResp, {'call', ?MODULE, 'fetch_zones', [_M]}) ->
    Model;
update_model(Model, _MResp, {'call', ?MODULE, 'fetch_assigned', [_M, _AccountName]}) ->
    Model;
update_model(Model, _MResp, {'call', ?MODULE, 'create_ip', [_M, ?DEDICATED(IP, Host, Zone)]}) ->
    pqc_util:transition_if(Model
                          ,[{fun pqc_kazoo_model:is_ip_missing/2, [IP]}
                           ,{fun pqc_kazoo_model:add_dedicated_ip/4, [IP, Host, Zone]}
                           ]
                          );
update_model(Model, _MResp, {'call', ?MODULE, 'delete_ip', [_M, ?DEDICATED(IP, _Host, _Zone)]}) ->
    pqc_util:transition_if(Model
                          ,[{fun pqc_kazoo_model:does_ip_exist/2, [IP]}
                           ,{fun pqc_kazoo_model:remove_dedicated_ip/2, [IP]}
                           ]
                          ).

-spec check_response(pqc_kazoo_model:model(), any(), any()) -> boolean().
check_response(Model, {'call', _, 'create_account', _Args}=Call, APIResult) ->
    pqc_cb_accounts:check_response(Model, Call, APIResult);
check_response(Model, {'call', ?MODULE, 'list_ips', [_M]}, {'ok', []}) ->
    [] =:= pqc_kazoo_model:dedicated_ips(Model);
check_response(Model, {'call', ?MODULE, 'list_ips', [_M]}, {'ok', ListedIPs}) ->
    are_all_ips_listed(pqc_kazoo_model:dedicated_ips(Model), ListedIPs, 'false');
check_response(Model, {'call', ?MODULE, 'list_ips', [_M]}, {'error', 'not_found'}) ->
    [] =:= pqc_kazoo_model:dedicated_ips(Model);

check_response(Model, {'call', ?MODULE, 'assign_ips', [_M, AccountName, Dedicateds]}, {'ok', ListedIPs}) ->
    lager:info("checking listed IPs: ~p", [ListedIPs]),
    lists:all(fun({IP, IPInfo}) ->
                      not is_ip_listed(IP, IPInfo, ListedIPs)
              end
             ,pqc_kazoo_model:account_ips(Model, AccountName)
             )
        andalso all_requested_are_listed(Model, AccountName, Dedicateds, ListedIPs);
check_response(_Model, {'call', ?MODULE, 'assign_ips', [_M, _AccountName, _Dedicateds]}, {'error', 'not_found'}) -> 'true';
check_response(Model, {'call', ?MODULE, 'remove_ip', [_M, AccountName, ?DEDICATED(IP, Host, Zone)]}, {'ok', RemovedIP}) ->
    pqc_kazoo_model:is_ip_assigned(Model, AccountName, IP)
        andalso IP =:= kz_json:get_ne_binary_value(<<"ip">>, RemovedIP)
        andalso Host =:= kz_json:get_ne_binary_value(<<"host">>, RemovedIP)
        andalso Zone =:= kz_json:get_ne_binary_value(<<"zone">>, RemovedIP)
        andalso 'true' =:= kz_json:is_true([<<"_read_only">>, <<"deleted">>], RemovedIP);
check_response(Model, {'call', ?MODULE, 'remove_ip', [_M, AccountName, ?DEDICATED(IP, _Host, _Zone)]}, {'error', 'not_found'}) ->
    not pqc_kazoo_model:is_ip_assigned(Model, AccountName, IP);
check_response(Model, {'call', ?MODULE, 'fetch_ip', [_M, AccountName, ?DEDICATED(IP, _Host, _Zone)=Dedicated]}, {'ok', FetchedIP}) ->
    pqc_kazoo_model:is_ip_assigned(Model, AccountName, IP)
        andalso is_assigned(Model, AccountName, Dedicated, FetchedIP);
check_response(Model, {'call', ?MODULE, 'fetch_ip', [_M, AccountName, ?DEDICATED(IP, _Host, _Zone)]}, {'error', 'not_found'}) ->
    not pqc_kazoo_model:is_ip_assigned(Model, AccountName, IP);
check_response(Model, {'call', ?MODULE, 'assign_ip', [_M, AccountName, ?DEDICATED(_, _, _)=Dedicated]}, {'ok', AssignedIP}) ->
    lager:info("assigning ip ~p", [AssignedIP]),
    AccountIPs = pqc_kazoo_model:account_ips(Model, AccountName),
    lager:info("Account IPs: ~p", [AccountIPs]),
    lists:all(fun({IP, IPInfo}) ->
                      not is_ip_listed(IP, IPInfo, [AssignedIP])
              end
             ,AccountIPs
             )
        andalso all_requested_are_listed(Model, AccountName, [Dedicated], [AssignedIP]);
check_response(_Model, {'call', ?MODULE, 'assign_ip', [_M, _AccountName, _Dedicated]}, {'error', 'not_found'}) -> 'true';
check_response(Model, {'call', ?MODULE, 'fetch_zones', [_M]}, {'ok', Zones}) ->
    lists:usort(Zones) =:= lists:usort(pqc_kazoo_model:dedicated_zones(Model));
check_response(Model, {'call', ?MODULE, 'fetch_zones', [_M]}, {'error', 'not_found'}) ->
    [] =:= pqc_kazoo_model:dedicated_zones(Model);
check_response(Model, {'call', ?MODULE, 'fetch_hosts', [_M]}, {'ok', Hosts}) ->
    lists:usort(Hosts) =:= lists:usort(pqc_kazoo_model:dedicated_hosts(Model));
check_response(Model, {'call', ?MODULE, 'fetch_hosts', [_M]}, {'error', 'not_found'}) ->
    [] =:= pqc_kazoo_model:dedicated_hosts(Model);

check_response(_Model, {'call', ?MODULE, 'fetch_assigned', [_M, 'undefined']}, {'error', 'not_found'}) ->
    'true';
check_response(Model, {'call', ?MODULE, 'fetch_assigned', [_M, AccountName]}, {'ok', []}) ->
    [] =:= pqc_kazoo_model:account_ips(Model, AccountName);
check_response(Model, {'call', ?MODULE, 'fetch_assigned', [_M, AccountName]}, {'ok', ListedIPs}) ->
    lager:info("listing assigned IPs: ~p", [ListedIPs]),
    lists:all(fun({IP, IPInfo}) ->
                      is_ip_listed(IP, IPInfo, ListedIPs)
              end
             ,pqc_kazoo_model:account_ips(Model, AccountName)
             );
check_response(Model, {'call', ?MODULE, 'fetch_assigned', [_M, AccountName]}, {'error', 'not_found'}) ->
    [] =:= pqc_kazoo_model:account_ips(Model, AccountName);
check_response(Model, {'call', ?MODULE, 'create_ip', [_M, ?DEDICATED(IP, _, _)]}, {'ok', _CreatedIP}) ->
    'undefined' =:= pqc_kazoo_model:dedicated_ip(Model, IP);
check_response(Model, {'call', ?MODULE, 'create_ip', [_M, ?DEDICATED(IP, _, _)]}, {'error', 'conflict'}) ->
    'undefined' =/= pqc_kazoo_model:dedicated_ip(Model, IP);
check_response(Model, {'call', ?MODULE, 'delete_ip', [_M, ?DEDICATED(IP, _, _)]}, {'ok', _Deleted}) ->
    'undefined' =/= pqc_kazoo_model:dedicated_ip(Model, IP);
check_response(Model, {'call', ?MODULE, 'delete_ip', [_M, ?DEDICATED(IP, _, _)]}, {'error', 'not_found'}) ->
    'undefined' =:= pqc_kazoo_model:dedicated_ip(Model, IP).

%%% Helpers
-spec do_dedicated_ips_exist(pqc_kazoo_model:model(), [dedicated()]) ->
                                    boolean().
do_dedicated_ips_exist(Model, [_|_]=Dedicateds) ->
    lager:info("do IPs exist in model"),
    lists:all(fun(?DEDICATED(IP, _, _)) -> pqc_kazoo_model:does_ip_exist(Model, IP) end
             ,Dedicateds
             ).

-spec are_dedicated_ips_unassigned(pqc_kazoo_model:model(), [dedicated()]) ->
                                          boolean().
are_dedicated_ips_unassigned(Model, [_|_]=Dedicateds) ->
    lager:info("are IPs unassigned"),
    lists:all(fun(?DEDICATED(IP, _, _)) -> pqc_kazoo_model:is_ip_unassigned(Model, IP) end
             ,Dedicateds
             ).

-spec assign_dedicated_ips(pqc_kazoo_model:model(), pqc_cb_accounts:account_id(), [dedicated()]) ->
                                  pqc_kazoo_model:model().
assign_dedicated_ips(Model, AccountName, [_|_]=Dedicateds) ->
    lists:foldl(fun(?DEDICATED(IP, _, _), Mdl) ->
                        pqc_kazoo_model:assign_dedicated_ip(Mdl, AccountName, IP)
                end
               ,Model
               ,Dedicateds
               ).

-spec are_all_ips_listed([{kz_term:ne_binary(), pqc_kazoo_model:dedicated_ip()}], kz_json:objects(), boolean()) ->
                                boolean().
are_all_ips_listed([], [], _CheckHost) -> 'true';
are_all_ips_listed(_ModelIPs, [], _CheckHost) -> 'false';
are_all_ips_listed([], _ListedIPs, _CheckHost) -> 'false';
are_all_ips_listed([_|_]=ModelIPs, ListedIPs, CheckHost) ->
    lager:info("are all IPs listed"),
    lists:all(fun({IP, IPInfo}) ->
                      is_ip_listed(IP, IPInfo, ListedIPs, CheckHost)
              end
             ,ModelIPs
             ).

-spec is_ip_listed(kz_term:ne_binary(), pqc_kazoo_model:dedicated_ip(), kz_json:objects()) ->
                          boolean().
is_ip_listed(IP, IPInfo, ListedIPs) ->
    is_ip_listed(IP, IPInfo, ListedIPs, 'true').

is_ip_listed(IP, IPInfo, ListedIPs, CheckHost) ->
    Host = maps:get('host', IPInfo, 'undefined'),
    Zone = maps:get('zone', IPInfo, 'undefined'),

    lager:info("is ip ~s listed in ~p", [IP, ListedIPs]),
    lager:info("host: ~s", [Host]),
    lager:info("zone: ~s", [Zone]),

    lists:any(fun(ListedIP) ->
                      IP =:= kz_json:get_ne_binary_value(<<"ip">>, ListedIP)
                          andalso Zone =:= kz_json:get_ne_binary_value(<<"zone">>, ListedIP)
                          andalso (CheckHost =:= 'false'
                                   orelse Host =:= kz_json:get_ne_binary_value(<<"host">>, ListedIP)
                                  )
              end
             ,ListedIPs
             ).

-spec all_requested_are_listed(pqc_kazoo_model:model(), kz_term:ne_binary(), [dedicated()], kz_json:objects()) -> boolean().
all_requested_are_listed(Model, AccountName, Dedicateds, ListedIPs) ->
    lager:info("are all requested also listed"),
    lager:info("listed: ~p", [ListedIPs]),
    lager:info("ded: ~p", [Dedicateds]),

    case lists:foldl(fun(ListedIP, Ds) ->
                             IP = kz_json:get_ne_binary_value(<<"ip">>, ListedIP),

                             case lists:keytake(IP, #dedicated.ip, Dedicateds) of
                                 'false' -> Ds;
                                 {'value', D, Ds1} ->
                                     case is_assigned(Model, AccountName, D, ListedIP) of
                                         'true' -> Ds1;
                                         'false' -> Ds
                                     end
                             end
                     end
                    ,Dedicateds
                    ,ListedIPs
                    )
    of
        [] -> 'true';
        Ds ->
            lager:info("failed to find ~p", [Ds]),
            'false'
    end.

-spec is_assigned(pqc_kazoo_model:model(), kz_term:ne_binary(), dedicated(), kz_json:object()) -> boolean().
is_assigned(Model, AccountName, ?DEDICATED(DIP, DHost, DZone), ListedIP) ->
    IP = kz_json:get_ne_binary_value(<<"ip">>, ListedIP),
    Host = kz_json:get_ne_binary_value(<<"host">>, ListedIP),
    Zone = kz_json:get_ne_binary_value(<<"zone">>, ListedIP),
    AssignedTo = kz_json:get_ne_binary_value(<<"assigned_to">>, ListedIP),
    Status = kz_json:get_ne_binary_value(<<"status">>, ListedIP),

    AccountId = pqc_kazoo_model:account_id_by_name(Model, AccountName),
    lager:info("account ~s(~s): assigned: ~s", [AccountName, AccountId, AssignedTo]),

    AccountId =:= AssignedTo
        andalso <<"assigned">> =:= Status
        andalso IP =:= DIP
        andalso Host =:= DHost
        andalso Zone =:= DZone.
