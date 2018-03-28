#!/bin/bash

export STACKID=7654

sh start_torq_demo.sh
sleep 10
q tests/run.q -stackid ${STACKID}
sh stop_torq_demo.sh
