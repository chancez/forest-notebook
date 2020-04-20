#!/bin/bash

echo -e "========================================="
echo -e "=   WELCOME TO THE RIGETTI FOREST SDK   ="
echo -e "========================================="
echo -e "Copyright (c) 2016-2019 Rigetti Computing\n"

quilc $QUILC_ARGS --quiet -R &> quilc.log &
qvm $QVM_ARGS --quiet -S &> qvm.log &

exec "$@"
