set -e

ROOT="$(pwd)"

if ! ([ -f curl-llist ] && [ -f curl-llist-parent ] && [ -f curl-multi-wait ] && [ -f curl-multi-wait-parent ])
then
	if ! [ -d $ROOT/curl ]
	then
		echo -e "\e[32mCloning cURL\e[0m"
		git clone git@github.com:curl/curl.git
		echo ""
	fi

	cd curl

	if ! [ -f $ROOT/curl-llist ]
	then
		echo -e "\e[32m\nChecking out llist changes\e[0m"
		git checkout cbae73e1dd95946597ea74ccb580c30f78e3fa73
		echo -e "\e[32m\nBuilding cURL with llist changes\e[0m"
		./buildconf && ./configure --disable-shared && make
		cp src/curl ../curl-llist
		echo ""
	fi

	if ! [ -f $ROOT/curl-llist-parent ]
	then
		echo -e "\e[32m\nChecking out llist changes parent\e[0m"
		git checkout cbae73e1dd95946597ea74ccb580c30f78e3fa73
		git checkout HEAD^
		echo -e "\e[32m\nBuilding parent\e[0m"
		./buildconf && ./configure --disable-shared && make
		cp src/curl ../curl-llist-parent
		echo ""
	fi

	if ! [ -f $ROOT/curl-multi-wait ]
	then
		echo -e "\e[32m\n\nChecking out multi_wait changes\e[0m"
		git checkout 5f1163517e1597339d980b6504dbbece43c7027c
		echo -e "\e[32m\nBuilding multi-wait changes\e[0m"
		./buildconf && ./configure --disable-shared && make
		cd docs/examples/
		sed -i 's!www.example.com/!localhost:8000/01G!' multi-single.c
		make multi-single
		git checkout multi-single.c
		cp multi-single ../../../curl-multi-wait
		cd ../../
		echo ""
	fi

	if ! [ -f $ROOT/curl-multi-wait-parent ]
	then
		echo -e "\e[32m\nChecking out multi-wait parent\e[0m"
		git checkout 5f1163517e1597339d980b6504dbbece43c7027c
		git checkout HEAD^
		echo -e "\e[32m\nBuilding multi-wait parent\e[0m"
		./buildconf && ./configure --disable-shared && make
		cd docs/examples/
		sed -i 's!www.example.com/!localhost:8000/01G!' multi-single.c
		make multi-single
		git checkout multi-single.c
		cp multi-single ../../../curl-multi-wait-parent
		cd ../../
		echo ""
	fi

	cd ..
	rm -rf curl
fi

set +e
echo -e "\e[32mSetting up test server\n\e[0m"
mkdir -p testserver
cd testserver
truncate -s 25G 25G
python -m http.server > /dev/null 2> /dev/null &
SERVER_PID=$!
sleep 1
cd ..

mkdir -p timings
for j in {1..10}
do
	echo -e "\e[32mTesting, iteration $j\e[0m"
	for i in curl-*
	do
		(time ./$i -Ss http://localhost:8000/25G -o /dev/null) 2>> timings/$i
	done
done

kill $SERVER_PID
