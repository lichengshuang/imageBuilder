#!/bin/bash

set -x

: ${BUILD_VERSION:="v$(date +'%Y%m%d%H%M%S')"}
: ${BUILD_NAME:="Debian-7.8.0-x86_64"}
: ${VM_NAME:="debian7.8"}

export BUILD_NAME
export VM_NAME
export BUILD_VERSION

PWD=`pwd`
FILENAME=${VM_NAME}.qcow2
PACKER=/opt/packer-builder-cloud/bin/packer

if [ -e "${PWD}/disk" ];
then
    rm -rf ${PWD}/disk
fi

if [ ! -e "${PWD}/final_images" ];
then
    mkdir -pv ${PWD}/final_images
fi

$PACKER build template_kvm.json

cd disk
qemu-img convert -c -O qcow2 $FILENAME ${BUILD_NAME}-${BUILD_VERSION}.qcow2
cd -

mv ${PWD}/disk/${BUILD_NAME}-${BUILD_VERSION}.qcow2 ${PWD}/final_images
rm -rf ${PWD}/disk
echo "==> Generate files:"
find ${PWD}/final_images -type f -printf "==> %f\n"

echo "Done"