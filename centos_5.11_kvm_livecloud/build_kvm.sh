#!/bin/bash

set -x

: ${BUILD_VERSION:="v$(date +'%Y%m%d%H%M%S')"}
: ${BUILD_NAME:="CentOS_5.11-x86_64"}
: ${VM_NAME:="centos_5.11"}

export BUILD_NAME
export VM_NAME
export BUILD_VERSION

PWD=`pwd`
FILENAME=${VM_NAME}
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