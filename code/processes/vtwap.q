/-default parameters

// replay logfile
tab:flip`time`sym`price`size`stop`cond`ex!();
upd:{[t;x]
  if[`trade=t;
  .vtwap.upd[t;tab upsert@[flip;x;enlist x]];
  ];
 };

\d .vtwap

tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                                              // list of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;1b];                                                                      // replay the tickerplant log file
schema:@[value;`schema;0b];                                                                            // retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`trade`trade_iex];                                                                   /////// a list of tables to subscribe to, default (`) means all tables
subscribesyms:@[value;`subscribesyms;`];                                                               // a list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];                                                          // number of seconds between attempts to connect to the tp

// For TWAP - only store last trade in batch of same times?
// fix on monday
upd:{[t;x]
  syms:exec distinct sym from x;
  if[any `trade`trade_iex=/t;
    .twap.twap:@[value;`.twap.twap;syms!()];
    .vwap.vwap:@[value;`.vwap.vwap;syms!()];
    createtable[`.twap.twap;exec enlist last([]time;price)by sym from x]'[syms];
    createtable[`.vwap.vwap;exec([]time;price;size)by sym from x]'[syms];
   ];
 };

createtable:{[tab;x;y]@[tab;y;upsert;x y]};

subscribe:{[]
        if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];;
                .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];
                /-set the date that was returned by the subscription code i.e. the date for the tickerplant log file
                /-and a list of the tables that the process is now subscribing for
                subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];
                /-setting subtables and tplogdate globals
                @[`.vtwap;;:;]'[key subinfo;value subinfo]]}
notpconnected:{[]
    0 = count select from .sub.SUBSCRIPTIONS where proctype in .vtwap.tickerplanttypes, active}
\d .
.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.vtwap.tickerplanttypes

/-set the upd function in the top level namespace
tschema:flip `time`sym`price`size!()
.lg.o[`init;"searching for servers"];
.servers.startup[]; 
/-subscribe to the tickerplant
.vtwap.subscribe[];
/-check if the tickerplant has connected, block the process until a connection is established
while[.vtwap.notpconnected[];
        /-while no connected make the process sleep for X seconds and then run the subscribe function again
        .os.sleep[.vtwap.tpconnsleepintv];
        /-run the servers startup code again (to make connection to discovery)
        .servers.startup[];
        .vtwap.subscribe[]]

upd:.vtwap.upd;

getvwap:{[syms;st;et]
  :raze{[syms;st;et]
    :([]enlist sym:syms),'
    select vwap:size wavg price from .vwap.vwap[syms] 
      where time within(st;et);
  }[;st;et]'[syms];
 };

gettwap:{[syms;st;et]
  :raze{[syms;et;st]
    :([]enlist sym:syms),'
    select twap:(next[time]-time) wavg price from .twap.twap[syms]
      where time within(st;et);
   }[;st;et]'[syms];
 };

