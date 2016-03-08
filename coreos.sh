#!/usr/bin/env bash

set -xe
IPXE_SCRIPTS_DIR=ipxe_scripts
IPXE_BUILD_DIR=ipxe_build

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

function create_delivery
{
    mkdir delivery || rm -Rf delivery/*
}

function start_build
{
    SCRIPT_DIR="$(pwd)/${IPXE_SCRIPTS_DIR}"
    for IPXE_FILE in `ls ${SCRIPT_DIR}/*.ipxe`
    do
        go_to_dirname
        builder `basename ${IPXE_FILE}`
        package `basename ${IPXE_FILE}`
    done
}

function builder
{
    mkdir output || rm -Rf output/*
    SCRIPT_NAME=$1
    echo "Starting build..."
    SCRIPT_PATH="$(pwd)/${IPXE_SCRIPTS_DIR}/${SCRIPT_NAME}"
    ISO_NAME=`echo ${SCRIPT_NAME} | sed "s/.ipxe//g"`.iso
    file ${SCRIPT_PATH}

    echo -n "------ $SCRIPT_NAME" >> output/metadata
    echo -n "date: " >> output/metadata
    date >> output/metadata

    make -C ${IPXE_BUILD_DIR}/src -j bin/ipxe.iso EMBED=${SCRIPT_PATH}
    echo -n "file: " >> output/metadata
    file "${IPXE_BUILD_DIR}/src/bin/ipxe.iso" >> output/metadata
    echo -n "sha1sum: " >> output/metadata
    sha1sum  "${IPXE_BUILD_DIR}/src/bin/ipxe.iso" >> output/metadata
    mv "${IPXE_BUILD_DIR}/src/bin/ipxe.iso" output/${ISO_NAME}
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

go_to_dirname
create_delivery
start_build
