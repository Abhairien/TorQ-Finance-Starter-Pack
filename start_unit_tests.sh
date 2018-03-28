. ./setenv.sh

export KDBTESTS=${TORQHOME}/tests
export KDBSTACKID="-stackid ${KDBBASEPORT}"

#Execute Unit tests
echo 'Executing Unit Tests...'
nohup q torq.q -procname unittests1 -proctype unittests -load tests/k4unit.q -test tests/ -debug
