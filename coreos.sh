#!/usr/bin/env bash

set -xe

function create_delivery
{
    mkdir delivery || rm -Rf delivery/*
}

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
    mkdir output || rm -Rf output/*
    SCRIPT_NAME=$1
    echo "Starting build..."
    SCRIPT_PATH="$(pwd)/${SCRIPT_NAME}"
    ISO_NAME=`echo ${SCRIPT_NAME} | sed "s/.ipxe//g"`.iso
    file ${SCRIPT_PATH}

    echo -n "------ $SCRIPT_NAME" >> output/metadata
    echo -n "date: " >> output/metadata
    date >> output/metadata

    make -C src -j bin/ipxe.iso EMBED=${SCRIPT_PATH}
    echo -n "file: " >> output/metadata
    file "src/bin/ipxe.iso" >> output/metadata
    echo -n "sha1sum: " >> output/metadata
    sha1sum  "src/bin/ipxe.iso" >> output/metadata
    mv "src/bin/ipxe.iso" output/${ISO_NAME}
}

function package
{
    SCRIPT_NAME=$1
    PACKAGE=`echo ${SCRIPT_NAME} | sed "s/.ipxe//g"`.tar.gz
    echo "Starting package..."
    cd output
    cat metadata
    tar -czvf ${PACKAGE} metadata *.iso
    file ${PACKAGE}
    mv ${PACKAGE} ../delivery/
    cd ..
}

function start_build
{
    SCRIPT_DIR="$(pwd)"
    for IPXE_FILE in `ls *.ipxe`
    do
        go_to_dirname
        builder ${IPXE_FILE}
        package ${IPXE_FILE}
    done
}

go_to_dirname
create_delivery
start_build
