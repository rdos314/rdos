/*
 * Copyright 1995-2022 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the OpenSSL license (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

/* socket-related functions used by s_client and s_server */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <openssl/opensslconf.h>
#include "e_os.h" /* struct timeval for DTLS */
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

# include <openssl/e_os2.h>
# include <openssl/ossl_typ.h>
# include <openssl/bio.h>

/*
 * With IPv6, it looks like Digital has mixed up the proper order of
 * recursive header file inclusion, resulting in the compiler complaining
 * that u_int isn't defined, but only if _POSIX_C_SOURCE is defined, which is
 * needed to have fileno() declared correctly...  So let's define u_int
 */

#ifndef OPENSSL_NO_SOCK

# include "internal/sockets.h"

# include <openssl/bio.h>
# include <openssl/err.h>

extern BIO *bio_err;

#define openssl_fdset(a,b) FD_SET(a, b)


typedef int (*do_server_cb)(int s, int stype, int prot, unsigned char *context);

/* Keep track of our peer's address for the cookie callback */
BIO_ADDR *ourpeer = NULL;

/*
 * init_client - helper routine to set up socket communication
 * @sock: pointer to storage of resulting socket.
 * @host: the host name or path (for AF_UNIX) to connect to.
 * @port: the port to connect to (ignored for AF_UNIX).
 * @bindhost: source host or path (for AF_UNIX).
 * @bindport: source port (ignored for AF_UNIX).
 * @family: desired socket family, may be AF_INET, AF_INET6, AF_UNIX or
 *  AF_UNSPEC
 * @type: socket type, must be SOCK_STREAM or SOCK_DGRAM
 * @protocol: socket protocol, e.g. IPPROTO_TCP or IPPROTO_UDP (or 0 for any)
 *
 * This will create a socket and use it to connect to a host:port, or if
 * family == AF_UNIX, to the path found in host.
 *
 * If the host has more than one address, it will try them one by one until
 * a successful connection is established.  The resulting socket will be
 * found in *sock on success, it will be given INVALID_SOCKET otherwise.
 *
 * Returns 1 on success, 0 on failure.
 */
int init_client(int *sock, const char *host, const char *port,
                const char *bindhost, const char *bindport,
                int family, int type, int protocol)
{
    BIO_ADDRINFO *res = NULL;
    BIO_ADDRINFO *bindaddr = NULL;
    const BIO_ADDRINFO *ai = NULL;
    const BIO_ADDRINFO *bi = NULL;
    int found = 0;
    int ret;

    if (BIO_sock_init() != 1)
        return 0;

    ret = BIO_lookup_ex(host, port, BIO_LOOKUP_CLIENT, family, type, protocol,
                        &res);
    if (ret == 0) {
        ERR_print_errors(bio_err);
        return 0;
    }

    if (bindhost != NULL || bindport != NULL) {
        ret = BIO_lookup_ex(bindhost, bindport, BIO_LOOKUP_CLIENT,
                            family, type, protocol, &bindaddr);
        if (ret == 0) {
            ERR_print_errors (bio_err);
            goto out;
        }
    }

    ret = 0;
    for (ai = res; ai != NULL; ai = BIO_ADDRINFO_next(ai)) {
        /* Admittedly, these checks are quite paranoid, we should not get
         * anything in the BIO_ADDRINFO chain that we haven't
         * asked for. */
        OPENSSL_assert((family == AF_UNSPEC
                        || family == BIO_ADDRINFO_family(ai))
                       && (type == 0 || type == BIO_ADDRINFO_socktype(ai))
                       && (protocol == 0
                           || protocol == BIO_ADDRINFO_protocol(ai)));

        if (bindaddr != NULL) {
            for (bi = bindaddr; bi != NULL; bi = BIO_ADDRINFO_next(bi)) {
                if (BIO_ADDRINFO_family(bi) == BIO_ADDRINFO_family(ai))
                    break;
            }
            if (bi == NULL)
                continue;
            ++found;
        }

        *sock = BIO_socket(BIO_ADDRINFO_family(ai), BIO_ADDRINFO_socktype(ai),
                           BIO_ADDRINFO_protocol(ai), 0);
        if (*sock == INVALID_SOCKET) {
            /* Maybe the kernel doesn't support the socket family, even if
             * BIO_lookup() added it in the returned result...
             */
            continue;
        }

        if (bi != NULL) {
            if (!BIO_bind(*sock, BIO_ADDRINFO_address(bi),
                          BIO_SOCK_REUSEADDR)) {
                BIO_closesocket(*sock);
                *sock = INVALID_SOCKET;
                break;
            }
        }

        if (!BIO_connect(*sock, BIO_ADDRINFO_address(ai),
                         BIO_ADDRINFO_protocol(ai) == IPPROTO_TCP ? BIO_SOCK_NODELAY : 0)) {
            BIO_closesocket(*sock);
            *sock = INVALID_SOCKET;
            continue;
        }

        /* Success, don't try any more addresses */
        break;
    }

    if (*sock == INVALID_SOCKET) {
        if (bindaddr != NULL && !found) {
            BIO_printf(bio_err, "Can't bind %saddress for %s%s%s\n",
//                       BIO_ADDRINFO_family(res) == AF_INET6 ? "IPv6 " :
                       BIO_ADDRINFO_family(res) == AF_INET ? "IPv4 " :
//                       BIO_ADDRINFO_family(res) == AF_UNIX ? "unix " : "",
                       bindhost != NULL ? bindhost : "",
                       bindport != NULL ? ":" : "",
                       bindport != NULL ? bindport : "");
            ERR_clear_error();
            ret = 0;
        }
        ERR_print_errors(bio_err);
    } else {
        /* Remove any stale errors from previous connection attempts */
        ERR_clear_error();
        ret = 1;
    }
out:
    if (bindaddr != NULL) {
        BIO_ADDRINFO_free (bindaddr);
    }
    BIO_ADDRINFO_free(res);
    return ret;
}

#endif  /* OPENSSL_NO_SOCK */
