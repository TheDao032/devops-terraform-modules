locals {
  # Resolved database name per service (defaults to the service key).
  svc_db = { for svc, cfg in var.services : svc => coalesce(cfg.database.name, svc) }

  # ── flatten services{} into the for_each-able maps the resources consume ──

  # db name -> database config object (databases.tf reads owner/template/encoding/... off this)
  databases = {
    for svc, cfg in var.services : local.svc_db[svc] => cfg.database
  }

  # all services' roles merged. Keys are the real (globally-unique) Postgres role names.
  roles = merge([for svc, cfg in var.services : cfg.roles]...)

  # (db, extension) -> {database, extension}
  db_extensions = merge([
    for svc, cfg in var.services : {
      for ext in cfg.database.extensions : "${local.svc_db[svc]}:${ext}" => { database = local.svc_db[svc], extension = ext }
    }
  ]...)

  # (db, schema) -> {database, schema, owner}. Owner = the service's db owner (its app role), so
  # migrations run by that role can create tables in the schema.
  db_schemas = merge([
    for svc, cfg in var.services : {
      for s in cfg.database.schemas : "${local.svc_db[svc]}:${s}" => { database = local.svc_db[svc], schema = s, owner = cfg.database.owner }
    }
  ]...)

  # (db, sql file) -> {database, path}. Seed SQL, run post-create over SSH.
  sql_units = merge([
    for svc, cfg in var.services : {
      for f in cfg.database.sql_files : "${local.svc_db[svc]}:${basename(f)}" => { database = local.svc_db[svc], path = f }
    }
  ]...)

  # grants -> stable keyed map. Each service's grants target THAT service's database (implicit).
  grants = {
    for g in flatten([
      for svc, cfg in var.services : [
        for i, gr in cfg.grants : merge(gr, { database = local.svc_db[svc], _svc = svc, _i = i })
      ]
    ]) : "${g._svc}:${g.role}:${g.schema}:${g.object_type}:${g._i}" => g
  }

  # immediate grants (existing objects) vs default privileges (future objects, e.g. migration-created)
  grants_now    = { for k, g in local.grants : k => g if !g.on_future }
  grants_future = { for k, g in local.grants : k => g if g.on_future }

  # ── pgbouncer: the SINGLE combined include file Terraform owns ──
  # Only services whose database opts in (database.pgbouncer.register). Ansible's base
  # pgbouncer.ini %include's this one file.
  pgbouncer_dbs = {
    for svc, cfg in var.services : local.svc_db[svc] => cfg.database
    if try(cfg.database.pgbouncer.register, true)
  }

  pgbouncer_ini = templatefile("${path.module}/templates/pgbouncer-databases.ini.tftpl", {
    databases   = local.pgbouncer_dbs
    coordinator = var.coordinator_container
    pg_port     = var.pg_port
  })

  # Common ssh(1) prefix for the imperative provisioners.
  ssh = "ssh -p ${var.ssh_port} ${var.ssh_opts} ${var.ssh_user}@${var.ssh_host}"
}
