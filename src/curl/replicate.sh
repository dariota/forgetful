set -e

ROOT="$(pwd)"

if ! ([ -f curl-llist ] && [ -f curl-llist-parent ] && [ -f curl-multi-wait-1 ] && [ -f curl-multi-wait-11 ] && [ -f curl-multi-wait-parent-1 ] && [ -f curl-multi-wait-parent-11 ] )
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

	if ! ([ -f $ROOT/curl-multi-wait-1 ] || [ -f $ROOT/curl-multi-wait-11 ])
	then
		echo -e "\e[32m\n\nChecking out multi_wait changes\e[0m"
		git checkout 5f1163517e1597339d980b6504dbbece43c7027c
		echo -e "\e[32m\nBuilding multi-wait changes\e[0m"
		./buildconf && ./configure --disable-shared && make
		cd docs/examples/

		cp ../../../multi-single.c multi-single.c
		make multi-single
		cp multi-single ../../../curl-multi-wait-1

		sed -i "s/NUM_HANDLES 1/NUM_HANDLES 11/" multi-single.c
		make multi-single
		cp multi-single ../../../curl-multi-wait-11

		git checkout multi-single.c
		cd ../../
		echo ""
	fi

	if ! ([ -f $ROOT/curl-multi-wait-parent-1 ] || [ -f $ROOT/curl-multi-wait-parent-11 ])
	then
		echo -e "\e[32m\nChecking out multi-wait parent\e[0m"
		git checkout 5f1163517e1597339d980b6504dbbece43c7027c
		git checkout HEAD^
		echo -e "\e[32m\nBuilding multi-wait parent\e[0m"
		./buildconf && ./configure --disable-shared && make
		cd docs/examples/

		cp ../../../multi-single.c multi-single.c
		make multi-single
		cp multi-single ../../../curl-multi-wait-parent-1

		sed -i "s/NUM_HANDLES 1/NUM_HANDLES 11/" multi-single.c
		make multi-single
		cp multi-single ../../../curl-multi-wait-parent-11

		git checkout multi-single.c
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
truncate -s 1G 1G
python -m http.server > /dev/null 2> /dev/null &
SERVER_PID=$!
sleep 1
cd ..

mkdir -p timings
for j in {1..10}
do
	echo -e "\e[32mTesting llist, iteration $j\e[0m"
	for i in curl-llist*
	do
		(time ./$i -Ss http://localhost:8000/25G -o /dev/null) 2>> timings/$i
	done
done

kill $SERVER_PID 2> /dev/null

PIDS=()
cd testserver
for i in {0..10}
do
	let port=8000+$i
	python -m http.server $port > /dev/null 2> /dev/null &
	PIDS[$i]=$!
done
cd ..

sleep 2

for j in {0..10}
do
	echo -e "\e[32mTesting multi-wait, iteration $j\e[0m"
	for i in curl-multi-*
	do
		(time ./$i > /dev/null) 2>> timings/$i
	done
done

for i in {0..10}
do
	kill ${PIDS[$i]} 2> /dev/null
done
