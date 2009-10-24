# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Echo;

plan tests => 1 * blocks();

run_tests();

__DATA__

=== TEST 1: standalone directive
--- config
    location /echo {
        echo $echo_client_request_headers;
    }
--- request
    GET /echo
--- response_body eval
"GET /echo HTTP/1.1\r
Host: localhost:\$ServerPort\r
User-Agent: Test::Nginx::Echo\r

"



=== TEST 2: multiple instances
--- config
    location /echo {
        echo $echo_client_request_headers;
        echo $echo_client_request_headers;
    }
--- request
    GET /echo
--- response_body eval
"GET /echo HTTP/1.1\r
Host: localhost:\$ServerPort\r
User-Agent: Test::Nginx::Echo\r

GET /echo HTTP/1.1\r
Host: localhost:\$ServerPort\r
User-Agent: Test::Nginx::Echo\r

"



=== TEST 3: does not explicitly request_body
--- config
    location /echo {
        echo [$echo_request_body];
    }
--- request
POST /echo
body here
heh
--- response_body
[]



=== TEST 4: let proxy read request_body
--- config
    location /echo {
        echo_before_body [$echo_request_body];
        proxy_pass $scheme://127.0.0.1:$server_port/blah;
    }
    location /blah { echo_duplicate 0 ''; }
--- request
POST /echo
body here
heh
--- response_body
[body here
heh]



=== TEST 5: use echo_read_request_body to read it!
--- config
    location /echo {
        echo_read_request_body;
        echo [$echo_request_body];
    }
--- request
POST /echo
body here
heh
--- response_body
[body here
heh]



=== TEST 6: how about sleep after that?
--- config
    location /echo {
        echo_read_request_body;
        echo_sleep 0.002;
        echo [$echo_request_body];
    }
--- request
POST /echo
body here
heh
--- response_body
[body here
heh]



=== TEST 7: echo back the whole client request
--- config
  # echo back the client request
  location /echoback {
    echo $echo_client_request_headers;
    echo_read_request_body;
    echo $echo_request_body;
  }
--- request
POST /echoback
body here
haha
--- response_body eval
"POST /echoback HTTP/1.1\r
Host: localhost:\$ServerPort\r
User-Agent: Test::Nginx::Echo\r
Content-Length: 14\r

body here
haha
"



=== TEST 8: preread body should not be included
--- config
    location /preread {
        echo_subrequest_async POST /proxy -b 'hello world';
    }
    location /proxy {
        proxy_pass $scheme://127.0.0.1:$server_port/sub;
    }
    location /sub {
        echo_duplicate 1 $echo_client_request_headers;
    }
--- request
    GET /preread
--- response_body eval
"POST /sub HTTP/1.0\r
Host: 127.0.0.1:\$ServerPort\r
Connection: close\r
Content-Length: 11\r
"

