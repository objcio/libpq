#ifndef __CPOSTGRESQL_SHIM_H__
#define __CPOSTGRESQL_SHIM_H__

#ifdef __APPLE__

#include "/opt/homebrew/opt/libpq/includA/libpq-fe.h"
#include "/opt/homebrew/opt/libpq/includA/postgres_ext.h"

#else

#include <libpq-fe.h>
#include <postgres_ext.h>

#endif

#endif
