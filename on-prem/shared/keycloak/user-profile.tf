# ── Realm user profile (B-M01) ──────────────────────────────────────────────────────────────────
#
# WHY THIS FILE EXISTS: Keycloak 26 enables the DECLARATIVE USER PROFILE, and with
# `unmanagedAttributePolicy` unset it SILENTLY DISCARDS any attribute that is not declared here.
#
# Measured against live dev on 2026-09-29:
#
#     PUT /admin/realms/fitmate-dev/users/{sub}  (full user representation, attributes merged)
#       → HTTP 204
#     GET the same user
#       → trainer_id ABSENT
#
# No error. No warning. A 204 that attests to "your request was well-formed" and NOT to
# "your data was stored". The back-fill tool only caught it because it reads the attribute back
# instead of trusting the status code.
#
# So `trainer_id` must be DECLARED to exist at all.
#
# ⚠️ THIS RESOURCE OWNS THE ENTIRE PROFILE. Keycloak has no "add one attribute" API — the PUT
# replaces the whole document. Declaring only `trainer_id` would DELETE username/email/firstName/
# lastName, which breaks registration, login and the account console at once. The four blocks
# below therefore reproduce the live built-ins EXACTLY as read back from
# `GET /admin/realms/fitmate-dev/users/profile`, validators included. Do not "tidy" them.
#
# Created only when a realm actually declares custom attributes, so realms that need none keep
# Keycloak's built-in profile untouched rather than gaining a terraform-managed copy of it.

resource "keycloak_realm_user_profile" "main" {
  count = length(var.realm.user_profile_attributes) > 0 ? 1 : 0

  realm_id = keycloak_realm.main.id

  # ── Keycloak built-ins, reproduced verbatim ────────────────────────────────────────────────
  attribute {
    name         = "username"
    display_name = "$${username}"

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    # 🔴 CONFIG IS MANDATORY, NOT OPTIONAL. Keycloak's `length` validator rejects the whole
    # PUT with error-validator-config-missing-value if min/max are absent — and it validates
    # the ENTIRE document, so one bare validator fails every attribute at once. The values
    # below are read back from the live realm, not chosen: username is min 3 / max 255, while
    # email/firstName/lastName carry max only (no min).
    validator {
      name = "length"
      config = {
        min = "3"
        max = "255"
      }
    }
    validator { name = "username-prohibited-characters" }
    validator { name = "up-username-not-idn-homograph" }
  }

  attribute {
    name               = "email"
    display_name       = "$${email}"
    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator { name = "email" }
    validator {
      name = "length"
      # max only — the live realm sets no minimum on email.
      config = {
        max = "255"
      }
    }
  }

  attribute {
    name               = "firstName"
    display_name       = "$${firstName}"
    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      # max only — matches the live realm.
      config = {
        max = "255"
      }
    }
    validator { name = "person-name-prohibited-characters" }
  }

  attribute {
    name               = "lastName"
    display_name       = "$${lastName}"
    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      # max only — matches the live realm.
      config = {
        max = "255"
      }
    }
    validator { name = "person-name-prohibited-characters" }
  }

  # ── Declared custom attributes ────────────────────────────────────────────────────────────
  dynamic "attribute" {
    for_each = { for a in var.realm.user_profile_attributes : a.name => a }

    content {
      name         = attribute.value.name
      display_name = attribute.value.display_name

      # 🔴 THE SECURITY-CRITICAL LINE IS `edit`.
      #
      # B-M01 exists because media-service trusted a caller-supplied trainer_id. Granting
      # "user" edit here would hand the user write access to the very value that replaces
      # that form field — relocating the forgery into Keycloak instead of removing it.
      #
      # Defaults are therefore admin-only for edit. `view` defaults to admin+user so a coach
      # can SEE their own id (harmless, and useful in the account console) without being able
      # to change it.
      permissions {
        view = attribute.value.view_roles
        edit = attribute.value.edit_roles
      }
    }
  }

  # group blocks are deliberately NOT managed: the live realm carries Keycloak's built-in
  # `user-metadata` group, and re-declaring it here adds drift for no benefit. Custom
  # attributes above are ungrouped, which renders them under the default section.
}
