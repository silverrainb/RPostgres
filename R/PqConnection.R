#' @include PqDriver.R
NULL

#' PqConnection and methods.
#'
#' @keywords internal
#' @export
setClass("PqConnection",
  contains = "DBIConnection",
  slots = list(ptr = "externalptr", bigint = "character")
)

# show()
#' @export
#' @rdname PqConnection-class
setMethod("show", "PqConnection", function(object) {
  info <- dbGetInfo(object)

  if (info$host == "") {
    host <- "socket"
  } else {
    host <- paste0(info$host, ":", info$port)
  }

  cat("<PqConnection> ", info$dbname, "@", host, "\n", sep = "")
})

# dbIsValid()
#' @export
#' @rdname PqConnection-class
setMethod("dbIsValid", "PqConnection", function(dbObj, ...) {
  connection_valid(dbObj@ptr)
})

# dbSendQuery()

# dbSendStatement()

# dbDataType()
#' @export
#' @rdname dbDataType
setMethod("dbDataType", "PqConnection", function(dbObj, obj, ...) {
  if (is.data.frame(obj)) return(vapply(obj, dbDataType, "", dbObj = dbObj))
  get_data_type(obj)
})

get_data_type <- function(obj) {
  if (is.factor(obj)) return("TEXT")
  if (inherits(obj, "POSIXt")) return("TIMESTAMPTZ")
  if (inherits(obj, "Date")) return("DATE")
  if (inherits(obj, "difftime")) return("TIME")
  switch(typeof(obj),
    integer = "INTEGER",
    double = "REAL",
    character = "TEXT",
    logical = "BOOLEAN",
    list = "BYTEA",
    stop("Unsupported type", call. = FALSE)
  )
}

# dbQuoteString()

# dbQuoteIdentifier()

# dbWriteTable()

# dbReadTable()

# dbListTables()

# dbExistsTable()

# dbListFields()

# dbRemoveTable()

# dbGetInfo()
#' @export
#' @rdname PqConnection-class
setMethod("dbGetInfo", "PqConnection", function(dbObj, ...) {
  connection_info(dbObj@ptr)
})

# dbBegin()

# dbCommit()

# dbRollback()

# other

#' Connect to a PostgreSQL database.
#'
#' Manually disconnecting a connection is not necessary with RPostgres, but
#' still recommended;
#' if you delete the object containing the connection, it will be automatically
#' disconnected during the next GC with a warning.
#'
#' @param drv `RPostgres::Postgres()`
#' @param dbname Database name. If `NULL`, defaults to the user name.
#'   Note that this argument can only contain the database name, it will not
#'   be parsed as a connection string (internally, `expand_dbname` is set to
#'   `false` in the call to
#'   [`PQconnectdbParams()`](https://www.postgresql.org/docs/9.6/static/libpq-connect.html)).
#' @param user,password User name and password. If `NULL`, will be
#'   retrieved from `PGUSER` and `PGPASSWORD` envvars, or from the
#'   appropriate line in `~/.pgpass`. See
#'   <http://www.postgresql.org/docs/9.6/static/libpq-pgpass.html> for
#'   more details.
#' @param host,port Host and port. If `NULL`, will be retrieved from
#'   `PGHOST` and `PGPORT` env vars.
#' @param service Name of service to connect as.  If `NULL`, will be
#'   ignored.  Otherwise, connection parameters will be loaded from the pg_service.conf
#'   file and used.  See <http://www.postgresql.org/docs/9.6/static/libpq-pgservice.html>
#'   for details on this file and syntax.
#' @param ... Other name-value pairs that describe additional connection
#'   options as described at
#'   <http://www.postgresql.org/docs/9.6/static/libpq-connect.html#LIBPQ-PARAMKEYWORDS>
#' @param bigint The R type that 64-bit integer types should be mapped to,
#'   default is [bit64::integer64], which allows the full range of 64 bit
#'   integers.
#' @param conn Connection to disconnect.
#' @export
#' @examples
#' if (postgresHasDefault()) {
#' library(DBI)
#' # Pass more arguments as necessary to dbConnect()
#' con <- dbConnect(RPostgres::Postgres())
#' dbDisconnect(con)
#' }
setMethod("dbConnect", "PqDriver",
  function(drv, dbname = NULL,
           host = NULL, port = NULL, password = NULL, user = NULL, service = NULL, ...,
           bigint = c("integer64", "integer", "numeric", "character")) {

    opts <- unlist(list(dbname = dbname, user = user, password = password,
      host = host, port = as.character(port), service = service, client_encoding = "utf8", ...))
    if (!is.character(opts)) {
      stop("All options should be strings", call. = FALSE)
    }
    bigint <- match.arg(bigint)

    if (length(opts) == 0) {
      ptr <- connection_create(character(), character())
    } else {
      ptr <- connection_create(names(opts), as.vector(opts))
    }

    con <- new("PqConnection", ptr = ptr, bigint = bigint)
    dbExecute(con, "SET TIMEZONE='UTC'")
    con
  })

# dbDisconnect() (after dbConnect() to maintain order in documentation)
#' @export
#' @rdname dbConnect-PqDriver-method
setMethod("dbDisconnect", "PqConnection", function(conn, ...) {
  connection_release(conn@ptr)
  invisible(TRUE)
})


#' Determine database type for R vector.
#'
#' @export
#' @param dbObj Postgres driver or connection.
#' @param obj Object to convert
#' @keywords internal
#' @rdname dbDataType
setMethod("dbDataType", "PqDriver", function(dbObj, obj, ...) {
  if (is.data.frame(obj)) return(vapply(obj, dbDataType, "", dbObj = dbObj))
  get_data_type(obj)
})
