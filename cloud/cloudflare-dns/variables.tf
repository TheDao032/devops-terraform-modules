variable "zone_id" {
  description = "Cloudflare zone id the records belong to."
  type        = string
}

variable "records" {
  description = <<-EOT
    Ordinary DNS records for this zone.

    Deliberately NOT a general-purpose passthrough: `proxied` defaults to FALSE and every
    caller must opt in. Cloudflare's orange-cloud proxy rewrites answers, which is correct
    for web hostnames and WRONG for every record here — a proxied DKIM CNAME still resolves,
    mail still sends, authentication silently fails, and the only symptom is landing in spam.
    A default of false makes the dangerous case the one you have to ask for.
  EOT
  type = list(object({
    name     = string # "@" for apex, or a subdomain label
    type     = string # TXT | CNAME | MX | A ...
    content  = string
    ttl      = optional(number, 1) # 1 = automatic
    proxied  = optional(bool, false)
    comment  = optional(string)
    priority = optional(number) # MX only
  }))

  validation {
    condition     = alltrue([for r in var.records : contains(["TXT", "CNAME", "A", "AAAA", "MX", "SRV", "CAA"], r.type)])
    error_message = "records[].type must be one of: TXT, CNAME, A, AAAA, MX, SRV, CAA."
  }

  # Proxying anything that is not a web hostname breaks it in a way that still looks healthy.
  validation {
    condition     = alltrue([for r in var.records : !coalesce(r.proxied, false) || contains(["A", "AAAA", "CNAME"], r.type)])
    error_message = "records[].proxied may only be true for A, AAAA or CNAME records."
  }

  # Two records of the same name+type collide in the for_each key and one would vanish
  # silently. Catch it at plan time rather than losing a record.
  validation {
    condition     = length(var.records) == length(distinct([for r in var.records : "${r.name}|${r.type}|${substr(r.content, 0, 40)}"]))
    error_message = "records[] contains duplicate name+type+content entries."
  }
}
