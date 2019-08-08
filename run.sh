#!/bin/bash

set -ex
export FILE_HOST="${FILE_HOST:-downloads.openwrt.org}"
TARGET="${TARGET:-x86-64}"
BRANCH="${BRANCH:-master}"

if [ "$BRANCH" == "master" ]; then
    export DOWNLOAD_PATH="snapshots/targets/$(echo $TARGET | tr '-' '/')"
else
    export DOWNLOAD_PATH="releases/$BRANCH/targets/$(echo $TARGET | tr '-' '/')"
fi

curl "https://$FILE_HOST/$DOWNLOAD_PATH/sha256sums" -fs -o sha256sums
curl "https://$FILE_HOST/$DOWNLOAD_PATH/sha256sums.asc" -fs -o sha256sums.asc || true
curl "https://$FILE_HOST/$DOWNLOAD_PATH/sha256sums.sig" -fs -o sha256sums.sig || true
if [ ! -f sha256sums.asc ] && [ ! -f sha256sums.sig ]; then
    echo "Missing sha256sums signature files"
    exit 1
fi
[ ! -f sha256sums.asc ] || gpg --with-fingerprint --verify sha256sums.asc sha256sums

if [ -f sha256sums.sig ]; then
	if hash signify-openbsd 2>/dev/null; then
		SIGNIFY_BIN=signify-openbsd # debian
	else
		SIGNIFY_BIN=signify # alpine
	fi
    VERIFIED=
    for KEY in ./usign/*; do
        echo "Trying $KEY..."
        if "$SIGNIFY_BIN" -V -q -p "$KEY" -x sha256sums.sig -m sha256sums; then
            echo "...verified"
            VERIFIED=1
            break
        fi
    done
    if [ -z "$VERIFIED" ]; then
        echo "Could not verify usign signature"
        exit 1
    fi
fi

# shrink checksum file to single desired file and verify downloaded archive
rsync -av "$FILE_HOST::downloads/$DOWNLOAD_PATH/$DOWNLOAD_FILE" . || exit 1
grep $DOWNLOAD_FILE sha256sums > sha256sums_min
sha256sum -c sha256sums_min
rm -f sha256sums{,_min,.sig,.asc}

BOOT_FILE="$(ls $DOWNLOAD_FILE)"
echo "yyy$BOOT_FILE"
gzip -d "$BOOT_FILE"
BOOT_FILE="$(basename $BOOT_FILE .gz)"
if [ ! -f "$BOOT_FILE" -a -s "$BOOT_FILE.gz" ]; then
    echo "xxx$BOOT_FILE"
fi

echo "$BOOT_FILE"
QEMU_HDA="$BOOT_FILE"


# main available options:
#   QEMU_CPU=n    (cores)
#   QEMU_RAM=nnn  (megabytes)
#   QEMU_HDA      (filename)
#   QEMU_HDA_SIZE (bytes, suffixes like "G" allowed)
#   QEMU_CDROM    (filename)
#   QEMU_BOOT     (-boot)
#   QEMU_PORTS="xxx[ xxx ...]" (space separated port numbers)
#   QEMU_NET_USER_EXTRA="net=192.168.76.0/24,dhcpstart=192.168.76.9" (extra raw args for "-net user,...")
#   QEMU_NO_SSH=1 (suppress automatic port 22 forwarding)
#   QEMU_NO_SERIAL=1 (suppress automatic "-serial stdio")

hostArch="$(uname -m)"
qemuArch="${QEMU_ARCH:-$hostArch}"
qemu="${QEMU_BIN:-qemu-system-$qemuArch}"
qemuArgs=()

qemuPorts=()
if [ -z "${QEMU_NO_SSH:-}" ]; then
	qemuPorts+=( 22 )
fi
qemuPorts+=( ${QEMU_PORTS:-} )

if [ -e /dev/kvm ]; then
	qemuArgs+=( -enable-kvm )
elif [ "$hostArch" = "$qemuArch" ]; then
	echo >&2
	echo >&2 'warning: /dev/kvm not found'
	echo >&2 '  PERFORMANCE WILL SUFFER'
	echo >&2 '  (hint: docker run --device /dev/kvm ...)'
	echo >&2
	sleep 3
fi

qemuScsiDevice='virtio-scsi-pci'
case "$qemuArch" in
    arm) qemuScsiDevice='virtio-scsi-device' ;;
esac
qemuArgs+=(
    -drive file="$QEMU_HDA",index=0,media=disk,discard=unmap,detect-zeroes=unmap,if=none,id=hda
    -device "$qemuScsiDevice"
    -device scsi-hd,drive=hda
)

qemuArgs+=( -smp "${QEMU_CPU:-1}" )
qemuArgs+=( -m "${QEMU_RAM:-512}" )

if [ -n "${QEMU_CDROM:-}" ]; then
	qemuArgs+=( -cdrom "$QEMU_CDROM" )
fi

if [ -n "${QEMU_BOOT:-}" ]; then
	qemuArgs+=( -boot "$QEMU_BOOT" )
fi

netArg='user'
netArg+=",hostname=$(hostname)"
if [ -n "${QEMU_NET_USER_EXTRA:-}" ]; then
	netArg+=",$QEMU_NET_USER_EXTRA"
fi
for port in "${qemuPorts[@]}"; do
	netArg+=",hostfwd=tcp::$port-:$port"
	netArg+=",hostfwd=udp::$port-:$port"
done

qemuNetDevice='virtio-net-pci'
case "$qemuArch" in
	arm) qemuNetDevice='virtio-net-device' ;;
esac

qemuArgs+=(
	-netdev "$netArg,id=net"
	-device "$qemuNetDevice,netdev=net"
	-vnc ':0'
)
if [ -z "${QEMU_NO_SERIAL:-}" ]; then
	qemuArgs+=(
		-serial stdio
	)
fi
qemuArgs+=( "$@" )

exec "$qemu" "${qemuArgs[@]}"
