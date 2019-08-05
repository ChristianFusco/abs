#!/bin/bash
# Maintainer: Gordian Edenhofer <gordian.edenhofer@gmail.com>
# Contributer: Philip Abernethy <chais.z3r0@gmail.com>
# Contributer: sowieso <sowieso@dukun.de>

pkgname=minecraft-server
pkgver=1.14.4
_nonce=3dc3d84a581f14691199cf6831b71ed1296a9fdf
# See https://launchermeta.mojang.com/mc/game/version_manifest.json for a list of all releases
_game="minecraft"
_server_root="/srv/minecraft"
_user="${_game}"

package() {
	wget https://launcher.mojang.com/v1/objects/${_nonce}/server.jar
	mv server.jar ${_game}_server.jar


	install -Dm644 ${_game}d.conf              "${pkgdir}/etc/conf.d/${_game}"
	install -Dm755 ${_game}d.sh                "${pkgdir}/usr/bin/${_game}d"
	install -Dm644 ${_game}d.service           "${pkgdir}/usr/lib/systemd/system/${_game}d.service"
	install -Dm644 ${_game}d-backup.service    "${pkgdir}/usr/lib/systemd/system/${_game}d-backup.service"
	install -Dm644 ${_game}d-backup.timer      "${pkgdir}/usr/lib/systemd/system/${_game}d-backup.timer"
	install -Dm644 ${_game}_server.jar "${pkgdir}${_server_root}/${_game}_server.jar"
	# I don't understand why this is here.
	# I'll leave it around just in case...
	# ln -s "${_game}_server.jar" "${pkgdir}${_server_root}/${_game}_server.jar"

	# Link the log files
	mkdir -p "${pkgdir}/var/log/"
	install -dm2755 "${pkgdir}/${_server_root}/logs"
	ln -s "${_server_root}/logs" "${pkgdir}/var/log/${_game}"

	# Give the group write permissions and set user or group ID on execution
	chmod g+ws "${pkgdir}${_server_root}"
}

post_install() {
        getent group "${_user}" &>/dev/null
        if [ $? -ne 0 ]; then
                echo "Adding ${_user} system group..."
                groupadd -r ${_user} 1>/dev/null
        fi

        getent passwd "${_user}" &>/dev/null
        if [ $? -ne 0 ]; then
                echo "Adding ${_user} system user..."
                useradd -r -g ${_user} -d "${_server_root}" ${_user} 1>/dev/null
        fi

        chown -R ${_user}:${_user} "${_server_root}"

        echo "The world data is stored under ${_server_root} and the server runs as ${_user} user to increase security."
        echo "Use the ${_game} script under /usr/bin/${_game}d to start, stop or backup the server."
        echo "Adjust the configuration file under /etc/conf.d/${_game} to your liking."
        echo "For the server to start you have to accept the EULA in ${_server_root}/eula.txt !"
        echo "The EULA file is generated after the first server start."
}

yum install -y nmap-ncat

package
post_install
