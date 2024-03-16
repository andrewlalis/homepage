#!/usr/bin/env dub
/+ dub.sdl:
    dependency "handy-httpd" version="~>8"
+/

/**
 * Run "./local-server.d" in your command-line to start up a server that simply
 * serves these files on http://localhost:8080. This can be helpful when you
 * need to simulate actual website behavior.
 */
module local_server;

import handy_httpd;
import handy_httpd.handlers.file_resolving_handler;

void main() {
    ServerConfig cfg;
    cfg.workerPoolSize = 5;
    new HttpServer(new FileResolvingHandler("./"), cfg).start();
}
