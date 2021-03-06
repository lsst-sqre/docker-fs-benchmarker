#!/usr/bin/env bash

# BENCHMARK_DIR defaults to /project/bench.  It must exist and be writeable
#  by the current user before the harness is run.

# FIO_INPUT_DIR, if set, will be where the fio input files land, and will
#  not be cleaned up at exit.  If unset, a temporary directory will be created
#  and it will be cleaned up at program exit.

# DRY_RUN, if set, will prevent fio from actually being run.  In conjunction
#  with FIO_INPUT_DIR, this allows inspection of the fio jobs to be run
#  without committing to actually executing the jobs.

: "${BENCHMARK_DIR:=/project/bench}"
if [ -n "${FIO_INPUT_DIR}" ]; then
    fio_dir=${FIO_INPUT_DIR}
    mkdir -p ${fio_dir}
else 
    fio_dir=$(mktemp -d)
fi

function cleanup {
    # If we didn't manually set FIO_INPUT_DIR, then clean up our working dir.
    #  If we did, leave the files in it.
    if [ -z "${FIO_INPUT_DIR}" ]; then
	rm -rf ${fio_dir}
    fi
}
trap cleanup EXIT

function generate_fio {
    i=0
    for t in read write readwrite randread randwrite randrw; do
	for e in sync posixaio ; do
	    for s in 100M 1G ; do
		n="fio-${t}-${e}-${s}"
		istr=$(printf "%02d" ${i})
		fn="${fio_dir}/${istr}-${n}.fio"
		if [ -n "${fns}" ]; then
		    fns="${fns} ${fn}";
		else
		    fns=${fn}
		fi
		cat <<-EOF > ${fn}
[global]
name=${n}
filename=${n}
bs=256k
numjobs=1
time_based
runtime=300
iodepth=16

[file${i}]
size=${s}
ioengine=${e}
rw=${t}
EOF
		i=$((i+1))
	    done
	done
    done
}

generate_fio
if [ -z "${DRY_RUN}" ]; then
    cd ${BENCHMARK_DIR}
    for f in ${fns}; do
	echo "Running fio ${f}"
	fio ${f}
    done
fi
