#!/usr/bin/env bash

set -xe

ISO=ipxe.iso
ISE_RULE=bin/${ISO}
ISO_BIN=src/${ISO_RULE}

SCRIPT_NAME=coreos.ipxe

PACKAGE=coreos_ipxe.tar.gz

function go_to_dirname
{
    echo "Go to working directory..."
    cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    if [ $? -ne 0 ]
    then
        echo "go_to_dirname failed";
        exit 1
    fi
    echo "-> Current directory is" $(pwd)
}

function builder
{
    echo "Starting build..."
    SCRIPT_PATH="$(pwd)/${SCRIPT_NAME}"
    file ${SCRIPT_PATH}

    echo -n "date: " >> output/metadata
    date >> output/metadata

    for RULE in ${ISO_RULE}
    do
        make -C src -j ${RULE} EMBED=${SCRIPT_PATH}
        echo -n "file: " >> output/metadata
        file "src/${RULE}" >> output/metadata
        echo -n "sha1sum: " >> output/metadata
        sha1sum  "ipxe/src/${RULE}" >> output/metadata
        mv "src/${RULE}" output/
    done
}

function package
{
    echo "Starting package..."
    mkdir delivery || rm -Rf delivery/*
    cd output
    cat metadata
    tar -czvf ${PACKAGE} *
    file ${PACKAGE}
    mv ${PACKAGE} ../delivery/
}

go_to_dirname
builder
package