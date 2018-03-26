set -e

ROOT="$(pwd)"

if ! ([ -f curl-llist ] && [ -f curl-llist-parent ] && [ -f curl-multi-wait ] && [ -f curl-multi-wait-parent ])
then
	echo -e "\e[32mCloning cURL\e[0m"
	git clone git@github.com:curl/curl.git
	cd curl

	if ! [ -f curl-llist ]
	then
		echo -e "\e[32m\nChecking out llist changes\e[0m"
		git checkout cbae73e1dd95946597ea74ccb580c30f78e3fa73
		echo -e "\e[32m\nBuilding cURL with llist changes\e[0m"
		./buildconf && ./configure --disable-shared && make
		cp src/curl ../curl-llist
	fi

	if ! [ -f curl-llist-parent ]
	then
		echo -e "\e[32m\nChecking out llist changes parent\e[0m"
		git checkout HEAD^
		echo -e "\e[32m\nBuilding parent\e[0m"
		./buildconf && ./configure --disable-shared && make
		cp src/curl ../curl-llist-parent
	fi

	if ! [ -f curl-multi-wait ]
	then
		echo -e "\e[32m\n\nChecking out multi_wait changes\e[0m"
		git checkout 5f1163517e1597339d980b6504dbbece43c7027c
		echo -e "\e[32m\nBuilding multi-wait changes\e[0m"
		./buildconf && ./configure --disable-shared && make
		cp src/curl ../curl-multi-wait
	fi

	if ! [ -f curl-multi-wait-parent ]
	then
		echo -e "\e[32m\nChecking out multi-wait parent\e[0m"
		git checkout HEAD^
		echo -e "\e[32m\nBuilding multi-wait parent\e[0m"
		./buildconf && ./configure --disable-shared && make
		cp src/curl ../curl-multi-wait-parent
	fi

	cd ..
	rm -rf curl
fi
